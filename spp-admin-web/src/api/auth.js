import api from './axios';

export const login = async (email, password) => {
  try {
    // Backend API uses /auth prefix
    const response = await api.post('/auth/login', { email, password });
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : new Error('Network Error');
  }
};

export const logout = async () => {
  try {
    await api.post('/auth/logout');
    localStorage.removeItem('token');
    localStorage.removeItem('user');
  } catch (error) {
    console.error('Logout failed', error);
  }
};

export const getUser = async () => {
  try {
    const response = await api.get('/auth/profile'); // Check api.php, usually profile is also under auth
    return response.data;
  } catch (error) {
    throw error;
  }
};
