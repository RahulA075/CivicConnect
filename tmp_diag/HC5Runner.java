import com.github.dockerjava.zerodep.shaded.org.apache.hc.client5.http.classic.methods.HttpGet;
import com.github.dockerjava.zerodep.shaded.org.apache.hc.client5.http.impl.classic.CloseableHttpClient;
import com.github.dockerjava.zerodep.shaded.org.apache.hc.client5.http.impl.classic.HttpClients;
import com.github.dockerjava.zerodep.shaded.org.apache.hc.core5.http.ClassicHttpResponse;
import com.github.dockerjava.zerodep.shaded.org.apache.hc.core5.http.Header;
import java.io.*;

/**
 * Runs an Apache HttpClient 5 GET request (using docker-java's shaded classes)
 * against the target URL, printing request and response details.
 * Run via: java -cp tmp_diag;<zerodep-jar> HC5Runner <url>
 */
public class HC5Runner {
    public static void main(String[] args) throws Exception {
        String url = args.length > 0 ? args[0] : "http://localhost:2375/info";
        System.out.println("HC5Runner: GET " + url);

        try (CloseableHttpClient client = HttpClients.createDefault()) {
            HttpGet request = new HttpGet(url);

            System.out.println("\nRequest headers set by HttpClient5:");
            // HttpGet doesn't expose headers until executed; we print after
            
            try (ClassicHttpResponse response = (ClassicHttpResponse) client.execute(request)) {
                System.out.println("HTTP Status: " + response.getCode());
                System.out.println("Response headers:");
                for (Header h : response.getHeaders()) {
                    System.out.println("  " + h.getName() + ": " + h.getValue());
                }
                byte[] body = response.getEntity().getContent().readAllBytes();
                String bodyStr = new String(body);
                System.out.println("\nBody (first 300 chars): " +
                    bodyStr.substring(0, Math.min(300, bodyStr.length())));
            }
        }
    }
}
