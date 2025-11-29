import api from './axios';

// Get all payments
export const getPayments = async (params = {}) => {
  const response = await api.get('/payments', { params });
  return response.data;
};

// Get payment detail
export const getPaymentDetail = async (id) => {
  const response = await api.get(`/payments/${id}`);
  return response.data;
};

// Verify payment
export const verifyPayment = async (id, status) => {
  const response = await api.post(`/payments/${id}/verify`, { status });
  return response.data;
};

// Process manual payment (Cicilan)
export const processManualPayment = async (id, amount) => {
  const response = await api.post(`/payments/${id}/pay`, { amount });
  return response.data;
};
