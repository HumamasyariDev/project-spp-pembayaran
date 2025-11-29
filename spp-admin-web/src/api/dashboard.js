import api from './axios';

/**
 * Get admin dashboard statistics
 */
export const getAdminStats = async () => {
  const response = await api.get('/dashboard/admin-stats');
  return response.data;
};

/**
 * Get all payments with optional status filter
 * @param {string} status - 'pending' | 'verified' | 'rejected' (optional)
 */
export const getPayments = async (status = null) => {
  const params = status ? { status } : {};
  const response = await api.get('/payments', { params });
  return response.data;
};

/**
 * Get recent payments (latest 5)
 */
export const getRecentPayments = async () => {
  const response = await api.get('/payments', { 
    params: { limit: 5 } 
  });
  return response.data;
};

/**
 * Get total students count
 */
export const getStudentsCount = async () => {
  // This would need a new endpoint, for now we'll use a placeholder
  // You can add this endpoint to your Laravel API later
  try {
    const response = await api.get('/users/students-count');
    return response.data;
  } catch (error) {
    // Return mock data if endpoint doesn't exist yet
    return { data: { count: 0 } };
  }
};
