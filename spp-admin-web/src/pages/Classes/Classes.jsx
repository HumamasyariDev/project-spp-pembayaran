import React, { useState, useEffect } from 'react';
import MainLayout from '../../components/Layout/MainLayout';
import { 
  getKelas, createKelas, updateKelas, deleteKelas,
  getJurusan, createJurusan, updateJurusan, deleteJurusan
} from '../../api/classes';
import './Classes.css';

const Classes = () => {
  const [activeTab, setActiveTab] = useState('kelas'); // 'kelas' or 'jurusan'
  const [dataList, setDataList] = useState([]);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  // Modal
  const [showModal, setShowModal] = useState(false);
  const [modalType, setModalType] = useState(''); // 'add' or 'edit'
  const [selectedItem, setSelectedItem] = useState(null);
  const [formData, setFormData] = useState({});

  // Fetch data based on active tab
  const fetchData = async () => {
    setLoading(true);
    setError(null);
    try {
      let response;
      if (activeTab === 'kelas') {
        response = await getKelas();
      } else {
        response = await getJurusan();
      }
      
      if (response.status) {
        setDataList(response.data || []);
      }
    } catch (err) {
      console.error('Error fetching data:', err);
      setError(`Gagal memuat data ${activeTab}`);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [activeTab]);

  // Handlers
  const handleTabChange = (tab) => {
    setActiveTab(tab);
    setSuccess(null);
    setError(null);
  };

  const handleAdd = () => {
    setSelectedItem(null);
    setFormData(activeTab === 'kelas' ? { nama: '', keterangan: '' } : { kode: '', nama: '', deskripsi: '' });
    setModalType('add');
    setShowModal(true);
  };

  const handleEdit = (item) => {
    setSelectedItem(item);
    setFormData(item);
    setModalType('edit');
    setShowModal(true);
  };

  const handleDelete = async (item) => {
    if (!window.confirm(`Yakin ingin menghapus ${activeTab} "${item.nama}"?`)) return;

    setSubmitting(true);
    try {
      if (activeTab === 'kelas') {
        await deleteKelas(item.id);
      } else {
        await deleteJurusan(item.id);
      }
      setSuccess('Berhasil dihapus!');
      fetchData();
    } catch (err) {
      console.error(err);
      setError('Gagal menghapus data. Mungkin data sedang digunakan.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleSubmit = async () => {
    setSubmitting(true);
    setError(null);
    try {
      if (modalType === 'add') {
        if (activeTab === 'kelas') await createKelas(formData);
        else await createJurusan(formData);
        setSuccess('Berhasil ditambahkan!');
      } else {
        if (activeTab === 'kelas') await updateKelas(selectedItem.id, formData);
        else await updateJurusan(selectedItem.id, formData);
        setSuccess('Berhasil diperbarui!');
      }
      setShowModal(false);
      fetchData();
    } catch (err) {
      console.error(err);
      setError(err.response?.data?.message || 'Gagal menyimpan data');
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

  return (
    <MainLayout>
      <div className="classes-page">
        {/* Header */}
        <div className="page-header">
          <div className="header-info">
            <h1 className="page-title">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M3 21h18M5 21V7l8-4 8 4v14M8 21v-9a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v9" />
              </svg>
              Data Kelas & Jurusan
            </h1>
            <p className="page-subtitle">Kelola daftar kelas dan jurusan sekolah</p>
          </div>
          <button className="btn-add" onClick={handleAdd}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <line x1="12" y1="5" x2="12" y2="19"></line>
              <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
            Tambah {activeTab === 'kelas' ? 'Kelas' : 'Jurusan'}
          </button>
        </div>

        {/* Tabs */}
        <div className="tabs-container">
          <button 
            className={`tab-btn ${activeTab === 'kelas' ? 'active' : ''}`}
            onClick={() => handleTabChange('kelas')}
          >
            Daftar Kelas
          </button>
          <button 
            className={`tab-btn ${activeTab === 'jurusan' ? 'active' : ''}`}
            onClick={() => handleTabChange('jurusan')}
          >
            Daftar Jurusan
          </button>
        </div>

        {/* Messages */}
        {success && (
          <div className="success-message">
            <span>✅ {success}</span>
            <button onClick={() => setSuccess(null)}>✕</button>
          </div>
        )}
        {error && (
          <div className="error-message">
            <span>⚠️ {error}</span>
            <button onClick={() => setError(null)}>✕</button>
          </div>
        )}

        {/* Content */}
        {loading ? (
          <div className="loading-state">
            <div className="spinner"></div>
            <p>Memuat data...</p>
          </div>
        ) : dataList.length === 0 ? (
          <div className="empty-state">
            <p>Belum ada data {activeTab}.</p>
          </div>
        ) : (
          <div className="content-grid">
            {dataList.map((item) => (
              <div className="class-card" key={item.id}>
                <div className="card-header">
                  <div>
                    <h3 className="card-title">{activeTab === 'kelas' ? item.nama : item.kode}</h3>
                    <p className="card-subtitle">{activeTab === 'kelas' ? item.keterangan : item.nama}</p>
                  </div>
                  <div className="card-actions">
                    <button className="btn-action edit" onClick={() => handleEdit(item)}>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                        <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                      </svg>
                    </button>
                    <button className="btn-action delete" onClick={() => handleDelete(item)}>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <polyline points="3 6 5 6 21 6"></polyline>
                        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                      </svg>
                    </button>
                  </div>
                </div>
                {activeTab === 'jurusan' && item.deskripsi && (
                  <p className="card-desc">{item.deskripsi}</p>
                )}
              </div>
            ))}
          </div>
        )}

        {/* Modal */}
        {showModal && (
          <div className="modal-overlay" onClick={closeModal}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h2 className="modal-title">
                  {modalType === 'add' ? 'Tambah' : 'Edit'} {activeTab === 'kelas' ? 'Kelas' : 'Jurusan'}
                </h2>
                <button className="modal-close" onClick={closeModal}>✕</button>
              </div>
              <div className="form-content">
                {activeTab === 'kelas' ? (
                  <>
                    <div className="form-group">
                      <label>Nama Kelas *</label>
                      <input 
                        type="text" 
                        placeholder="Contoh: X, XI, XII"
                        value={formData.nama || ''}
                        onChange={(e) => setFormData({...formData, nama: e.target.value})}
                      />
                    </div>
                    <div className="form-group">
                      <label>Keterangan</label>
                      <input 
                        type="text" 
                        placeholder="Contoh: Kelas Sepuluh"
                        value={formData.keterangan || ''}
                        onChange={(e) => setFormData({...formData, keterangan: e.target.value})}
                      />
                    </div>
                  </>
                ) : (
                  <>
                    <div className="form-group">
                      <label>Kode Jurusan *</label>
                      <input 
                        type="text" 
                        placeholder="Contoh: RPL, TKJ"
                        value={formData.kode || ''}
                        onChange={(e) => setFormData({...formData, kode: e.target.value})}
                      />
                    </div>
                    <div className="form-group">
                      <label>Nama Jurusan *</label>
                      <input 
                        type="text" 
                        placeholder="Contoh: Rekayasa Perangkat Lunak"
                        value={formData.nama || ''}
                        onChange={(e) => setFormData({...formData, nama: e.target.value})}
                      />
                    </div>
                    <div className="form-group">
                      <label>Deskripsi</label>
                      <textarea 
                        placeholder="Deskripsi singkat jurusan"
                        value={formData.deskripsi || ''}
                        onChange={(e) => setFormData({...formData, deskripsi: e.target.value})}
                        rows="3"
                      />
                    </div>
                  </>
                )}
              </div>
              <div className="modal-actions">
                <button className="btn-secondary" onClick={closeModal}>Batal</button>
                <button className="btn-primary" onClick={handleSubmit} disabled={submitting}>
                  {submitting ? 'Menyimpan...' : 'Simpan'}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </MainLayout>
  );
};

export default Classes;
