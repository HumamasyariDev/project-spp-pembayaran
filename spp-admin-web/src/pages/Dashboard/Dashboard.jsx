import React, { useState, useEffect } from 'react';
import MainLayout from '../../components/Layout/MainLayout';
import { getAdminStats, getPayments } from '../../api/dashboard';
import './Dashboard.css';

const Dashboard = () => {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [dashboardData, setDashboardData] = useState({
    totalStudents: 0,
    totalCollected: 0,
    transactionsToday: 0,
    unpaidBills: 0,
    pendingPayments: 0
  });
  const [recentTransactions, setRecentTransactions] = useState([]);

  // Ambil data user dari localStorage dengan aman
  let user = {};
  try {
    const userData = localStorage.getItem('user');
    user = userData ? JSON.parse(userData) : { name: 'Admin' };
  } catch (e) {
    user = { name: 'Admin' };
  }

  // Fetch dashboard data from API
  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setLoading(true);
        setError(null);

        // Check if token exists
        const token = localStorage.getItem('token');
        if (!token) {
          setError('Anda belum login. Silakan login terlebih dahulu.');
          setLoading(false);
          return;
        }

        // Fetch admin stats and payments in parallel
        const [statsResponse, paymentsResponse] = await Promise.all([
          getAdminStats(),
          getPayments()
        ]);

        if (statsResponse.status) {
          const { queues, payments, bills } = statsResponse.data;
          setDashboardData({
            totalStudents: bills?.unpaid_total || 0, // Using unpaid as proxy for now
            totalCollected: payments?.collected_today || 0,
            transactionsToday: payments?.verified_today || 0,
            unpaidBills: bills?.unpaid_total || 0,
            pendingPayments: payments?.pending || 0
          });
        }

        if (paymentsResponse.status && paymentsResponse.data) {
          // Transform payments data for display
          const payments = Array.isArray(paymentsResponse.data) 
            ? paymentsResponse.data 
            : [];
          
          const formattedTransactions = payments.slice(0, 5).map((payment, index) => ({
            id: payment.id || index,
            student: payment.student_name || payment.user?.name || 'Unknown',
            class: payment.class || payment.user?.kelas || '-',
            amount: formatCurrency(payment.amount || payment.jumlah || 0),
            date: formatDate(payment.tanggal_bayar || payment.created_at),
            status: mapStatus(payment.status)
          }));
          
          setRecentTransactions(formattedTransactions);
        }

      } catch (err) {
        console.error('Error fetching dashboard data:', err);
        
        // Check if it's an authentication error
        if (err.response?.status === 401) {
          setError('Sesi telah berakhir. Silakan login kembali.');
          // Optionally redirect to login
          // localStorage.removeItem('token');
          // localStorage.removeItem('user');
          // window.location.href = '/login';
        } else if (err.response?.status === 403) {
          setError('Anda tidak memiliki akses ke halaman ini.');
        } else if (err.code === 'ERR_NETWORK') {
          setError('Tidak dapat terhubung ke server. Pastikan backend sudah berjalan.');
        } else {
          setError('Gagal memuat data dashboard');
        }
        
        // Set default data on error
        setRecentTransactions([]);
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

  // Helper functions
  const formatCurrency = (amount) => {
    if (!amount) return 'Rp 0';
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount);
  };

  const formatDate = (dateString) => {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return date.toLocaleDateString('id-ID', {
      day: 'numeric',
      month: 'short',
      year: 'numeric'
    });
  };

  const mapStatus = (status) => {
    const statusMap = {
      'verified': 'Sukses',
      'paid': 'Sukses',
      'pending': 'Pending',
      'rejected': 'Gagal',
      'failed': 'Gagal'
    };
    return statusMap[status?.toLowerCase()] || status || 'Pending';
  };

  const formatShortCurrency = (amount) => {
    if (!amount) return 'Rp 0';
    if (amount >= 1000000000) {
      return `Rp ${(amount / 1000000000).toFixed(1)}M`;
    }
    if (amount >= 1000000) {
      return `Rp ${(amount / 1000000).toFixed(1)}Jt`;
    }
    if (amount >= 1000) {
      return `Rp ${(amount / 1000).toFixed(0)}Rb`;
    }
    return formatCurrency(amount);
  };

  // Stats data with real values
  const stats = [
    { 
      title: 'Tagihan Belum Lunas', 
      value: dashboardData.unpaidBills.toLocaleString('id-ID'), 
      label: 'Total Tagihan', 
      icon: <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>,
      color: 'blue'
    },
    { 
      title: 'Pemasukan Hari Ini', 
      value: formatShortCurrency(dashboardData.totalCollected), 
      label: 'Terverifikasi', 
      icon: <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="12" y1="1" x2="12" y2="23"></line><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path></svg>,
      color: 'green'
    },
    { 
      title: 'Transaksi Hari Ini', 
      value: dashboardData.transactionsToday.toString(), 
      label: 'Pembayaran', 
      icon: <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="22 12 18 12 15 21 9 3 6 12 2 12"></polyline></svg>,
      color: 'purple'
    },
    { 
      title: 'Menunggu Verifikasi', 
      value: dashboardData.pendingPayments.toString(), 
      label: 'Pending', 
      icon: <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="8" x2="12" y2="12"></line><line x1="12" y1="16" x2="12.01" y2="16"></line></svg>,
      color: 'red'
    }
  ];

  return (
    <MainLayout>
      <div className="dashboard-container">
        {/* Welcome Banner */}
        <div className="dashboard-header">
        <div className="header-info">
          <h1 className="page-title">
            <span className="wave">👋</span> Selamat Datang, {user.name || 'Admin'}!
          </h1>
          <p className="page-subtitle">Kelola pembayaran SPP dengan mudah dan efisien. Berikut ringkasan hari ini.</p>
        </div>
        <div className="header-actions">
          <button className="btn-primary">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
              <line x1="12" y1="5" x2="12" y2="19"></line>
              <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
            <span>Catat Pembayaran</span>
          </button>
          <button className="btn-secondary">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
              <polyline points="7 10 12 15 17 10"></polyline>
              <line x1="12" y1="15" x2="12" y2="3"></line>
            </svg>
            <span>Export Laporan</span>
          </button>
        </div>
      </div>

      {/* Error Message */}
      {error && (
        <div className="error-banner">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="12" cy="12" r="10"></circle>
            <line x1="12" y1="8" x2="12" y2="12"></line>
            <line x1="12" y1="16" x2="12.01" y2="16"></line>
          </svg>
          <span>{error}</span>
          <button onClick={() => window.location.reload()}>Coba Lagi</button>
        </div>
      )}

      {/* Stats Grid */}
      <div className="stats-grid">
        {stats.map((stat, index) => (
          <div key={index} className={`stat-card color-${stat.color} ${loading ? 'loading' : ''}`}>
            <div className="stat-icon-wrapper">
              {stat.icon}
            </div>
            <div className="stat-content">
              <p className="stat-title">{stat.title}</p>
              <h3 className="stat-value">{loading ? '...' : stat.value}</h3>
              <span className="stat-label">{stat.label}</span>
            </div>
          </div>
        ))}
      </div>

      {/* Recent Transactions Section */}
      <div className="content-section">
        <div className="section-header">
          <h2>Transaksi Terakhir</h2>
          <button className="btn-text">
            Lihat Semua
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="9 18 15 12 9 6"></polyline>
            </svg>
          </button>
        </div>
        <div className="table-container">
          {loading ? (
            <div className="loading-state">
              <div className="spinner"></div>
              <p>Memuat data transaksi...</p>
            </div>
          ) : recentTransactions.length === 0 ? (
            <div className="empty-state">
              <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                <path d="M9 5H7a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-2"></path>
                <rect x="9" y="3" width="6" height="4" rx="1"></rect>
                <line x1="9" y1="12" x2="15" y2="12"></line>
                <line x1="9" y1="16" x2="15" y2="16"></line>
              </svg>
              <p>Belum ada transaksi</p>
            </div>
          ) : (
            <table className="data-table">
              <thead>
                <tr>
                  <th>Siswa</th>
                  <th>Jumlah</th>
                  <th>Tanggal</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {recentTransactions.map((tx) => (
                  <tr key={tx.id}>
                    <td>
                      <div className="student-cell">
                        <div className="student-avatar">{tx.student.charAt(0).toUpperCase()}</div>
                        <div className="student-info">
                          <span className="student-name">{tx.student}</span>
                          <span className="student-class">{tx.class}</span>
                        </div>
                      </div>
                    </td>
                    <td><span className="amount-cell">{tx.amount}</span></td>
                    <td className="date-cell">{tx.date}</td>
                    <td>
                      <span className={`status-badge status-${tx.status.toLowerCase()}`}>
                        {tx.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* Quick Actions */}
      <div className="quick-actions">
        <div className="action-card">
          <div className="action-icon">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
              <circle cx="9" cy="7" r="4"></circle>
              <line x1="19" y1="8" x2="19" y2="14"></line>
              <line x1="22" y1="11" x2="16" y2="11"></line>
            </svg>
          </div>
          <div className="action-text">
            <h4>Tambah Siswa</h4>
            <p>Daftarkan siswa baru</p>
          </div>
        </div>
        <div className="action-card">
          <div className="action-icon">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <rect x="1" y="4" width="22" height="16" rx="2" ry="2"></rect>
              <line x1="1" y1="10" x2="23" y2="10"></line>
            </svg>
          </div>
          <div className="action-text">
            <h4>Pembayaran Baru</h4>
            <p>Catat transaksi SPP</p>
          </div>
        </div>
        <div className="action-card">
          <div className="action-icon">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
              <polyline points="14 2 14 8 20 8"></polyline>
              <line x1="16" y1="13" x2="8" y2="13"></line>
              <line x1="16" y1="17" x2="8" y2="17"></line>
            </svg>
          </div>
          <div className="action-text">
            <h4>Cetak Laporan</h4>
            <p>Generate laporan bulanan</p>
          </div>
        </div>
      </div>
      </div>
    </MainLayout>
  );
};

export default Dashboard;
