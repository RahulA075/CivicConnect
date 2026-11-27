import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.*;
import java.util.concurrent.atomic.*;

/**
 * TCP intercept proxy on port 2376.
 * Captures exact bytes sent by any HTTP client to localhost:2376,
 * forwards them to localhost:2375, and prints both directions.
 *
 * Usage:
 *   Step 1 — start this proxy: java WireDiag proxy
 *   Step 2 — in another shell, point httpclient5 / curl at port 2376
 *   OR: run embedded tests below with: java WireDiag test
 */
public class WireDiag {

    static final int  PROXY_PORT  = 2376;
    static final String DOCKER_HOST = "localhost";
    static final int  DOCKER_PORT  = 2375;

    // Captured request bytes from the most recent connection
    static final AtomicReference<byte[]> lastRequest  = new AtomicReference<>();
    static final AtomicReference<byte[]> lastResponse = new AtomicReference<>();
    static final CountDownLatch          captured     = new CountDownLatch(1);

    public static void main(String[] args) throws Exception {
        String mode = args.length > 0 ? args[0] : "test";

        if ("proxy".equals(mode)) {
            startProxy();
            System.out.println("Proxy listening on port " + PROXY_PORT +
                    " → forwarding to " + DOCKER_HOST + ":" + DOCKER_PORT);
            System.out.println("Point your client at http://localhost:" + PROXY_PORT + "/info");
            Thread.currentThread().join(); // block forever
        } else {
            runTests();
        }
    }

    // ── Start proxy in background thread, run tests, compare ────────────────
    static void runTests() throws Exception {
        // Start the intercept proxy
        ServerSocket proxy = new ServerSocket(PROXY_PORT);
        System.out.println("Intercept proxy started on port " + PROXY_PORT);

        Thread proxyThread = new Thread(() -> {
            try {
                Socket client = proxy.accept(); // accept ONE connection
                handleProxyConnection(client);
                proxy.close();
            } catch (Exception e) {
                if (!e.getMessage().contains("closed")) e.printStackTrace();
            }
        });
        proxyThread.setDaemon(true);
        proxyThread.start();

        // ── TEST A: Raw JDK Socket (known-good) ─────────────────────────────
        System.out.println("\n========================================");
        System.out.println("TEST A: JDK Raw Socket → direct to :2375");
        System.out.println("========================================");
        byte[] rawReqBytes = runRawSocketRequest(DOCKER_HOST, DOCKER_PORT, "/info");
        System.out.println("\nExact bytes sent (as string):");
        System.out.println("---");
        System.out.println(new String(rawReqBytes, StandardCharsets.UTF_8));
        System.out.println("---");

        // ── TEST B: httpclient5 via proxy ────────────────────────────────────
        System.out.println("\n========================================");
        System.out.println("TEST B: Apache HttpClient5 → via proxy :2376 → :2375");
        System.out.println("========================================");
        runHttpClient5Request("http://localhost:" + PROXY_PORT + "/info");

        // Wait for proxy to capture the request (max 10s)
        if (!captured.await(10, TimeUnit.SECONDS)) {
            System.out.println("TIMEOUT: proxy did not capture a request within 10s");
            return;
        }

        byte[] hc5Request  = lastRequest.get();
        byte[] hc5Response = lastResponse.get();

        System.out.println("\nExact bytes sent by HttpClient5 (as string):");
        System.out.println("---");
        System.out.println(hc5Request == null ? "(null)" : new String(hc5Request, StandardCharsets.UTF_8));
        System.out.println("---");

        System.out.println("\nResponse received by HttpClient5 (status line + headers):");
        if (hc5Response != null) {
            String resp = new String(hc5Response, StandardCharsets.UTF_8);
            int bodyStart = resp.indexOf("\r\n\r\n");
            System.out.println(bodyStart >= 0 ? resp.substring(0, bodyStart) : resp.substring(0, Math.min(500, resp.length())));
        }

        // ── DIFF ─────────────────────────────────────────────────────────────
        System.out.println("\n========================================");
        System.out.println("HEADER DIFF");
        System.out.println("========================================");
        if (hc5Request != null) {
            diffHeaders(new String(rawReqBytes, StandardCharsets.UTF_8),
                        new String(hc5Request, StandardCharsets.UTF_8));
        }
    }

    // ── Raw Socket request — returns the exact bytes we sent ─────────────────
    static byte[] runRawSocketRequest(String host, int port, String path) throws Exception {
        String req =
                "GET " + path + " HTTP/1.1\r\n" +
                "Host: " + host + ":" + port + "\r\n" +
                "Accept: application/json\r\n" +
                "Connection: close\r\n" +
                "\r\n";
        byte[] reqBytes = req.getBytes(StandardCharsets.UTF_8);

        Socket s = new Socket();
        s.connect(new InetSocketAddress(host, port), 5000);
        s.setSoTimeout(5000);
        s.getOutputStream().write(reqBytes);
        s.getOutputStream().flush();

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        byte[] buf = new byte[4096];
        int n;
        try {
            while ((n = s.getInputStream().read(buf)) != -1) baos.write(buf, 0, n);
        } catch (SocketTimeoutException ignored) {}
        s.close();

        String response = baos.toString("UTF-8");
        String statusLine = response.split("\r\n")[0];
        System.out.println("Response status: " + statusLine);
        printKeyFields("JDK-RawSocket", response);

        return reqBytes;
    }

    // ── HttpClient5 request — uses reflection to load shaded classes ─────────
    static void runHttpClient5Request(String url) {
        // We load the shaded httpclient5 from the docker-java-transport-zerodep jar
        // which is on the classpath when run via: java -cp <zerodep-jar> WireDiag
        try {
            // Try the shaded path first (docker-java zerodep)
            Class<?> hcBuilderClass = null;
            String[] candidatePaths = {
                "com.github.dockerjava.zerodep.shaded.org.apache.hc.client5.http.impl.classic.HttpClients",
                "org.apache.hc.client5.http.impl.classic.HttpClients"
            };
            for (String cp : candidatePaths) {
                try { hcBuilderClass = Class.forName(cp); break; }
                catch (ClassNotFoundException ignored) {}
            }

            if (hcBuilderClass == null) {
                System.out.println("HttpClient5 not found on classpath — skipping HC5 test");
                System.out.println("Run with: java -cp WireDiag.jar:<docker-java-transport-zerodep.jar> WireDiag");
                captured.countDown();
                return;
            }

            // HttpClients.createDefault()
            Object httpClient = hcBuilderClass.getMethod("createDefault").invoke(null);

            // Build GET request
            Class<?> httpGetClass = null;
            String[] getClasses = {
                "com.github.dockerjava.zerodep.shaded.org.apache.hc.client5.http.classic.methods.HttpGet",
                "org.apache.hc.client5.http.classic.methods.HttpGet"
            };
            for (String cp : getClasses) {
                try { httpGetClass = Class.forName(cp); break; }
                catch (ClassNotFoundException ignored) {}
            }

            if (httpGetClass == null) {
                System.out.println("HttpGet class not found");
                captured.countDown();
                return;
            }

            Object httpGet = httpGetClass.getConstructor(String.class).newInstance(url);

            // execute(httpGet)
            // CloseableHttpResponse response = httpClient.execute(httpGet)
            Object response = httpClient.getClass()
                    .getMethod("execute", httpGetClass.getInterfaces()[0].getDeclaringClass() == null
                        ? httpGetClass : httpGetClass.getSuperclass())
                    .invoke(httpClient, httpGet);

            // Get status code
            int code = (int) response.getClass().getMethod("getCode").invoke(response);
            System.out.println("HttpClient5 response status: " + code);

            // close
            try { response.getClass().getMethod("close").invoke(response); } catch (Exception ignored) {}
            try { httpClient.getClass().getMethod("close").invoke(httpClient); } catch (Exception ignored) {}

        } catch (Exception e) {
            System.out.println("HttpClient5 reflection error: " + e.getMessage());
            e.printStackTrace();
            captured.countDown();
        }
    }

    // ── TCP intercept proxy ───────────────────────────────────────────────────
    static void handleProxyConnection(Socket clientSocket) {
        try {
            clientSocket.setSoTimeout(8000);

            // Read request from client (httpclient5)
            InputStream  cin  = clientSocket.getInputStream();
            OutputStream cout = clientSocket.getOutputStream();

            ByteArrayOutputStream reqBuf = new ByteArrayOutputStream();
            byte[] buf = new byte[8192];

            // Read until we have a complete HTTP request header (\r\n\r\n)
            int totalRead = 0;
            boolean headerDone = false;
            while (!headerDone) {
                int n = cin.read(buf, 0, 1); // read 1 byte at a time for header
                if (n <= 0) break;
                reqBuf.write(buf, 0, n);
                totalRead++;
                byte[] so_far = reqBuf.toByteArray();
                if (so_far.length >= 4) {
                    // Check for \r\n\r\n
                    int end = so_far.length - 1;
                    if (so_far[end] == '\n' && so_far[end-1] == '\r' &&
                        so_far[end-2] == '\n' && so_far[end-3] == '\r') {
                        headerDone = true;
                    }
                }
                if (totalRead > 16384) break; // safety
            }

            byte[] requestBytes = reqBuf.toByteArray();
            lastRequest.set(requestBytes);

            System.out.println("[PROXY] Captured request from HttpClient5 (" + requestBytes.length + " bytes)");

            // Forward to real Docker daemon
            Socket dockerSocket = new Socket();
            dockerSocket.connect(new InetSocketAddress(DOCKER_HOST, DOCKER_PORT), 5000);
            dockerSocket.setSoTimeout(8000);

            OutputStream dout = dockerSocket.getOutputStream();
            InputStream  din  = dockerSocket.getInputStream();

            dout.write(requestBytes);
            dout.flush();

            // Read response from Docker
            ByteArrayOutputStream respBuf = new ByteArrayOutputStream();
            byte[] rbuf = new byte[4096];
            int n;
            try {
                while ((n = din.read(rbuf)) != -1) respBuf.write(rbuf, 0, n);
            } catch (SocketTimeoutException ignored) {}
            dockerSocket.close();

            byte[] responseBytes = respBuf.toByteArray();
            lastResponse.set(responseBytes);

            // Forward response back to httpclient5
            cout.write(responseBytes);
            cout.flush();
            clientSocket.close();

            System.out.println("[PROXY] Forwarded response (" + responseBytes.length + " bytes) back to client");
            captured.countDown();

        } catch (Exception e) {
            System.out.println("[PROXY] Error: " + e.getMessage());
            captured.countDown();
        }
    }

    // ── Start standalone proxy (foreground) ──────────────────────────────────
    static void startProxy() throws Exception {
        ServerSocket ss = new ServerSocket(PROXY_PORT);
        while (true) {
            Socket client = ss.accept();
            new Thread(() -> handleProxyConnection(client)).start();
        }
    }

    // ── Header diff ───────────────────────────────────────────────────────────
    static void diffHeaders(String rawSocket, String hc5) {
        String[] rawLines = rawSocket.split("\r\n");
        String[] hc5Lines = hc5.split("\r\n");

        System.out.println("JDK Raw Socket headers:");
        for (String l : rawLines) {
            if (l.isEmpty()) break;
            System.out.println("  [A] " + l);
        }
        System.out.println("\nApache HttpClient5 headers:");
        for (String l : hc5Lines) {
            if (l.isEmpty()) break;
            System.out.println("  [B] " + l);
        }

        System.out.println("\nIn [B] but not in [A] (HttpClient5 extra headers):");
        for (String bl : hc5Lines) {
            if (bl.isEmpty()) break;
            boolean found = false;
            for (String al : rawLines) { if (al.equalsIgnoreCase(bl)) { found = true; break; } }
            if (!found) System.out.println("  EXTRA: " + bl);
        }

        System.out.println("\nIn [A] but not in [B] (JDK missing from HttpClient5):");
        for (String al : rawLines) {
            if (al.isEmpty()) break;
            boolean found = false;
            for (String bl : hc5Lines) { if (al.equalsIgnoreCase(bl)) { found = true; break; } }
            if (!found) System.out.println("  MISSING: " + al);
        }
    }

    static void printKeyFields(String label, String response) {
        int bodyStart = response.indexOf("\r\n\r\n");
        String body = bodyStart >= 0 ? response.substring(bodyStart + 4) : response;
        // chunked: skip chunk size line if present
        if (body.matches("(?s)^[0-9a-fA-F]+\r\n.*")) {
            body = body.substring(body.indexOf("\r\n") + 2);
        }
        System.out.println("[" + label + "] ServerVersion=" + extract(body, "ServerVersion") +
                "  Driver=" + extract(body, "Driver") +
                "  NCPU=" + extract(body, "NCPU"));
    }

    static String extract(String json, String key) {
        int i = json.indexOf("\"" + key + "\":");
        if (i < 0) return "?";
        int s = i + key.length() + 3;
        while (s < json.length() && json.charAt(s) == ' ') s++;
        if (s >= json.length()) return "?";
        char f = json.charAt(s);
        if (f == '"') { int e = json.indexOf('"', s+1); return e>=0 ? json.substring(s+1,e) : "?"; }
        int e = s; while (e < json.length() && ",}".indexOf(json.charAt(e)) < 0) e++;
        return json.substring(s, e).trim();
    }
}
