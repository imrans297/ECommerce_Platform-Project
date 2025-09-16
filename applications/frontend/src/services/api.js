import axios from 'axios';

const API_BASE_URL = '';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 5000,
});

export const checkServiceHealth = async (serviceName) => {
  const response = await api.get(`/${serviceName}/health`);
  return response.data;
};

export const getProducts = async () => {
  const response = await api.get('/product-service/products');
  return response.data;
};

export const getOrders = async () => {
  const response = await api.get('/order-service/orders');
  return response.data;
};

export const getUsers = async () => {
  const response = await api.get('/user-service/users');
  return response.data;
};

export default api;