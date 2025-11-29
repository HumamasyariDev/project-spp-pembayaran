import api from './axios';

// Get all students
export const getStudents = async (params = {}) => {
  const response = await api.get('/students', { params });
  return response.data;
};

// Get student statistics
export const getStudentStats = async () => {
  const response = await api.get('/students/stats');
  return response.data;
};

// Get single student
export const getStudent = async (id) => {
  const response = await api.get(`/students/${id}`);
  return response.data;
};

// Create student
export const createStudent = async (data) => {
  const response = await api.post('/students', data);
  return response.data;
};

// Update student
export const updateStudent = async (id, data) => {
  const response = await api.put(`/students/${id}`, data);
  return response.data;
};

// Delete student
export const deleteStudent = async (id) => {
  const response = await api.delete(`/students/${id}`);
  return response.data;
};

// Get kelas options
export const getKelasOptions = async () => {
  const response = await api.get('/kelas');
  return response.data;
};

// Get jurusan options
export const getJurusanOptions = async () => {
  const response = await api.get('/jurusan');
  return response.data;
};
