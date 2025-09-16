package com.ecommerce;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class OrderServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(OrderServiceApplication.class, args);
    }

    @GetMapping("/health")
    public String health() {
        return "{\"status\":\"healthy\",\"service\":\"order-service\"}";
    }

    @GetMapping("/orders")
    public String orders() {
        return "{\"orders\":[],\"message\":\"Order service running\"}";
    }
}