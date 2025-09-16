import { render, screen } from '@testing-library/react';
import { Provider } from 'react-redux';
import { BrowserRouter } from 'react-router-dom';
import App from './App';
import store from './store/store';

const renderWithProviders = (component) => {
  return render(
    <Provider store={store}>
      <BrowserRouter>
        {component}
      </BrowserRouter>
    </Provider>
  );
};

test('renders e-commerce platform header', () => {
  renderWithProviders(<App />);
  const headerElement = screen.getByText(/E-commerce Platform/i);
  expect(headerElement).toBeInTheDocument();
});

test('renders navigation links', () => {
  renderWithProviders(<App />);
  expect(screen.getByText('Home')).toBeInTheDocument();
  expect(screen.getByText('Products')).toBeInTheDocument();
  expect(screen.getByText('Orders')).toBeInTheDocument();
});