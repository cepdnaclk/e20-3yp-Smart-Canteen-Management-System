package com.SmartCanteen.Backend.Config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.web.client.RestTemplate;

import java.net.http.HttpClient;
import java.time.Duration;

// Removed all SSL-related imports (javax.net.ssl.*, java.security.cert.*, etc.)

@Configuration
public class RestTemplateConfig {

    @Value("${rest.template.connection-timeout}")
    private int connectionTimeout;

    @Value("${rest.template.read-timeout}")
    private int readTimeout;

    @Bean
    public RestTemplate restTemplate() {
        // For HTTP communication, no custom SSLContext is needed.
        // We simply build a standard HttpClient.
        HttpClient httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofMillis(connectionTimeout))
                .build();

        // JdkClientHttpRequestFactory uses the configured HttpClient
        JdkClientHttpRequestFactory factory = new JdkClientHttpRequestFactory(httpClient);
        // Set the read timeout directly on the factory for consistency with RestTemplate behavior
        factory.setReadTimeout(Duration.ofMillis(readTimeout));

        return new RestTemplate(factory);
    }
}