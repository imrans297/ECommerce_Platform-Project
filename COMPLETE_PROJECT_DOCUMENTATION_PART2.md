# Complete Enterprise E-commerce Platform - Part 2
## Order Service, Notification Service & Complete CI/CD Pipeline

---

## 🛍️ **Order Service (Java/Spring Boot) - Complete Implementation**

### **1. Project Structure**
```
applications/order-service/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/
│   │   │       └── ecommerce/
│   │   │           ├── OrderServiceApplication.java
│   │   │           ├── config/
│   │   │           │   ├── DatabaseConfig.java
│   │   │           │   ├── SecurityConfig.java
│   │   │           │   └── RabbitMQConfig.java
│   │   │           ├── controller/
│   │   │           │   ├── OrderController.java
│   │   │           │   └── PaymentController.java
│   │   │           ├── service/
│   │   │           │   ├── OrderService.java
│   │   │           │   ├── PaymentService.java
│   │   │           │   └── InventoryService.java
│   │   │           ├── model/
│   │   │           │   ├── Order.java
│   │   │           │   ├── OrderItem.java
│   │   │           │   └── Payment.java
│   │   │           ├── repository/
│   │   │           │   ├── OrderRepository.java
│   │   │           │   └── PaymentRepository.java
│   │   │           ├── dto/
│   │   │           │   ├── OrderDTO.java
│   │   │           │   └── CreateOrderRequest.java
│   │   │           └── exception/
│   │   │               └── GlobalExceptionHandler.java
│   │   └── resources/
│   │       ├── application.yml
│   │       └── db/migration/
│   └── test/
├── pom.xml
└── Dockerfile
```

### **2. Order Entity Model**
```java
// model/Order.java
package com.ecommerce.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "orders")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Order {
    
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;
    
    @Column(name = "order_number", unique = true, nullable = false)
    private String orderNumber;
    
    @Column(name = "user_id", nullable = false)
    private UUID userId;
    
    @Column(name = "customer_email", nullable = false)
    @Email
    private String customerEmail;
    
    @Column(name = "customer_name", nullable = false)
    private String customerName;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private OrderStatus status = OrderStatus.PENDING;
    
    @Column(name = "subtotal", precision = 10, scale = 2, nullable = false)
    private BigDecimal subtotal;
    
    @Column(name = "tax_amount", precision = 10, scale = 2)
    private BigDecimal taxAmount = BigDecimal.ZERO;
    
    @Column(name = "shipping_amount", precision = 10, scale = 2)
    private BigDecimal shippingAmount = BigDecimal.ZERO;
    
    @Column(name = "discount_amount", precision = 10, scale = 2)
    private BigDecimal discountAmount = BigDecimal.ZERO;
    
    @Column(name = "total_amount", precision = 10, scale = 2, nullable = false)
    private BigDecimal totalAmount;
    
    @Embedded
    private ShippingAddress shippingAddress;
    
    @Embedded
    private BillingAddress billingAddress;
    
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<OrderItem> orderItems;
    
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Payment> payments;
    
    @Column(name = "notes")
    private String notes;
    
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    
    @Column(name = "shipped_at")
    private LocalDateTime shippedAt;
    
    @Column(name = "delivered_at")
    private LocalDateTime deliveredAt;
    
    // Business methods
    public void calculateTotalAmount() {
        this.totalAmount = subtotal
            .add(taxAmount)
            .add(shippingAmount)
            .subtract(discountAmount);
    }
    
    public boolean canBeCancelled() {
        return status == OrderStatus.PENDING || status == OrderStatus.CONFIRMED;
    }
    
    public void markAsShipped() {
        this.status = OrderStatus.SHIPPED;
        this.shippedAt = LocalDateTime.now();
    }
    
    public void markAsDelivered() {
        this.status = OrderStatus.DELIVERED;
        this.deliveredAt = LocalDateTime.now();
    }
}

@Entity
@Table(name = "order_items")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class OrderItem {
    
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;
    
    @Column(name = "product_id", nullable = false)
    private UUID productId;
    
    @Column(name = "product_name", nullable = false)
    private String productName;
    
    @Column(name = "product_sku", nullable = false)
    private String productSku;
    
    @Column(name = "quantity", nullable = false)
    @Min(1)
    private Integer quantity;
    
    @Column(name = "unit_price", precision = 10, scale = 2, nullable = false)
    private BigDecimal unitPrice;
    
    @Column(name = "total_price", precision = 10, scale = 2, nullable = false)
    private BigDecimal totalPrice;
    
    @PrePersist
    @PreUpdate
    public void calculateTotalPrice() {
        this.totalPrice = unitPrice.multiply(BigDecimal.valueOf(quantity));
    }
}

// Enums
public enum OrderStatus {
    PENDING,
    CONFIRMED,
    PROCESSING,
    SHIPPED,
    DELIVERED,
    CANCELLED,
    REFUNDED
}

@Embeddable
@Data
public class ShippingAddress {
    @Column(name = "shipping_first_name")
    private String firstName;
    
    @Column(name = "shipping_last_name")
    private String lastName;
    
    @Column(name = "shipping_address_line1")
    private String addressLine1;
    
    @Column(name = "shipping_address_line2")
    private String addressLine2;
    
    @Column(name = "shipping_city")
    private String city;
    
    @Column(name = "shipping_state")
    private String state;
    
    @Column(name = "shipping_postal_code")
    private String postalCode;
    
    @Column(name = "shipping_country")
    private String country;
    
    @Column(name = "shipping_phone")
    private String phone;
}
```

### **3. Order Service Implementation**
```java
// service/OrderService.java
package com.ecommerce.service;

import com.ecommerce.dto.CreateOrderRequest;
import com.ecommerce.dto.OrderDTO;
import com.ecommerce.exception.OrderNotFoundException;
import com.ecommerce.exception.InsufficientInventoryException;
import com.ecommerce.model.Order;
import com.ecommerce.model.OrderItem;
import com.ecommerce.model.OrderStatus;
import com.ecommerce.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class OrderService {
    
    private final OrderRepository orderRepository;
    private final InventoryService inventoryService;
    private final PaymentService paymentService;
    private final NotificationService notificationService;
    
    public OrderDTO createOrder(CreateOrderRequest request) {
        log.info("Creating order for user: {}", request.getUserId());
        
        try {
            // Validate inventory
            validateInventory(request.getItems());
            
            // Create order entity
            Order order = new Order();
            order.setOrderNumber(generateOrderNumber());
            order.setUserId(request.getUserId());
            order.setCustomerEmail(request.getCustomerEmail());
            order.setCustomerName(request.getCustomerName());
            order.setStatus(OrderStatus.PENDING);
            order.setShippingAddress(request.getShippingAddress());
            order.setBillingAddress(request.getBillingAddress());
            order.setNotes(request.getNotes());
            
            // Create order items
            List<OrderItem> orderItems = request.getItems().stream()
                .map(itemRequest -> {
                    OrderItem item = new OrderItem();
                    item.setOrder(order);
                    item.setProductId(itemRequest.getProductId());
                    item.setProductName(itemRequest.getProductName());
                    item.setProductSku(itemRequest.getProductSku());
                    item.setQuantity(itemRequest.getQuantity());
                    item.setUnitPrice(itemRequest.getUnitPrice());
                    return item;
                })
                .collect(Collectors.toList());
            
            order.setOrderItems(orderItems);
            
            // Calculate amounts
            calculateOrderAmounts(order);
            
            // Reserve inventory
            reserveInventory(orderItems);
            
            // Save order
            Order savedOrder = orderRepository.save(order);
            
            // Send confirmation notification
            notificationService.sendOrderConfirmation(savedOrder);
            
            log.info("Order created successfully: {}", savedOrder.getOrderNumber());
            return convertToDTO(savedOrder);
            
        } catch (Exception e) {
            log.error("Error creating order for user {}: {}", request.getUserId(), e.getMessage());
            throw new RuntimeException("Failed to create order: " + e.getMessage());
        }
    }
    
    @Transactional(readOnly = true)
    public OrderDTO getOrder(UUID orderId) {
        Order order = orderRepository.findById(orderId)
            .orElseThrow(() -> new OrderNotFoundException("Order not found: " + orderId));
        return convertToDTO(order);
    }
    
    @Transactional(readOnly = true)
    public Page<OrderDTO> getUserOrders(UUID userId, Pageable pageable) {
        Page<Order> orders = orderRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable);
        return orders.map(this::convertToDTO);
    }
    
    @Transactional(readOnly = true)
    public Page<OrderDTO> getAllOrders(Pageable pageable) {
        Page<Order> orders = orderRepository.findAllByOrderByCreatedAtDesc(pageable);
        return orders.map(this::convertToDTO);
    }
    
    public OrderDTO updateOrderStatus(UUID orderId, OrderStatus newStatus) {
        Order order = orderRepository.findById(orderId)
            .orElseThrow(() -> new OrderNotFoundException("Order not found: " + orderId));
        
        OrderStatus oldStatus = order.getStatus();
        order.setStatus(newStatus);
        
        // Handle status-specific logic
        switch (newStatus) {
            case CONFIRMED:
                handleOrderConfirmation(order);
                break;
            case SHIPPED:
                order.markAsShipped();
                notificationService.sendShippingNotification(order);
                break;
            case DELIVERED:
                order.markAsDelivered();
                notificationService.sendDeliveryNotification(order);
                break;
            case CANCELLED:
                handleOrderCancellation(order);
                break;
        }
        
        Order updatedOrder = orderRepository.save(order);
        
        log.info("Order {} status updated from {} to {}", 
            order.getOrderNumber(), oldStatus, newStatus);
        
        return convertToDTO(updatedOrder);
    }
    
    public OrderDTO cancelOrder(UUID orderId, String reason) {
        Order order = orderRepository.findById(orderId)
            .orElseThrow(() -> new OrderNotFoundException("Order not found: " + orderId));
        
        if (!order.canBeCancelled()) {
            throw new IllegalStateException("Order cannot be cancelled in current status: " + order.getStatus());
        }
        
        order.setStatus(OrderStatus.CANCELLED);
        order.setNotes(order.getNotes() + "\nCancellation reason: " + reason);
        
        // Release reserved inventory
        releaseInventory(order.getOrderItems());
        
        // Process refund if payment was made
        if (order.getPayments() != null && !order.getPayments().isEmpty()) {
            paymentService.processRefund(order);
        }
        
        Order cancelledOrder = orderRepository.save(order);
        
        // Send cancellation notification
        notificationService.sendCancellationNotification(cancelledOrder);
        
        log.info("Order cancelled: {}", order.getOrderNumber());
        return convertToDTO(cancelledOrder);
    }
    
    // Private helper methods
    private void validateInventory(List<CreateOrderRequest.OrderItemRequest> items) {
        for (CreateOrderRequest.OrderItemRequest item : items) {
            if (!inventoryService.isAvailable(item.getProductId(), item.getQuantity())) {
                throw new InsufficientInventoryException(
                    "Insufficient inventory for product: " + item.getProductSku());
            }
        }
    }
    
    private void calculateOrderAmounts(Order order) {
        BigDecimal subtotal = order.getOrderItems().stream()
            .map(item -> item.getUnitPrice().multiply(BigDecimal.valueOf(item.getQuantity())))
            .reduce(BigDecimal.ZERO, BigDecimal::add);
        
        order.setSubtotal(subtotal);
        
        // Calculate tax (8% for demo)
        BigDecimal taxAmount = subtotal.multiply(BigDecimal.valueOf(0.08));
        order.setTaxAmount(taxAmount);
        
        // Calculate shipping (free over $100)
        BigDecimal shippingAmount = subtotal.compareTo(BigDecimal.valueOf(100)) >= 0 
            ? BigDecimal.ZERO 
            : BigDecimal.valueOf(10.00);
        order.setShippingAmount(shippingAmount);
        
        order.calculateTotalAmount();
    }
    
    private void reserveInventory(List<OrderItem> orderItems) {
        for (OrderItem item : orderItems) {
            inventoryService.reserveInventory(item.getProductId(), item.getQuantity());
        }
    }
    
    private void releaseInventory(List<OrderItem> orderItems) {
        for (OrderItem item : orderItems) {
            inventoryService.releaseInventory(item.getProductId(), item.getQuantity());
        }
    }
    
    private void handleOrderConfirmation(Order order) {
        // Process payment
        paymentService.processPayment(order);
        
        // Update inventory
        for (OrderItem item : order.getOrderItems()) {
            inventoryService.updateInventory(item.getProductId(), -item.getQuantity());
        }
        
        // Send confirmation
        notificationService.sendOrderConfirmation(order);
    }
    
    private void handleOrderCancellation(Order order) {
        releaseInventory(order.getOrderItems());
        notificationService.sendCancellationNotification(order);
    }
    
    private String generateOrderNumber() {
        return "ORD-" + System.currentTimeMillis();
    }
    
    private OrderDTO convertToDTO(Order order) {
        // Convert Order entity to DTO
        return OrderDTO.builder()
            .id(order.getId())
            .orderNumber(order.getOrderNumber())
            .userId(order.getUserId())
            .customerEmail(order.getCustomerEmail())
            .customerName(order.getCustomerName())
            .status(order.getStatus())
            .subtotal(order.getSubtotal())
            .taxAmount(order.getTaxAmount())
            .shippingAmount(order.getShippingAmount())
            .discountAmount(order.getDiscountAmount())
            .totalAmount(order.getTotalAmount())
            .shippingAddress(order.getShippingAddress())
            .billingAddress(order.getBillingAddress())
            .notes(order.getNotes())
            .createdAt(order.getCreatedAt())
            .updatedAt(order.getUpdatedAt())
            .shippedAt(order.getShippedAt())
            .deliveredAt(order.getDeliveredAt())
            .build();
    }
}
```

### **4. Order Controller**
```java
// controller/OrderController.java
package com.ecommerce.controller;

import com.ecommerce.dto.CreateOrderRequest;
import com.ecommerce.dto.OrderDTO;
import com.ecommerce.model.OrderStatus;
import com.ecommerce.service.OrderService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/orders")
@RequiredArgsConstructor
@Tag(name = "Orders", description = "Order management endpoints")
public class OrderController {
    
    private final OrderService orderService;
    
    @PostMapping
    @Operation(summary = "Create new order")
    public ResponseEntity<ApiResponse<OrderDTO>> createOrder(
            @Valid @RequestBody CreateOrderRequest request) {
        
        OrderDTO order = orderService.createOrder(request);
        
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.<OrderDTO>builder()
                .success(true)
                .message("Order created successfully")
                .data(order)
                .build());
    }
    
    @GetMapping("/{orderId}")
    @Operation(summary = "Get order by ID")
    public ResponseEntity<ApiResponse<OrderDTO>> getOrder(@PathVariable UUID orderId) {
        OrderDTO order = orderService.getOrder(orderId);
        
        return ResponseEntity.ok(ApiResponse.<OrderDTO>builder()
            .success(true)
            .data(order)
            .build());
    }
    
    @GetMapping("/user/{userId}")
    @Operation(summary = "Get user orders")
    @PreAuthorize("hasRole('ADMIN') or #userId == authentication.principal.userId")
    public ResponseEntity<ApiResponse<Page<OrderDTO>>> getUserOrders(
            @PathVariable UUID userId,
            Pageable pageable) {
        
        Page<OrderDTO> orders = orderService.getUserOrders(userId, pageable);
        
        return ResponseEntity.ok(ApiResponse.<Page<OrderDTO>>builder()
            .success(true)
            .data(orders)
            .build());
    }
    
    @GetMapping
    @Operation(summary = "Get all orders (Admin only)")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Page<OrderDTO>>> getAllOrders(Pageable pageable) {
        Page<OrderDTO> orders = orderService.getAllOrders(pageable);
        
        return ResponseEntity.ok(ApiResponse.<Page<OrderDTO>>builder()
            .success(true)
            .data(orders)
            .build());
    }
    
    @PutMapping("/{orderId}/status")
    @Operation(summary = "Update order status (Admin only)")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<OrderDTO>> updateOrderStatus(
            @PathVariable UUID orderId,
            @RequestParam OrderStatus status) {
        
        OrderDTO order = orderService.updateOrderStatus(orderId, status);
        
        return ResponseEntity.ok(ApiResponse.<OrderDTO>builder()
            .success(true)
            .message("Order status updated successfully")
            .data(order)
            .build());
    }
    
    @PostMapping("/{orderId}/cancel")
    @Operation(summary = "Cancel order")
    public ResponseEntity<ApiResponse<OrderDTO>> cancelOrder(
            @PathVariable UUID orderId,
            @RequestParam(required = false) String reason) {
        
        OrderDTO order = orderService.cancelOrder(orderId, reason);
        
        return ResponseEntity.ok(ApiResponse.<OrderDTO>builder()
            .success(true)
            .message("Order cancelled successfully")
            .data(order)
            .build());
    }
    
    @GetMapping("/health")
    @Operation(summary = "Health check endpoint")
    public ResponseEntity<ApiResponse<String>> healthCheck() {
        return ResponseEntity.ok(ApiResponse.<String>builder()
            .success(true)
            .data("Order service is healthy")
            .build());
    }
}
```

### **5. Order Service Configuration**
```yaml
# application.yml
server:
  port: 8080
  servlet:
    context-path: /

spring:
  application:
    name: order-service
  
  datasource:
    url: jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:ecommerce}
    username: ${DB_USERNAME:postgres}
    password: ${DB_PASSWORD:password}
    driver-class-name: org.postgresql.Driver
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
  
  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
        format_sql: true
        use_sql_comments: true
        jdbc:
          batch_size: 20
        order_inserts: true
        order_updates: true
  
  flyway:
    enabled: true
    locations: classpath:db/migration
    baseline-on-migrate: true
  
  rabbitmq:
    host: ${RABBITMQ_HOST:localhost}
    port: ${RABBITMQ_PORT:5672}
    username: ${RABBITMQ_USERNAME:guest}
    password: ${RABBITMQ_PASSWORD:guest}
    virtual-host: /
  
  redis:
    host: ${REDIS_HOST:localhost}
    port: ${REDIS_PORT:6379}
    password: ${REDIS_PASSWORD:}
    timeout: 2000ms
    lettuce:
      pool:
        max-active: 8
        max-idle: 8
        min-idle: 0

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    health:
      show-details: always
  metrics:
    export:
      prometheus:
        enabled: true

logging:
  level:
    com.ecommerce: DEBUG
    org.springframework.security: DEBUG
    org.hibernate.SQL: DEBUG
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} - %msg%n"
    file: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n"
  file:
    name: logs/order-service.log

# Custom application properties
app:
  security:
    jwt:
      secret: ${JWT_SECRET:mySecretKey}
      expiration: 86400000 # 24 hours
  
  payment:
    gateway:
      url: ${PAYMENT_GATEWAY_URL:http://localhost:8081}
      api-key: ${PAYMENT_API_KEY:test-key}
  
  inventory:
    service:
      url: ${INVENTORY_SERVICE_URL:http://localhost:8082}
  
  notification:
    service:
      url: ${NOTIFICATION_SERVICE_URL:http://localhost:9000}
```

### **6. Order Service Dockerfile**
```dockerfile
FROM openjdk:17-jdk-slim

WORKDIR /app

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy Maven wrapper and pom.xml
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./

# Download dependencies
RUN ./mvnw dependency:go-offline -B

# Copy source code
COPY src ./src

# Build application
RUN ./mvnw clean package -DskipTests

# Create non-root user
RUN useradd --create-home --shell /bin/bash spring && \
    chown -R spring:spring /app
USER spring

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/api/orders/health || exit 1

EXPOSE 8080

CMD ["java", "-jar", "target/order-service-1.0.0.jar"]
```

---

## 📢 **Notification Service (Go) - Complete Implementation**

### **1. Project Structure**
```
applications/notification-service/
├── cmd/
│   └── server/
│       └── main.go
├── internal/
│   ├── config/
│   │   └── config.go
│   ├── handler/
│   │   ├── notification.go
│   │   └── health.go
│   ├── service/
│   │   ├── email.go
│   │   ├── sms.go
│   │   └── push.go
│   ├── model/
│   │   └── notification.go
│   ├── repository/
│   │   └── notification.go
│   └── middleware/
│       ├── auth.go
│       ├── cors.go
│       └── logging.go
├── pkg/
│   ├── database/
│   │   └── redis.go
│   └── queue/
│       └── rabbitmq.go
├── templates/
│   ├── email/
│   │   ├── order_confirmation.html
│   │   ├── shipping_notification.html
│   │   └── welcome.html
│   └── sms/
├── go.mod
├── go.sum
├── Dockerfile
└── docker-compose.yml
```

### **2. Main Application**
```go
// cmd/server/main.go
package main

import (
    "context"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/ecommerce/notification-service/internal/config"
    "github.com/ecommerce/notification-service/internal/handler"
    "github.com/ecommerce/notification-service/internal/middleware"
    "github.com/ecommerce/notification-service/internal/service"
    "github.com/ecommerce/notification-service/pkg/database"
    "github.com/ecommerce/notification-service/pkg/queue"
)

func main() {
    // Load configuration
    cfg := config.Load()

    // Initialize database connections
    redisClient, err := database.NewRedisClient(cfg.Redis)
    if err != nil {
        log.Fatalf("Failed to connect to Redis: %v", err)
    }
    defer redisClient.Close()

    // Initialize message queue
    rabbitMQ, err := queue.NewRabbitMQ(cfg.RabbitMQ)
    if err != nil {
        log.Fatalf("Failed to connect to RabbitMQ: %v", err)
    }
    defer rabbitMQ.Close()

    // Initialize services
    emailService := service.NewEmailService(cfg.Email)
    smsService := service.NewSMSService(cfg.SMS)
    pushService := service.NewPushService(cfg.Push)
    
    notificationService := service.NewNotificationService(
        emailService,
        smsService,
        pushService,
        redisClient,
        rabbitMQ,
    )

    // Initialize handlers
    notificationHandler := handler.NewNotificationHandler(notificationService)
    healthHandler := handler.NewHealthHandler()

    // Setup Gin router
    if cfg.Environment == "production" {
        gin.SetMode(gin.ReleaseMode)
    }

    router := gin.New()
    
    // Middleware
    router.Use(middleware.Logger())
    router.Use(middleware.CORS())
    router.Use(gin.Recovery())

    // Health check routes
    router.GET("/health", healthHandler.HealthCheck)
    router.GET("/ready", healthHandler.ReadinessCheck)

    // API routes
    api := router.Group("/api/v1")
    {
        // Notification routes
        notifications := api.Group("/notifications")
        notifications.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
        {
            notifications.POST("/email", notificationHandler.SendEmail)
            notifications.POST("/sms", notificationHandler.SendSMS)
            notifications.POST("/push", notificationHandler.SendPush)
            notifications.POST("/bulk", notificationHandler.SendBulkNotification)
            notifications.GET("/status/:id", notificationHandler.GetNotificationStatus)
            notifications.GET("/history", notificationHandler.GetNotificationHistory)
        }

        // Webhook routes for external services
        webhooks := api.Group("/webhooks")
        {
            webhooks.POST("/email/status", notificationHandler.EmailStatusWebhook)
            webhooks.POST("/sms/status", notificationHandler.SMSStatusWebhook)
        }
    }

    // Start message queue consumers
    go notificationService.StartConsumers(context.Background())

    // Setup HTTP server
    server := &http.Server{
        Addr:         ":" + cfg.Server.Port,
        Handler:      router,
        ReadTimeout:  time.Duration(cfg.Server.ReadTimeout) * time.Second,
        WriteTimeout: time.Duration(cfg.Server.WriteTimeout) * time.Second,
        IdleTimeout:  time.Duration(cfg.Server.IdleTimeout) * time.Second,
    }

    // Start server in a goroutine
    go func() {
        log.Printf("Starting server on port %s", cfg.Server.Port)
        if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatalf("Failed to start server: %v", err)
        }
    }()

    // Wait for interrupt signal to gracefully shutdown
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    log.Println("Shutting down server...")

    // Graceful shutdown with timeout
    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()

    if err := server.Shutdown(ctx); err != nil {
        log.Fatalf("Server forced to shutdown: %v", err)
    }

    log.Println("Server exited")
}
```

### **3. Notification Models**
```go
// internal/model/notification.go
package model

import (
    "time"
    "github.com/google/uuid"
)

type NotificationType string

const (
    NotificationTypeEmail NotificationType = "email"
    NotificationTypeSMS   NotificationType = "sms"
    NotificationTypePush  NotificationType = "push"
)

type NotificationStatus string

const (
    NotificationStatusPending   NotificationStatus = "pending"
    NotificationStatusSent      NotificationStatus = "sent"
    NotificationStatusDelivered NotificationStatus = "delivered"
    NotificationStatusFailed    NotificationStatus = "failed"
    NotificationStatusBounced   NotificationStatus = "bounced"
)

type Notification struct {
    ID          uuid.UUID          `json:"id" redis:"id"`
    Type        NotificationType   `json:"type" redis:"type"`
    Status      NotificationStatus `json:"status" redis:"status"`
    Recipient   string             `json:"recipient" redis:"recipient"`
    Subject     string             `json:"subject,omitempty" redis:"subject"`
    Content     string             `json:"content" redis:"content"`
    Template    string             `json:"template,omitempty" redis:"template"`
    Data        map[string]interface{} `json:"data,omitempty" redis:"data"`
    Priority    int                `json:"priority" redis:"priority"`
    ScheduledAt *time.Time         `json:"scheduled_at,omitempty" redis:"scheduled_at"`
    SentAt      *time.Time         `json:"sent_at,omitempty" redis:"sent_at"`
    DeliveredAt *time.Time         `json:"delivered_at,omitempty" redis:"delivered_at"`
    FailedAt    *time.Time         `json:"failed_at,omitempty" redis:"failed_at"`
    ErrorMsg    string             `json:"error_message,omitempty" redis:"error_message"`
    Attempts    int                `json:"attempts" redis:"attempts"`
    MaxAttempts int                `json:"max_attempts" redis:"max_attempts"`
    CreatedAt   time.Time          `json:"created_at" redis:"created_at"`
    UpdatedAt   time.Time          `json:"updated_at" redis:"updated_at"`
}

type EmailNotification struct {
    To          []string           `json:"to" validate:"required"`
    CC          []string           `json:"cc,omitempty"`
    BCC         []string           `json:"bcc,omitempty"`
    Subject     string             `json:"subject" validate:"required"`
    HTMLContent string             `json:"html_content,omitempty"`
    TextContent string             `json:"text_content,omitempty"`
    Template    string             `json:"template,omitempty"`
    Data        map[string]interface{} `json:"data,omitempty"`
    Attachments []Attachment       `json:"attachments,omitempty"`
    Priority    int                `json:"priority,omitempty"`
    ScheduledAt *time.Time         `json:"scheduled_at,omitempty"`
}

type SMSNotification struct {
    To          string             `json:"to" validate:"required,e164"`
    Message     string             `json:"message" validate:"required,max=160"`
    Template    string             `json:"template,omitempty"`
    Data        map[string]interface{} `json:"data,omitempty"`
    Priority    int                `json:"priority,omitempty"`
    ScheduledAt *time.Time         `json:"scheduled_at,omitempty"`
}

type PushNotification struct {
    To          []string           `json:"to" validate:"required"`
    Title       string             `json:"title" validate:"required"`
    Body        string             `json:"body" validate:"required"`
    Icon        string             `json:"icon,omitempty"`
    Image       string             `json:"image,omitempty"`
    Data        map[string]interface{} `json:"data,omitempty"`
    Priority    int                `json:"priority,omitempty"`
    ScheduledAt *time.Time         `json:"scheduled_at,omitempty"`
}

type Attachment struct {
    Filename    string `json:"filename" validate:"required"`
    ContentType string `json:"content_type" validate:"required"`
    Content     []byte `json:"content" validate:"required"`
}

type BulkNotificationRequest struct {
    Type         NotificationType   `json:"type" validate:"required"`
    Recipients   []string           `json:"recipients" validate:"required,min=1"`
    Subject      string             `json:"subject,omitempty"`
    Content      string             `json:"content,omitempty"`
    Template     string             `json:"template,omitempty"`
    Data         map[string]interface{} `json:"data,omitempty"`
    Priority     int                `json:"priority,omitempty"`
    ScheduledAt  *time.Time         `json:"scheduled_at,omitempty"`
}

// Order-related notification events
type OrderEvent struct {
    EventType   string      `json:"event_type"`
    OrderID     uuid.UUID   `json:"order_id"`
    UserID      uuid.UUID   `json:"user_id"`
    OrderNumber string      `json:"order_number"`
    CustomerEmail string    `json:"customer_email"`
    CustomerName  string    `json:"customer_name"`
    TotalAmount   float64   `json:"total_amount"`
    Items         []OrderItem `json:"items"`
    ShippingAddress Address `json:"shipping_address"`
    TrackingNumber  string  `json:"tracking_number,omitempty"`
    Timestamp     time.Time `json:"timestamp"`
}

type OrderItem struct {
    ProductName string  `json:"product_name"`
    Quantity    int     `json:"quantity"`
    UnitPrice   float64 `json:"unit_price"`
    TotalPrice  float64 `json:"total_price"`
}

type Address struct {
    FirstName    string `json:"first_name"`
    LastName     string `json:"last_name"`
    AddressLine1 string `json:"address_line1"`
    AddressLine2 string `json:"address_line2"`
    City         string `json:"city"`
    State        string `json:"state"`
    PostalCode   string `json:"postal_code"`
    Country      string `json:"country"`
    Phone        string `json:"phone"`
}
```

### **4. Email Service Implementation**
```go
// internal/service/email.go
package service

import (
    "bytes"
    "context"
    "fmt"
    "html/template"
    "log"
    "path/filepath"
    "time"

    "github.com/ecommerce/notification-service/internal/config"
    "github.com/ecommerce/notification-service/internal/model"
    "gopkg.in/gomail.v2"
)

type EmailService struct {
    config    config.EmailConfig
    templates map[string]*template.Template
    dialer    *gomail.Dialer
}

func NewEmailService(cfg config.EmailConfig) *EmailService {
    dialer := gomail.NewDialer(cfg.SMTPHost, cfg.SMTPPort, cfg.Username, cfg.Password)
    
    service := &EmailService{
        config:    cfg,
        templates: make(map[string]*template.Template),
        dialer:    dialer,
    }
    
    // Load email templates
    service.loadTemplates()
    
    return service
}

func (s *EmailService) loadTemplates() {
    templateDir := "templates/email"
    
    templates := []string{
        "order_confirmation.html",
        "shipping_notification.html",
        "delivery_notification.html",
        "order_cancellation.html",
        "welcome.html",
        "password_reset.html",
    }
    
    for _, tmplName := range templates {
        tmplPath := filepath.Join(templateDir, tmplName)
        tmpl, err := template.ParseFiles(tmplPath)
        if err != nil {
            log.Printf("Warning: Failed to load template %s: %v", tmplName, err)
            continue
        }
        
        // Remove .html extension for template name
        name := tmplName[:len(tmplName)-5]
        s.templates[name] = tmpl
    }
    
    log.Printf("Loaded %d email templates", len(s.templates))
}

func (s *EmailService) SendEmail(ctx context.Context, notification *model.EmailNotification) error {
    message := gomail.NewMessage()
    
    // Set sender
    message.SetHeader("From", s.config.FromEmail)
    
    // Set recipients
    message.SetHeader("To", notification.To...)
    if len(notification.CC) > 0 {
        message.SetHeader("Cc", notification.CC...)
    }
    if len(notification.BCC) > 0 {
        message.SetHeader("Bcc", notification.BCC...)
    }
    
    // Set subject
    message.SetHeader("Subject", notification.Subject)
    
    // Set content
    var htmlContent, textContent string
    var err error
    
    if notification.Template != "" {
        // Use template
        htmlContent, textContent, err = s.renderTemplate(notification.Template, notification.Data)
        if err != nil {
            return fmt.Errorf("failed to render template: %w", err)
        }
    } else {
        // Use provided content
        htmlContent = notification.HTMLContent
        textContent = notification.TextContent
    }
    
    if htmlContent != "" {
        message.SetBody("text/html", htmlContent)
    }
    if textContent != "" {
        if htmlContent != "" {
            message.AddAlternative("text/plain", textContent)
        } else {
            message.SetBody("text/plain", textContent)
        }
    }
    
    // Add attachments
    for _, attachment := range notification.Attachments {
        message.Attach(attachment.Filename, gomail.SetCopyFunc(func(w gomail.Writer) error {
            _, err := w.Write(attachment.Content)
            return err
        }))
    }
    
    // Set priority
    if notification.Priority > 0 {
        message.SetHeader("X-Priority", fmt.Sprintf("%d", notification.Priority))
    }
    
    // Send email
    if err := s.dialer.DialAndSend(message); err != nil {
        return fmt.Errorf("failed to send email: %w", err)
    }
    
    log.Printf("Email sent successfully to %v", notification.To)
    return nil
}

func (s *EmailService) renderTemplate(templateName string, data map[string]interface{}) (string, string, error) {
    tmpl, exists := s.templates[templateName]
    if !exists {
        return "", "", fmt.Errorf("template not found: %s", templateName)
    }
    
    var htmlBuf bytes.Buffer
    if err := tmpl.Execute(&htmlBuf, data); err != nil {
        return "", "", fmt.Errorf("failed to execute template: %w", err)
    }
    
    htmlContent := htmlBuf.String()
    
    // For now, we'll use the same content for text (in production, you'd have separate text templates)
    textContent := htmlContent
    
    return htmlContent, textContent, nil
}

func (s *EmailService) SendOrderConfirmation(ctx context.Context, orderEvent *model.OrderEvent) error {
    emailData := map[string]interface{}{
        "CustomerName":  orderEvent.CustomerName,
        "OrderNumber":   orderEvent.OrderNumber,
        "OrderID":       orderEvent.OrderID,
        "TotalAmount":   orderEvent.TotalAmount,
        "Items":         orderEvent.Items,
        "ShippingAddress": orderEvent.ShippingAddress,
        "OrderDate":     orderEvent.Timestamp.Format("January 2, 2006"),
    }
    
    notification := &model.EmailNotification{
        To:       []string{orderEvent.CustomerEmail},
        Subject:  fmt.Sprintf("Order Confirmation - %s", orderEvent.OrderNumber),
        Template: "order_confirmation",
        Data:     emailData,
        Priority: 1,
    }
    
    return s.SendEmail(ctx, notification)
}

func (s *EmailService) SendShippingNotification(ctx context.Context, orderEvent *model.OrderEvent) error {
    emailData := map[string]interface{}{
        "CustomerName":   orderEvent.CustomerName,
        "OrderNumber":    orderEvent.OrderNumber,
        "TrackingNumber": orderEvent.TrackingNumber,
        "ShippingAddress": orderEvent.ShippingAddress,
        "ShippedDate":    orderEvent.Timestamp.Format("January 2, 2006"),
    }
    
    notification := &model.EmailNotification{
        To:       []string{orderEvent.CustomerEmail},
        Subject:  fmt.Sprintf("Your Order %s Has Shipped!", orderEvent.OrderNumber),
        Template: "shipping_notification",
        Data:     emailData,
        Priority: 1,
    }
    
    return s.SendEmail(ctx, notification)
}

func (s *EmailService) SendDeliveryNotification(ctx context.Context, orderEvent *model.OrderEvent) error {
    emailData := map[string]interface{}{
        "CustomerName":  orderEvent.CustomerName,
        "OrderNumber":   orderEvent.OrderNumber,
        "DeliveredDate": orderEvent.Timestamp.Format("January 2, 2006"),
    }
    
    notification := &model.EmailNotification{
        To:       []string{orderEvent.CustomerEmail},
        Subject:  fmt.Sprintf("Your Order %s Has Been Delivered!", orderEvent.OrderNumber),
        Template: "delivery_notification",
        Data:     emailData,
        Priority: 1,
    }
    
    return s.SendEmail(ctx, notification)
}
```

### **5. Notification Service Dockerfile**
```dockerfile
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install git for go modules
RUN apk add --no-cache git

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o notification-service ./cmd/server

# Final stage
FROM alpine:latest

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates tzdata

WORKDIR /root/

# Copy binary from builder stage
COPY --from=builder /app/notification-service .

# Copy templates
COPY --from=builder /app/templates ./templates

# Create non-root user
RUN adduser -D -s /bin/sh appuser
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:9000/health || exit 1

EXPOSE 9000

CMD ["./notification-service"]
```

---

This completes Part 2 with detailed Order Service and Notification Service implementations. Would you like me to continue with Part 3 covering the complete CI/CD pipeline details, Jenkins configuration, and deployment strategies?