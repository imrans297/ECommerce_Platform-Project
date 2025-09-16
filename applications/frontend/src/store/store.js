import { configureStore } from '@reduxjs/toolkit';
import productSlice from './productSlice';
import orderSlice from './orderSlice';

export const store = configureStore({
  reducer: {
    products: productSlice,
    orders: orderSlice,
  },
});

export default store;