import api from './axios';

// Get active queues (for petugas)
export const getActiveQueues = async () => {
  const response = await api.get('/queues/active');
  return response.data;
};

// Scan QR Code (for petugas)
export const scanQueueQr = async (qrCode) => {
  const response = await api.post('/queues/scan', { qr_code: qrCode });
  return response.data;
};

// Call next queue
export const callNextQueue = async () => {
  const response = await api.post('/queues/call-next');
  return response.data;
};

// Serve queue
export const serveQueue = async (id) => {
  const response = await api.post(`/queues/${id}/serve`);
  return response.data;
};

// Complete queue
export const completeQueue = async (id) => {
  const response = await api.post(`/queues/${id}/complete`);
  return response.data;
};

// Get available services
export const getServices = async () => {
  const response = await api.get('/queues/services');
  return response.data;
};
