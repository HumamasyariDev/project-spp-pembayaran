import api from './axios';

// ==================== ANNOUNCEMENTS ====================
export const getAnnouncements = async () => {
  try {
    const response = await api.get('/announcements');
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : new Error('Network Error');
  }
};

export const createAnnouncement = async (data) => {
  try {
    const response = await api.post('/announcements', data);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : new Error('Network Error');
  }
};

export const updateAnnouncement = async (id, data) => {
  try {
    const response = await api.put(`/announcements/${id}`, data);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : new Error('Network Error');
  }
};

export const deleteAnnouncement = async (id) => {
  try {
    const response = await api.delete(`/announcements/${id}`);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : new Error('Network Error');
  }
};

// ==================== EVENTS ====================
export const getEvents = async () => {
  try {
    const response = await api.get('/events');
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : new Error('Network Error');
  }
};

export const createEvent = async (data) => {
  try {
    const response = await api.post('/events', data);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : new Error('Network Error');
  }
};

export const updateEvent = async (id, data) => {
  try {
    const response = await api.put(`/events/${id}`, data);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : new Error('Network Error');
  }
};

export const deleteEvent = async (id) => {
  try {
    const response = await api.delete(`/events/${id}`);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : new Error('Network Error');
  }
};

// ==================== EXAMS (using Events with category 'ujian') ====================
export const getExams = async () => {
  try {
    const response = await api.get('/events?category=ujian');
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : new Error('Network Error');
  }
};

export const createExam = async (data) => {
  try {
    // Set category to ujian for exams
    const examData = { ...data, category: 'ujian' };
    const response = await api.post('/events', examData);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : new Error('Network Error');
  }
};

export const updateExam = async (id, data) => {
  try {
    const response = await api.put(`/events/${id}`, data);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : new Error('Network Error');
  }
};

export const deleteExam = async (id) => {
  try {
    const response = await api.delete(`/events/${id}`);
    return response.data;
  } catch (error) {
    throw error.response ? error.response.data : new Error('Network Error');
  }
};
