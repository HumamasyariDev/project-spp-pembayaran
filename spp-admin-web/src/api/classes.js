import api from './axios';

// ==================== KELAS API ====================

export const getKelas = async () => {
  const response = await api.get('/kelas');
  return response.data;
};

export const createKelas = async (data) => {
  const response = await api.post('/kelas', data);
  return response.data;
};

export const updateKelas = async (id, data) => {
  const response = await api.put(`/kelas/${id}`, data);
  return response.data;
};

export const deleteKelas = async (id) => {
  const response = await api.delete(`/kelas/${id}`);
  return response.data;
};

// ==================== JURUSAN API ====================

export const getJurusan = async () => {
  const response = await api.get('/jurusan');
  return response.data;
};

export const createJurusan = async (data) => {
  const response = await api.post('/jurusan', data);
  return response.data;
};

export const updateJurusan = async (id, data) => {
  const response = await api.put(`/jurusan/${id}`, data);
  return response.data;
};

export const deleteJurusan = async (id) => {
  const response = await api.delete(`/jurusan/${id}`);
  return response.data;
};
