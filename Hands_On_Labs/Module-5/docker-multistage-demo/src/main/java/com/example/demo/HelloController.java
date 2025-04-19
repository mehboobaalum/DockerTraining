package com.example.demo;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.net.InetAddress;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
public class HelloController {

    @Value("${spring.application.name}")
    private String appName;

    @GetMapping("/")
    public Map<String, Object> hello() {
        Map<String, Object> response = new HashMap<>();
        response.put("message", "Hello from " + appName);
        response.put("timestamp", LocalDateTime.now().toString());
        
        try {
            response.put("hostname", InetAddress.getLocalHost().getHostName());
        } catch (Exception e) {
            response.put("hostname", "unknown");
        }
        
        return response;
    }
}
