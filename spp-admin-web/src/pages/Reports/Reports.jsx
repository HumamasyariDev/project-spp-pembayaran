import React, { useState, useEffect } from 'react';
import MainLayout from '../../components/Layout/MainLayout';
import { getPayments } from '../../api/dashboard';
import './Reports.css';

const Reports = () => {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [reportType, setReportType] = useState('payments');
  const [dateRange, setDateRange] = useState({
    startDate: new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString().split('T')[0],
    endDate: new Date().toISOString().split('T')[0]
  });
  const [reportData, setReportData] = useState([]);
  const [summary, setSummary] = useState({
    totalAmount: 0,
    totalTransactions: 0,
    paidCount: 0,
    pendingCount: 0
  });

  const reportTypes = [
    { id: 'payments', label: 'Laporan Pembayaran', icon: '💰' },
    { id: 'monthly', label: 'Laporan Bulanan', icon: '📅' },
    { id: 'students', label: 'Laporan Per Siswa', icon: '👨‍🎓' },
  ];

  useEffect(() => {
    fetchReportData();
  }, [reportType, dateRange]);

  const fetchReportData = async () => {
    try {
      setLoading(true);
      setError(null);

      const token = localStorage.getItem('token');
      if (!token) {
        setError('Anda belum login. Silakan login terlebih dahulu.');
        setLoading(false);
        return;
      }

      const response = await getPayments();
      
      if (response.status && response.data) {
        const payments = Array.isArray(response.data) ? response.data : [];
        
        // Filter by date range
        const filteredPayments = payments.filter(payment => {
          const paymentDate = new Date(payment.tanggal_bayar || payment.created_at);
          const start = new Date(dateRange.startDate);
          const end = new Date(dateRange.endDate);
          end.setHours(23, 59, 59);
          return paymentDate >= start && paymentDate <= end;
        });

        setReportData(filteredPayments);

        // Calculate summary
        const totalAmount = filteredPayments.reduce((sum, p) => sum + (p.amount || p.jumlah || 0), 0);
        const paidCount = filteredPayments.filter(p => p.status === 'verified' || p.status === 'paid').length;
        const pendingCount = filteredPayments.filter(p => p.status === 'pending').length;

        setSummary({
          totalAmount,
          totalTransactions: filteredPayments.length,
          paidCount,
          pendingCount
        });
      }
    } catch (err) {
      console.error('Error fetching report data:', err);
      if (err.response?.status === 401) {
        setError('Sesi telah berakhir. Silakan login kembali.');
      } else if (err.code === 'ERR_NETWORK') {
        setError('Tidak dapat terhubung ke server.');
      } else {
        setError('Gagal memuat data laporan');
      }
    } finally {
      setLoading(false);
    }
  };

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0
    }).format(amount);
  };

  const formatDate = (dateString) => {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleDateString('id-ID', {
      day: '2-digit',
      month: 'short',
      year: 'numeric'
    });
  };

  const getStatusBadge = (status) => {
    const statusMap = {
      'verified': { label: 'Terverifikasi', class: 'status-success' },
      'paid': { label: 'Lunas', class: 'status-success' },
      'pending': { label: 'Pending', class: 'status-warning' },
      'rejected': { label: 'Ditolak', class: 'status-danger' },
    };
    const statusInfo = statusMap[status] || { label: status || 'Unknown', class: 'status-default' };
    return <span className={`status-badge ${statusInfo.class}`}>{statusInfo.label}</span>;
  };

  const handleExport = (format) => {
    // Export functionality
    if (format === 'csv') {
      exportToCSV();
    } else if (format === 'print') {
      window.print();
    }
  };

  const exportToCSV = () => {
    const headers = ['No', 'Tanggal', 'Nama Siswa', 'Kelas', 'Jumlah', 'Status'];
    const rows = reportData.map((item, index) => [
      index + 1,
      formatDate(item.tanggal_bayar || item.created_at),
      item.student_name || item.user?.name || '-',
      item.class || item.user?.kelas || '-',
      item.amount || item.jumlah || 0,
      item.status
    ]);

    const csvContent = [headers, ...rows].map(row => row.join(',')).join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = `laporan_${reportType}_${dateRange.startDate}_${dateRange.endDate}.csv`;
    link.click();
  };

  return (
    <MainLayout>
      <div className="reports-page">
        {/* Header */}
        <div className="reports-header">
          <div className="header-info">
            <h1 className="page-title">Laporan</h1>
            <p className="page-subtitle">Kelola dan unduh laporan pembayaran SPP</p>
          </div>
          <div className="header-actions">
            <button className="btn-export" onClick={() => handleExport('csv')}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                <polyline points="7 10 12 15 17 10"></polyline>
                <line x1="12" y1="15" x2="12" y2="3"></line>
              </svg>
              Export CSV
            </button>
            <button className="btn-print" onClick={() => handleExport('print')}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <polyline points="6 9 6 2 18 2 18 9"></polyline>
                <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path>
                <rect x="6" y="14" width="12" height="8"></rect>
              </svg>
              Print
            </button>
          </div>
        </div>

        {/* Report Type Tabs */}
        <div className="report-tabs">
          {reportTypes.map(type => (
            <button
              key={type.id}
              className={`tab-btn ${reportType === type.id ? 'active' : ''}`}
              onClick={() => setReportType(type.id)}
            >
              <span className="tab-icon">{type.icon}</span>
              {type.label}
            </button>
          ))}
        </div>

        {/* Filters */}
        <div className="filters-section">
          <div className="filter-group">
            <label>Tanggal Mulai</label>
            <input
              type="date"
              value={dateRange.startDate}
              onChange={(e) => setDateRange({ ...dateRange, startDate: e.target.value })}
              className="filter-input"
            />
          </div>
          <div className="filter-group">
            <label>Tanggal Akhir</label>
            <input
              type="date"
              value={dateRange.endDate}
              onChange={(e) => setDateRange({ ...dateRange, endDate: e.target.value })}
              className="filter-input"
            />
          </div>
          <button className="btn-filter" onClick={fetchReportData}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <circle cx="11" cy="11" r="8"></circle>
              <path d="m21 21-4.35-4.35"></path>
            </svg>
            Terapkan Filter
          </button>
        </div>

        {/* Summary Cards */}
        <div className="summary-cards">
          <div className="summary-card">
            <div className="summary-icon total">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <line x1="12" y1="1" x2="12" y2="23"></line>
                <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path>
              </svg>
            </div>
            <div className="summary-info">
              <span className="summary-label">Total Pembayaran</span>
              <span className="summary-value">{formatCurrency(summary.totalAmount)}</span>
            </div>
          </div>
          <div className="summary-card">
            <div className="summary-icon transactions">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <rect x="1" y="4" width="22" height="16" rx="2" ry="2"></rect>
                <line x1="1" y1="10" x2="23" y2="10"></line>
              </svg>
            </div>
            <div className="summary-info">
              <span className="summary-label">Total Transaksi</span>
              <span className="summary-value">{summary.totalTransactions}</span>
            </div>
          </div>
          <div className="summary-card">
            <div className="summary-icon success">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                <polyline points="22 4 12 14.01 9 11.01"></polyline>
              </svg>
            </div>
            <div className="summary-info">
              <span className="summary-label">Terverifikasi</span>
              <span className="summary-value">{summary.paidCount}</span>
            </div>
          </div>
          <div className="summary-card">
            <div className="summary-icon pending">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <circle cx="12" cy="12" r="10"></circle>
                <polyline points="12 6 12 12 16 14"></polyline>
              </svg>
            </div>
            <div className="summary-info">
              <span className="summary-label">Pending</span>
              <span className="summary-value">{summary.pendingCount}</span>
            </div>
          </div>
        </div>

        {/* Report Table */}
        <div className="report-table-container">
          {loading ? (
            <div className="loading-state">
              <div className="spinner"></div>
              <p>Memuat data laporan...</p>
            </div>
          ) : error ? (
            <div className="error-state">
              <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <circle cx="12" cy="12" r="10"></circle>
                <line x1="12" y1="8" x2="12" y2="12"></line>
                <line x1="12" y1="16" x2="12.01" y2="16"></line>
              </svg>
              <p>{error}</p>
              <button onClick={fetchReportData} className="btn-retry">Coba Lagi</button>
            </div>
          ) : reportData.length === 0 ? (
            <div className="empty-state">
              <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                <polyline points="14 2 14 8 20 8"></polyline>
                <line x1="16" y1="13" x2="8" y2="13"></line>
                <line x1="16" y1="17" x2="8" y2="17"></line>
              </svg>
              <p>Tidak ada data untuk periode ini</p>
            </div>
          ) : (
            <table className="report-table">
              <thead>
                <tr>
                  <th>No</th>
                  <th>Tanggal</th>
                  <th>Nama Siswa</th>
                  <th>Kelas</th>
                  <th>Jumlah</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {reportData.map((item, index) => (
                  <tr key={item.id || index}>
                    <td>{index + 1}</td>
                    <td>{formatDate(item.tanggal_bayar || item.created_at)}</td>
                    <td>{item.student_name || item.user?.name || '-'}</td>
                    <td>{item.class || item.user?.kelas || '-'}</td>
                    <td className="amount">{formatCurrency(item.amount || item.jumlah || 0)}</td>
                    <td>{getStatusBadge(item.status)}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr>
                  <td colSpan="4" className="total-label">Total</td>
                  <td className="total-amount">{formatCurrency(summary.totalAmount)}</td>
                  <td></td>
                </tr>
              </tfoot>
            </table>
          )}
        </div>
      </div>
    </MainLayout>
  );
};

export default Reports;
