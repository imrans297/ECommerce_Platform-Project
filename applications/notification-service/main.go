package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"
)

type HealthResponse struct {
	Status    string    `json:"status"`
	Service   string    `json:"service"`
	Timestamp time.Time `json:"timestamp"`
}

type HomeResponse struct {
	Message string `json:"message"`
	Version string `json:"version"`
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	response := HealthResponse{
		Status:    "healthy",
		Service:   "notification-service",
		Timestamp: time.Now(),
	}
	json.NewEncoder(w).Encode(response)
}

func homeHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	response := HomeResponse{
		Message: "Notification Service API",
		Version: "1.0.0",
	}
	json.NewEncoder(w).Encode(response)
}

func notificationsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	response := map[string]interface{}{
		"notifications": []interface{}{},
		"message":       "Notifications endpoint working",
	}
	json.NewEncoder(w).Encode(response)
}

func main() {
	http.HandleFunc("/", homeHandler)
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/notifications", notificationsHandler)
	
	port := "9000"
	fmt.Printf("Notification service running on port %s\n", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}