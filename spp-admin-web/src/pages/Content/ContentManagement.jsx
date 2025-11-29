import React, { useState, useEffect } from 'react';
import MainLayout from '../../components/Layout/MainLayout';
import './ContentManagement.css';
import {
  getAnnouncements, createAnnouncement, updateAnnouncement, deleteAnnouncement,
  getEvents, createEvent, updateEvent, deleteEvent,
  getExams, createExam, updateExam, deleteExam
} from '../../api/content';

const ContentManagement = () => {
  const [activeTab, setActiveTab] = useState('announcements');
  const [showModal, setShowModal] = useState(false);
  const [modalType, setModalType] = useState(''); // 'edit', 'delete', 'add'
  const [selectedItem, setSelectedItem] = useState(null);
  const [formData, setFormData] = useState({});
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  // Data from API
  const [announcements, setAnnouncements] = useState([]);
  const [events, setEvents] = useState([]);
  const [exams, setExams] = useState([]);

  const tabs = [
    { id: 'announcements', label: 'Pengumuman' },
    { id: 'events', label: 'Kegiatan' },
    { id: 'exams', label: 'Jadwal Ujian' },
  ];

  const getTabIcon = (tabId) => {
    switch(tabId) {
      case 'announcements':
        return (
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M22 17H2a3 3 0 0 0 3-3V9a7 7 0 0 1 14 0v5a3 3 0 0 0 3 3zm-8.27 4a2 2 0 0 1-3.46 0"></path>
          </svg>
        );
      case 'events':
        return (
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
            <line x1="16" y1="2" x2="16" y2="6"></line>
            <line x1="8" y1="2" x2="8" y2="6"></line>
            <line x1="3" y1="10" x2="21" y2="10"></line>
          </svg>
        );
      case 'exams':
        return (
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
            <polyline points="14 2 14 8 20 8"></polyline>
            <line x1="16" y1="13" x2="8" y2="13"></line>
            <line x1="16" y1="17" x2="8" y2="17"></line>
          </svg>
        );
      default:
        return null;
    }
  };

  // Fetch data from API
  const fetchData = async () => {
    setLoading(true);
    setError(null);
    try {
      const [announcementsRes, eventsRes, examsRes] = await Promise.all([
        getAnnouncements(),
        getEvents(),
        getExams()
      ]);

      // Map API response to local state format
      if (announcementsRes.status && announcementsRes.data) {
        setAnnouncements(announcementsRes.data.map(item => ({
          id: item.id,
          title: item.title,
          content: item.content,
          date: item.publish_date,
          category: item.category,
          status: new Date(item.publish_date) <= new Date() ? 'published' : 'draft',
          is_important: item.is_important
        })));
      }

      if (eventsRes.status && eventsRes.data) {
        // Filter out 'ujian' category since that's for exams
        setEvents(eventsRes.data.filter(item => item.category !== 'ujian').map(item => ({
          id: item.id,
          title: item.title,
          description: item.description,
          date: item.event_date,
          time: item.event_time,
          location: item.location,
          category: item.category,
          status: new Date(item.event_date) >= new Date() ? 'upcoming' : 'completed'
        })));
      }

      if (examsRes.status && examsRes.data) {
        setExams(examsRes.data.map(item => ({
          id: item.id,
          title: item.title,
          description: item.description,
          startDate: item.event_date,
          endDate: item.event_date, // For exams we use same date or extend if needed
          location: item.location,
          status: new Date(item.event_date) >= new Date() ? 'scheduled' : 'completed'
        })));
      }
    } catch (err) {
      console.error('Failed to fetch data:', err);
      setError('Gagal memuat data. Pastikan server API berjalan.');
    } finally {
      setLoading(false);
    }
  };

  // Load data on mount
  useEffect(() => {
    fetchData();
  }, []);

  // Data Helpers
  const getCurrentData = () => {
    switch (activeTab) {
      case 'announcements': return announcements;
      case 'events': return events;
      case 'exams': return exams;
      default: return [];
    }
  };

  // Handlers
  const handleEdit = (item) => {
    setSelectedItem(item);
    setFormData({ ...item });
    setModalType('edit');
    setError(null);
    setShowModal(true);
  };

  const handleDelete = (item) => {
    setSelectedItem(item);
    setModalType('delete');
    setError(null);
    setShowModal(true);
  };

  const handleAddNew = () => {
    const emptyItem = getEmptyItem();
    setSelectedItem(null);
    setFormData(emptyItem);
    setModalType('add');
    setError(null);
    setShowModal(true);
  };

  const getEmptyItem = () => {
    const today = new Date().toISOString().split('T')[0];
    switch (activeTab) {
      case 'announcements':
        return { title: '', content: '', date: today, category: 'pengumuman_umum', is_important: false };
      case 'events':
        return { title: '', description: '', date: today, time: '08:00', location: '', category: 'lainnya' };
      case 'exams':
        return { title: '', description: '', startDate: today, location: 'Sekolah' };
      default:
        return {};
    }
  };

  const handleInputChange = (field, value) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handleSubmit = async () => {
    // Validasi sederhana
    if (!formData.title || formData.title.trim() === '') {
      setError('Judul tidak boleh kosong');
      return;
    }
    
    setSubmitting(true);
    setError(null);
    try {
      if (activeTab === 'announcements') {
        const apiData = {
          title: formData.title,
          content: formData.content || formData.title,
          category: formData.category || 'pengumuman_umum',
          publish_date: formData.date,
          is_important: formData.is_important || false
        };
        
        if (modalType === 'add') {
          await createAnnouncement(apiData);
        } else {
          await updateAnnouncement(selectedItem.id, apiData);
        }
      } else if (activeTab === 'events') {
        const apiData = {
          title: formData.title,
          description: formData.description || '',
          event_date: formData.date,
          event_time: formData.time || null,
          location: formData.location,
          category: formData.category || 'lainnya',
          is_featured: false
        };
        
        if (modalType === 'add') {
          await createEvent(apiData);
        } else {
          await updateEvent(selectedItem.id, apiData);
        }
      } else if (activeTab === 'exams') {
        const apiData = {
          title: formData.title,
          description: formData.description || '',
          event_date: formData.startDate,
          location: formData.location || 'Sekolah',
          category: 'ujian'
        };
        
        if (modalType === 'add') {
          await createExam(apiData);
        } else {
          await updateExam(selectedItem.id, apiData);
        }
      }
      
      // Refresh data after success
      await fetchData();
      setSuccess(modalType === 'add' ? 'Data berhasil ditambahkan!' : 'Data berhasil diperbarui!');
      setTimeout(() => setSuccess(null), 3000);
      closeModal();
    } catch (err) {
      console.error('Failed to save:', err);
      setError(err.message || 'Gagal menyimpan data. Silakan coba lagi.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeleteConfirm = async () => {
    setSubmitting(true);
    setError(null);
    try {
      if (activeTab === 'announcements') {
        await deleteAnnouncement(selectedItem.id);
      } else if (activeTab === 'events') {
        await deleteEvent(selectedItem.id);
      } else if (activeTab === 'exams') {
        await deleteExam(selectedItem.id);
      }
      
      // Refresh data after success
      await fetchData();
      setSuccess('Data berhasil dihapus!');
      setTimeout(() => setSuccess(null), 3000);
      closeModal();
    } catch (err) {
      console.error('Failed to delete:', err);
      setError(err.message || 'Gagal menghapus data. Silakan coba lagi.');
    } finally {
      setSubmitting(false);
    }
  };

  const closeModal = () => {
    setShowModal(false);
    setModalType('');
    setSelectedItem(null);
    setFormData({});
  };

  const getStatusBadge = (status) => {
    const statusConfig = {
      published: { label: 'Dipublikasi', class: 'status-success' },
      draft: { label: 'Draft', class: 'status-warning' },
      upcoming: { label: 'Akan Datang', class: 'status-info' },
      completed: { label: 'Selesai', class: 'status-default' },
      scheduled: { label: 'Terjadwal', class: 'status-info' },
    };
    const config = statusConfig[status] || { label: status, class: 'status-default' };
    return <span className={`status-badge ${config.class}`}>{config.label}</span>;
  };

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('id-ID', {
      day: 'numeric',
      month: 'short',
      year: 'numeric'
    });
  };

  const renderFormFields = () => {
    switch (activeTab) {
      case 'announcements':
        return (
          <>
            <div className="form-group">
              <label className="form-label">Judul Pengumuman</label>
              <input
                type="text"
                className="form-input"
                value={formData.title || ''}
                onChange={(e) => handleInputChange('title', e.target.value)}
                placeholder="Masukkan judul pengumuman"
              />
            </div>
            <div className="form-group">
              <label className="form-label">Isi Pengumuman</label>
              <textarea
                className="form-input"
                rows="4"
                value={formData.content || ''}
                onChange={(e) => handleInputChange('content', e.target.value)}
                placeholder="Masukkan isi pengumuman"
              />
            </div>
            <div className="form-group">
              <label className="form-label">Kategori</label>
              <select
                className="form-input"
                value={formData.category || 'pengumuman_umum'}
                onChange={(e) => handleInputChange('category', e.target.value)}
              >
                <option value="pengumuman_umum">Pengumuman Umum</option>
                <option value="libur">Libur</option>
                <option value="ekstrakurikuler">Ekstrakurikuler</option>
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Tanggal Publikasi</label>
              <input
                type="date"
                className="form-input"
                value={formData.date || ''}
                onChange={(e) => handleInputChange('date', e.target.value)}
              />
            </div>
            <div className="form-group" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <input
                type="checkbox"
                id="is_important"
                checked={formData.is_important || false}
                onChange={(e) => handleInputChange('is_important', e.target.checked)}
              />
              <label htmlFor="is_important">Tandai sebagai Penting</label>
            </div>
          </>
        );
      case 'events':
        return (
          <>
            <div className="form-group">
              <label className="form-label">Nama Kegiatan</label>
              <input
                type="text"
                className="form-input"
                value={formData.title || ''}
                onChange={(e) => handleInputChange('title', e.target.value)}
                placeholder="Masukkan nama kegiatan"
              />
            </div>
            <div className="form-group">
              <label className="form-label">Deskripsi</label>
              <textarea
                className="form-input"
                rows="3"
                value={formData.description || ''}
                onChange={(e) => handleInputChange('description', e.target.value)}
                placeholder="Masukkan deskripsi kegiatan"
              />
            </div>
            <div className="form-group">
              <label className="form-label">Kategori</label>
              <select
                className="form-input"
                value={formData.category || 'lainnya'}
                onChange={(e) => handleInputChange('category', e.target.value)}
              >
                <option value="olahraga">Olahraga</option>
                <option value="ekskul">Ekstrakurikuler</option>
                <option value="lainnya">Lainnya</option>
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Tanggal</label>
              <input
                type="date"
                className="form-input"
                value={formData.date || ''}
                onChange={(e) => handleInputChange('date', e.target.value)}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Waktu</label>
              <input
                type="time"
                className="form-input"
                value={formData.time || ''}
                onChange={(e) => handleInputChange('time', e.target.value)}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Lokasi</label>
              <input
                type="text"
                className="form-input"
                value={formData.location || ''}
                onChange={(e) => handleInputChange('location', e.target.value)}
                placeholder="Masukkan lokasi kegiatan"
              />
            </div>
          </>
        );
      case 'exams':
        return (
          <>
            <div className="form-group">
              <label className="form-label">Nama Ujian</label>
              <input
                type="text"
                className="form-input"
                value={formData.title || ''}
                onChange={(e) => handleInputChange('title', e.target.value)}
                placeholder="Masukkan nama ujian"
              />
            </div>
            <div className="form-group">
              <label className="form-label">Deskripsi</label>
              <textarea
                className="form-input"
                rows="3"
                value={formData.description || ''}
                onChange={(e) => handleInputChange('description', e.target.value)}
                placeholder="Masukkan deskripsi ujian"
              />
            </div>
            <div className="form-group">
              <label className="form-label">Tanggal Ujian</label>
              <input
                type="date"
                className="form-input"
                value={formData.startDate || ''}
                onChange={(e) => handleInputChange('startDate', e.target.value)}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Lokasi</label>
              <input
                type="text"
                className="form-input"
                value={formData.location || ''}
                onChange={(e) => handleInputChange('location', e.target.value)}
                placeholder="Masukkan lokasi ujian"
              />
            </div>
          </>
        );
      default:
        return null;
    }
  };

  return (
    <MainLayout>
      <div className="content-management-page">
        {/* Page Header */}
        <div className="content-header">
          <div className="header-info">
            <h1 className="page-title">Kelola Konten</h1>
            <p className="page-subtitle">Kelola pengumuman, kegiatan, dan jadwal ujian sekolah</p>
          </div>
          <button className="btn-add" onClick={handleAddNew}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
              <line x1="12" y1="5" x2="12" y2="19"></line>
              <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
            <span>Tambah {tabs.find(t => t.id === activeTab)?.label}</span>
          </button>
        </div>

        {/* Tabs */}
        <div className="tabs-container">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              className={`tab-btn ${activeTab === tab.id ? 'active' : ''}`}
              onClick={() => setActiveTab(tab.id)}
            >
              <span className="tab-icon">{getTabIcon(tab.id)}</span>
              <span className="tab-label">{tab.label}</span>
            </button>
          ))}
        </div>

        {/* Success Message */}
        {success && (
          <div className="success-message">
            <span>✅ {success}</span>
            <button onClick={() => setSuccess(null)}>✕</button>
          </div>
        )}

        {/* Error Message */}
        {error && !showModal && (
          <div className="error-message">
            <span>⚠️ {error}</span>
            <button onClick={() => setError(null)}>✕</button>
          </div>
        )}

        {/* Content Area */}
        <div className="content-area">
          {loading ? (
            <div className="loading-state">
              <div className="spinner"></div>
              <p>Memuat data...</p>
            </div>
          ) : (
          <div className="content-list">
            {getCurrentData().length === 0 ? (
              <div className="empty-state">
                <div className="empty-icon">{getTabIcon(activeTab)}</div>
                <p>Belum ada data {tabs.find(t => t.id === activeTab)?.label.toLowerCase()}</p>
                <button className="btn-add-small" onClick={handleAddNew}>Tambah Baru</button>
              </div>
            ) : (
              getCurrentData().map((item) => (
                <div key={item.id} className="content-card">
                  <div className={`card-icon ${activeTab === 'announcements' ? 'announcement-icon' : activeTab === 'events' ? 'event-icon' : 'exam-icon'}`}>
                    {getTabIcon(activeTab)}
                  </div>
                  
                  <div className="card-info">
                    <h3 className="card-title">{item.title}</h3>
                    <div className="card-meta">
                      <span className="meta-date">
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                          <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                          <line x1="16" y1="2" x2="16" y2="6"></line>
                          <line x1="8" y1="2" x2="8" y2="6"></line>
                          <line x1="3" y1="10" x2="21" y2="10"></line>
                        </svg>
                        {item.startDate ? `${formatDate(item.startDate)} - ${formatDate(item.endDate)}` : formatDate(item.date)}
                      </span>
                      {item.location && (
                        <span className="meta-location">
                          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
                            <circle cx="12" cy="10" r="3"></circle>
                          </svg>
                          {item.location}
                        </span>
                      )}
                    </div>
                  </div>
                  
                  <div className="card-status">{getStatusBadge(item.status)}</div>

                  <div className="card-actions">
                    <button className="btn-action btn-edit" title="Edit" onClick={() => handleEdit(item)}>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                      </svg>
                      Edit
                    </button>
                    <button className="btn-action btn-delete" title="Hapus" onClick={() => handleDelete(item)}>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <polyline points="3 6 5 6 21 6"></polyline>
                        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                      </svg>
                      Hapus
                    </button>
                  </div>
                </div>
              ))
            )}
          </div>
          )}
        </div>

        {/* Modal for Edit/Delete/Add */}
        {showModal && (
          <div className="modal-overlay" onClick={closeModal}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h2 className="modal-title">
                  {modalType === 'add' && `Tambah ${tabs.find(t => t.id === activeTab)?.label}`}
                  {modalType === 'edit' && `Edit ${tabs.find(t => t.id === activeTab)?.label}`}
                  {modalType === 'delete' && `Hapus ${tabs.find(t => t.id === activeTab)?.label}`}
                </h2>
                <button className="modal-close" onClick={closeModal}>
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                  </svg>
                </button>
              </div>

              {modalType === 'delete' ? (
                <div>
                  <p>Apakah Anda yakin ingin menghapus <strong>"{selectedItem?.title}"</strong>?</p>
                  <p style={{ color: '#64748b', fontSize: '0.9rem', marginTop: '0.5rem' }}>
                    Tindakan ini tidak dapat dibatalkan.
                  </p>
                </div>
              ) : (
                <div>
                  {renderFormFields()}
                </div>
              )}

              {/* Error in modal */}
              {error && showModal && (
                <div className="modal-error">
                  ⚠️ {error}
                </div>
              )}

              <div className="modal-actions">
                <button className="btn-secondary" onClick={closeModal} disabled={submitting}>
                  Batal
                </button>
                {modalType === 'delete' ? (
                  <button className="btn-danger" onClick={handleDeleteConfirm} disabled={submitting}>
                    {submitting ? 'Menghapus...' : 'Hapus'}
                  </button>
                ) : (
                  <button className="btn-add" onClick={handleSubmit} disabled={submitting}>
                    {submitting ? 'Menyimpan...' : (modalType === 'add' ? 'Tambah' : 'Simpan')}
                  </button>
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    </MainLayout>
  );
};

export default ContentManagement;
