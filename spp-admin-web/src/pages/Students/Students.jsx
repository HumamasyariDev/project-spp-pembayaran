import React, { useState, useEffect } from 'react';
import MainLayout from '../../components/Layout/MainLayout';
import { 
  getStudents, createStudent, updateStudent, deleteStudent, getStudentStats,
  getKelasOptions, getJurusanOptions 
} from '../../api/students';
import './Students.css';

const Students = () => {
  const [students, setStudents] = useState([]);
  const [stats, setStats] = useState({ total: 0, aktif: 0, lulus: 0 });
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  
  // Options states
  const [kelasOptions, setKelasOptions] = useState([]);
  const [jurusanOptions, setJurusanOptions] = useState([]);
  
  // Modal states
  const [showModal, setShowModal] = useState(false);
  const [modalType, setModalType] = useState(''); // 'add', 'edit', 'delete', 'view'
  const [selectedStudent, setSelectedStudent] = useState(null);
  const [formData, setFormData] = useState({});
  
  // Filter states
  const [searchTerm, setSearchTerm] = useState('');
  const [filterKelas, setFilterKelas] = useState('');
  const [filterJurusan, setFilterJurusan] = useState('');

  // Fetch data
  const fetchData = async () => {
    setLoading(true);
    setError(null);
    try {
      const params = {};
      if (searchTerm) params.search = searchTerm;
      if (filterKelas) params.kelas = filterKelas;
      if (filterJurusan) params.jurusan = filterJurusan;

      const [studentsRes, statsRes, kelasRes, jurusanRes] = await Promise.all([
        getStudents(params),
        getStudentStats(),
        getKelasOptions(),
        getJurusanOptions()
      ]);

      if (studentsRes.status) {
        setStudents(studentsRes.data || []);
      }
      if (statsRes.status) {
        setStats(statsRes.data || { total: 0, aktif: 0, lulus: 0 });
      }
      if (kelasRes.status) {
        setKelasOptions(kelasRes.data.map(k => k.nama) || []);
      }
      if (jurusanRes.status) {
        setJurusanOptions(jurusanRes.data.map(j => j.kode) || []);
      }
    } catch (err) {
      console.error('Error fetching data:', err);
      setError('Gagal memuat data siswa');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [searchTerm, filterKelas, filterJurusan]);

  // Handlers
  const handleAdd = () => {
    setSelectedStudent(null);
    setFormData({
      name: '',
      email: '',
      password: '',
      nis: '',
      nisn: '',
      kelas: kelasOptions.length > 0 ? kelasOptions[0] : '',
      jurusan: jurusanOptions.length > 0 ? jurusanOptions[0] : '',
      jenis_kelamin: 'L',
      telepon: '',
      alamat: ''
    });
    setModalType('add');
    setError(null);
    setShowModal(true);
  };

  const handleEdit = (student) => {
    setSelectedStudent(student);
    setFormData({
      name: student.name || '',
      email: student.email || '',
      password: '',
      nis: student.nis || '',
      nisn: student.nisn || '',
      kelas: student.kelas || (kelasOptions.length > 0 ? kelasOptions[0] : ''),
      jurusan: student.jurusan || (jurusanOptions.length > 0 ? jurusanOptions[0] : ''),
      jenis_kelamin: student.jenis_kelamin || 'L',
      telepon: student.telepon || '',
      alamat: student.alamat || '',
      status_kelulusan: student.status_kelulusan || 'aktif'
    });
    setModalType('edit');
    setError(null);
    setShowModal(true);
  };

  const handleView = (student) => {
    setSelectedStudent(student);
    setModalType('view');
    setShowModal(true);
  };

  const handleDelete = (student) => {
    setSelectedStudent(student);
    setModalType('delete');
    setError(null);
    setShowModal(true);
  };

  const handleInputChange = (field, value) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handleSubmit = async () => {
    if (!formData.name || !formData.email || !formData.nis || !formData.nisn) {
      setError('Nama, Email, NIS, dan NISN wajib diisi');
      return;
    }
    if (modalType === 'add' && !formData.password) {
      setError('Password wajib diisi untuk siswa baru');
      return;
    }

    setSubmitting(true);
    setError(null);
    try {
      if (modalType === 'add') {
        await createStudent(formData);
        setSuccess('Siswa berhasil ditambahkan!');
      } else {
        await updateStudent(selectedStudent.id, formData);
        setSuccess('Data siswa berhasil diperbarui!');
      }
      await fetchData();
      setTimeout(() => setSuccess(null), 3000);
      closeModal();
    } catch (err) {
      console.error('Error:', err);
      setError(err.response?.data?.message || 'Gagal menyimpan data siswa');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeleteConfirm = async () => {
    setSubmitting(true);
    setError(null);
    try {
      await deleteStudent(selectedStudent.id);
      setSuccess('Siswa berhasil dihapus!');
      await fetchData();
      setTimeout(() => setSuccess(null), 3000);
      closeModal();
    } catch (err) {
      console.error('Error:', err);
      setError(err.response?.data?.message || 'Gagal menghapus siswa');
    } finally {
      setSubmitting(false);
    }
  };

  const closeModal = () => {
    setShowModal(false);
    setModalType('');
    setSelectedStudent(null);
    setFormData({});
  };

  return (
    <MainLayout>
      <div className="students-page">
        {/* Header */}
        <div className="page-header">
          <div className="header-info">
            <h1 className="page-title">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                <circle cx="9" cy="7" r="4"></circle>
                <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
              </svg>
              Data Siswa
            </h1>
            <p className="page-subtitle">Kelola data siswa sekolah</p>
          </div>
          <button className="btn-add" onClick={handleAdd}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
              <line x1="12" y1="5" x2="12" y2="19"></line>
              <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
            Tambah Siswa
          </button>
        </div>

        {/* Stats Cards */}
        <div className="stats-grid">
          <div className="stat-card">
            <div className="stat-icon blue">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                <circle cx="9" cy="7" r="4"></circle>
                <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
              </svg>
            </div>
            <div className="stat-info">
              <span className="stat-value">{stats.total}</span>
              <span className="stat-label">Total Siswa</span>
            </div>
          </div>
          <div className="stat-card">
            <div className="stat-icon green">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                <polyline points="22 4 12 14.01 9 11.01"></polyline>
              </svg>
            </div>
            <div className="stat-info">
              <span className="stat-value">{stats.aktif}</span>
              <span className="stat-label">Siswa Aktif</span>
            </div>
          </div>
          <div className="stat-card">
            <div className="stat-icon purple">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M22 10v6M2 10l10-5 10 5-10 5z"></path>
                <path d="M6 12v5c3 3 9 3 12 0v-5"></path>
              </svg>
            </div>
            <div className="stat-info">
              <span className="stat-value">{stats.lulus}</span>
              <span className="stat-label">Siswa Lulus</span>
            </div>
          </div>
        </div>

        {/* Filters */}
        <div className="filters-section">
          <div className="search-box">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <circle cx="11" cy="11" r="8"></circle>
              <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
            </svg>
            <input
              type="text"
              placeholder="Cari nama, NIS, atau NISN..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <select value={filterKelas} onChange={(e) => setFilterKelas(e.target.value)}>
            <option value="">Semua Kelas</option>
            {kelasOptions.map(k => <option key={k} value={k}>{k}</option>)}
          </select>
          <select value={filterJurusan} onChange={(e) => setFilterJurusan(e.target.value)}>
            <option value="">Semua Jurusan</option>
            {jurusanOptions.map(j => <option key={j} value={j}>{j}</option>)}
          </select>
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

        {/* Table */}
        <div className="table-container">
          {loading ? (
            <div className="loading-state">
              <div className="spinner"></div>
              <p>Memuat data siswa...</p>
            </div>
          ) : students.length === 0 ? (
            <div className="empty-state">
              <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                <circle cx="9" cy="7" r="4"></circle>
              </svg>
              <p>Belum ada data siswa</p>
              <button className="btn-add-small" onClick={handleAdd}>Tambah Siswa</button>
            </div>
          ) : (
            <table className="data-table">
              <thead>
                <tr>
                  <th>Siswa</th>
                  <th>NIS / NISN</th>
                  <th>Kelas</th>
                  <th>Jurusan</th>
                  <th>Status</th>
                  <th>Aksi</th>
                </tr>
              </thead>
              <tbody>
                {students.map((student) => (
                  <tr key={student.id}>
                    <td>
                      <div className="student-cell">
                        <div className="student-avatar">
                          {student.name?.charAt(0).toUpperCase()}
                        </div>
                        <div className="student-info">
                          <span className="student-name">{student.name}</span>
                          <span className="student-email">{student.email}</span>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div className="id-cell">
                        <span className="nisn">{student.nisn}</span>
                        <span className="nis">{student.nis}</span>
                      </div>
                    </td>
                    <td><span className="kelas-badge">{student.kelas}</span></td>
                    <td>{student.jurusan}</td>
                    <td>
                      <span className={`status-badge status-${student.status_kelulusan || 'aktif'}`}>
                        {student.status_kelulusan || 'Aktif'}
                      </span>
                    </td>
                    <td>
                      <div className="action-buttons">
                        <button className="btn-action btn-view" onClick={() => handleView(student)} title="Lihat">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
                            <circle cx="12" cy="12" r="3"></circle>
                          </svg>
                        </button>
                        <button className="btn-action btn-edit" onClick={() => handleEdit(student)} title="Edit">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                          </svg>
                        </button>
                        <button className="btn-action btn-delete" onClick={() => handleDelete(student)} title="Hapus">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <polyline points="3 6 5 6 21 6"></polyline>
                            <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                          </svg>
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        {/* Modal */}
        {showModal && (
          <div className="modal-overlay" onClick={closeModal}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h2 className="modal-title">
                  {modalType === 'add' && 'Tambah Siswa Baru'}
                  {modalType === 'edit' && 'Edit Data Siswa'}
                  {modalType === 'delete' && 'Hapus Siswa'}
                  {modalType === 'view' && 'Detail Siswa'}
                </h2>
                <button className="modal-close" onClick={closeModal}>
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                  </svg>
                </button>
              </div>

              {modalType === 'view' ? (
                <div className="view-content">
                  <div className="view-avatar">
                    {selectedStudent?.name?.charAt(0).toUpperCase()}
                  </div>
                  <h3>{selectedStudent?.name}</h3>
                  <div className="view-grid">
                    <div className="view-item"><label>Email</label><span>{selectedStudent?.email}</span></div>
                    <div className="view-item"><label>NIS</label><span>{selectedStudent?.nis}</span></div>
                    <div className="view-item"><label>NISN</label><span>{selectedStudent?.nisn}</span></div>
                    <div className="view-item"><label>Kelas</label><span>{selectedStudent?.kelas}</span></div>
                    <div className="view-item"><label>Jurusan</label><span>{selectedStudent?.jurusan}</span></div>
                    <div className="view-item"><label>Jenis Kelamin</label><span>{selectedStudent?.jenis_kelamin === 'L' ? 'Laki-laki' : 'Perempuan'}</span></div>
                    <div className="view-item"><label>Telepon</label><span>{selectedStudent?.telepon || '-'}</span></div>
                    <div className="view-item"><label>Alamat</label><span>{selectedStudent?.alamat || '-'}</span></div>
                    <div className="view-item"><label>Status</label><span className={`status-badge status-${selectedStudent?.status_kelulusan || 'aktif'}`}>{selectedStudent?.status_kelulusan || 'Aktif'}</span></div>
                  </div>
                </div>
              ) : modalType === 'delete' ? (
                <div className="delete-content">
                  <p>Apakah Anda yakin ingin menghapus siswa <strong>"{selectedStudent?.name}"</strong>?</p>
                  <p className="warning-text">Tindakan ini tidak dapat dibatalkan.</p>
                </div>
              ) : (
                <div className="form-content">
                  <div className="form-row">
                    <div className="form-group">
                      <label>Nama Lengkap *</label>
                      <input type="text" value={formData.name || ''} onChange={(e) => handleInputChange('name', e.target.value)} placeholder="Masukkan nama lengkap" />
                    </div>
                    <div className="form-group">
                      <label>Email *</label>
                      <input type="email" value={formData.email || ''} onChange={(e) => handleInputChange('email', e.target.value)} placeholder="email@example.com" />
                    </div>
                  </div>
                  {modalType === 'add' && (
                    <div className="form-group">
                      <label>Password *</label>
                      <input type="password" value={formData.password || ''} onChange={(e) => handleInputChange('password', e.target.value)} placeholder="Minimal 6 karakter" />
                    </div>
                  )}
                  {modalType === 'edit' && (
                    <div className="form-group">
                      <label>Password Baru (kosongkan jika tidak diubah)</label>
                      <input type="password" value={formData.password || ''} onChange={(e) => handleInputChange('password', e.target.value)} placeholder="Minimal 6 karakter" />
                    </div>
                  )}
                  <div className="form-row">
                    <div className="form-group">
                      <label>NIS *</label>
                      <input type="text" value={formData.nis || ''} onChange={(e) => handleInputChange('nis', e.target.value)} placeholder="Nomor Induk Siswa" />
                    </div>
                    <div className="form-group">
                      <label>NISN *</label>
                      <input type="text" value={formData.nisn || ''} onChange={(e) => handleInputChange('nisn', e.target.value)} placeholder="Nomor Induk Siswa Nasional" />
                    </div>
                  </div>
                  <div className="form-row">
                    <div className="form-group">
                      <label>Kelas *</label>
                      <select value={formData.kelas || ''} onChange={(e) => handleInputChange('kelas', e.target.value)}>
                        {kelasOptions.map(k => <option key={k} value={k}>{k}</option>)}
                      </select>
                    </div>
                    <div className="form-group">
                      <label>Jurusan *</label>
                      <select value={formData.jurusan || ''} onChange={(e) => handleInputChange('jurusan', e.target.value)}>
                        {jurusanOptions.map(j => <option key={j} value={j}>{j}</option>)}
                      </select>
                    </div>
                    <div className="form-group">
                      <label>Jenis Kelamin *</label>
                      <select value={formData.jenis_kelamin || 'L'} onChange={(e) => handleInputChange('jenis_kelamin', e.target.value)}>
                        <option value="L">Laki-laki</option>
                        <option value="P">Perempuan</option>
                      </select>
                    </div>
                  </div>
                  <div className="form-group">
                    <label>Telepon</label>
                    <input type="text" value={formData.telepon || ''} onChange={(e) => handleInputChange('telepon', e.target.value)} placeholder="Nomor telepon" />
                  </div>
                  <div className="form-group">
                    <label>Alamat</label>
                    <textarea value={formData.alamat || ''} onChange={(e) => handleInputChange('alamat', e.target.value)} placeholder="Alamat lengkap" rows="2" />
                  </div>
                  {modalType === 'edit' && (
                    <div className="form-group">
                      <label>Status</label>
                      <select value={formData.status_kelulusan || 'aktif'} onChange={(e) => handleInputChange('status_kelulusan', e.target.value)}>
                        <option value="aktif">Aktif</option>
                        <option value="lulus">Lulus</option>
                        <option value="keluar">Keluar</option>
                      </select>
                    </div>
                  )}
                </div>
              )}

              {/* Error in modal */}
              {error && showModal && (
                <div className="modal-error">⚠️ {error}</div>
              )}

              <div className="modal-actions">
                <button className="btn-secondary" onClick={closeModal} disabled={submitting}>
                  {modalType === 'view' ? 'Tutup' : 'Batal'}
                </button>
                {modalType === 'delete' && (
                  <button className="btn-danger" onClick={handleDeleteConfirm} disabled={submitting}>
                    {submitting ? 'Menghapus...' : 'Hapus'}
                  </button>
                )}
                {(modalType === 'add' || modalType === 'edit') && (
                  <button className="btn-primary" onClick={handleSubmit} disabled={submitting}>
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

export default Students;
