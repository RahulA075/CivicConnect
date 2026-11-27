import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;

/**
 * Single-connection TCP capture proxy.
 * Listens on :2376, captures ONE request, prints it, forwards to :2375, prints response headers.
 */
public class CaptureProxy {
    public static void main(String[] args) throws Exception {
        int listenPort = 2376;
        String targetHost = "localhost";
        int targetPort = 2375;

        System.out.println("Listening on :" + listenPort + " → :" + targetPort);
        System.out.flush();

        try (ServerSocket ss = new ServerSocket(listenPort)) {
            Socket client = ss.accept();
            System.out.println("Client connected: " + client.getRemoteSocketAddress());

            client.setSoTimeout(8000);
            InputStream  cin  = client.getInputStream();
            OutputStream cout = client.getOutputStream();

            // Read until end of HTTP headers (\r\n\r\n)
            ByteArrayOutputStream reqBuf = new ByteArrayOutputStream();
            byte[] b = new byte[1];
            while (true) {
                int n = cin.read(b);
                if (n <= 0) break;
                reqBuf.write(b, 0, 1);
                byte[] so_far = reqBuf.toByteArray();
                int len = so_far.length;
                if (len >= 4 &&
                    so_far[len-4]=='\r' && so_far[len-3]=='\n' &&
                    so_far[len-2]=='\r' && so_far[len-1]=='\n') break;
                if (len > 65536) break;
            }

            byte[] reqBytes = reqBuf.toByteArray();

            System.out.println("\n=== EXACT REQUEST SENT BY HC5 (" + reqBytes.length + " bytes) ===");
            System.out.println(new String(reqBytes, StandardCharsets.UTF_8));
            System.out.println("=== END REQUEST ===");
            System.out.flush();

            // Forward to Docker
            Socket docker = new Socket(targetHost, targetPort);
            docker.setSoTimeout(8000);
            OutputStream dout = docker.getOutputStream();
            InputStream  din  = docker.getInputStream();

            dout.write(reqBytes);
            dout.flush();

            // Read response headers
            ByteArrayOutputStream respBuf = new ByteArrayOutputStream();
            byte[] rb = new byte[1];
            while (true) {
                int n = din.read(rb);
                if (n <= 0) break;
                respBuf.write(rb, 0, 1);
                byte[] sf = respBuf.toByteArray();
                int len = sf.length;
                if (len >= 4 &&
                    sf[len-4]=='\r' && sf[len-3]=='\n' &&
                    sf[len-2]=='\r' && sf[len-1]=='\n') break;
                if (len > 65536) break;
            }

            byte[] respHeaderBytes = respBuf.toByteArray();
            System.out.println("=== RESPONSE FROM DOCKER ===");
            System.out.println(new String(respHeaderBytes, StandardCharsets.UTF_8));
            System.out.flush();

            // Read remaining body and forward everything back
            cout.write(respHeaderBytes);
            byte[] buf = new byte[4096];
            int n;
            try { while ((n = din.read(buf)) != -1) { cout.write(buf, 0, n); } }
            catch (SocketTimeoutException ignored) {}

            docker.close();
            cout.flush();
            client.close();
        }
        System.out.println("Done.");
    }
}
