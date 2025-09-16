import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '2m', target: 10 }, // Ramp up
    { duration: '5m', target: 10 }, // Stay at 10 users
    { duration: '2m', target: 0 },  // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests must complete below 500ms
    http_req_failed: ['rate<0.1'],    // Error rate must be below 10%
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost';

export default function () {
  // Test user service
  let userResponse = http.get(`${BASE_URL}/user-service/health`);
  check(userResponse, {
    'user service status is 200': (r) => r.status === 200,
    'user service response time < 200ms': (r) => r.timings.duration < 200,
  });

  // Test product service
  let productResponse = http.get(`${BASE_URL}/product-service/health`);
  check(productResponse, {
    'product service status is 200': (r) => r.status === 200,
    'product service response time < 200ms': (r) => r.timings.duration < 200,
  });

  // Test order service
  let orderResponse = http.get(`${BASE_URL}/order-service/health`);
  check(orderResponse, {
    'order service status is 200': (r) => r.status === 200,
    'order service response time < 200ms': (r) => r.timings.duration < 200,
  });

  // Test notification service
  let notificationResponse = http.get(`${BASE_URL}/notification-service/health`);
  check(notificationResponse, {
    'notification service status is 200': (r) => r.status === 200,
    'notification service response time < 200ms': (r) => r.timings.duration < 200,
  });

  sleep(1);
}