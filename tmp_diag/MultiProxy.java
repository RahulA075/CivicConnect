import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.*;

public class MultiProxy {
    public static void main(String[] args) throws Exception {
        ServerSocket ss = new ServerSocket(2376);
        System.out.println("MultiProxy ready on :2376");
        System.out.flush();
        ExecutorService pool = Executors.newCachedThreadPool();
        while (true) { Socket client = ss.accept(); pool.submit(() -> handle(client)); }
    }
    static void handle(Socket client) {
        try {
            client.setSoTimeout(8000);
            InputStream cin = client.getInputStream();
            OutputStream cout = client.getOutputStream();
            ByteArrayOutputStream buf = new ByteArrayOutputStream();
            byte[] b = new byte[1];
            while (true) {
                if (cin.read(b) <= 0) break;
                buf.write(b, 0, 1);
                byte[] sf = buf.toByteArray(); int len = sf.length;
                if (len>=4 && sf[len-4]=='\r' && sf[len-3]=='\n' && sf[len-2]=='\r' && sf[len-1]=='\n') break;
                if (len > 65536) break;
            }
            byte[] req = buf.toByteArray();
            System.out.println("=== REQUEST ===\n" + new String(req, StandardCharsets.UTF_8) + "=== END ===\n");
            System.out.flush();
            Socket docker = new Socket("localhost", 2375);
            docker.setSoTimeout(8000);
            docker.getOutputStream().write(req); docker.getOutputStream().flush();
            ByteArrayOutputStream rb = new ByteArrayOutputStream();
            byte[] rbuf = new byte[4096]; int n;
            try { while ((n = docker.getInputStream().read(rbuf)) != -1) rb.write(rbuf, 0, n); }
            catch (SocketTimeoutException ignored) {}
            docker.close();
            byte[] resp = rb.toByteArray();
            System.out.println("=== RESPONSE: " + new String(resp, StandardCharsets.UTF_8).split("\r\n")[0] + " ===\n");
            System.out.flush();
            cout.write(resp); cout.flush(); client.close();
        } catch (Exception e) { System.out.println("[ERR] " + e.getMessage()); System.out.flush(); }
    }
}