const request = require('supertest');
const app = require('../index');

describe('User Service', () => {
  test('GET /health should return healthy status', async () => {
    const response = await request(app)
      .get('/health')
      .expect(200);
    
    expect(response.body.status).toBe('healthy');
    expect(response.body.service).toBe('user-service');
  });

  test('GET /users should return users array', async () => {
    const response = await request(app)
      .get('/users')
      .expect(200);
    
    expect(response.body.users).toBeDefined();
    expect(Array.isArray(response.body.users)).toBe(true);
  });
});