import React, { useState, useEffect, useRef } from 'react';
import MainLayout from '../../components/Layout/MainLayout';
import { getPayments, getPaymentDetail, verifyPayment, processManualPayment } from '../../api/payments';
import { scanQueueQr, serveQueue } from '../../api/queues';
import './Payments.css';

const Payments = () => {
  const [payments, setPayments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState(''); // '', 'pending', 'verified', 'unpaid'
  const [searchTerm, setSearchTerm] = useState('');
  
  // Modal states
  const [showModal, setShowModal] = useState(false);
  const [selectedPayment, setSelectedPayment] = useState(null);
  const [processing, setProcessing] = useState(false);

  // Scanner states
  const [showScanner, setShowScanner] = useState(false);
  const [qrInput, setQrInput] = useState('');
  const [lastScannedQr, setLastScannedQr] = useState(''); // Store last scanned QR for refresh
  const [scanResult, setScanResult] = useState(null);
  const [scanError, setScanError] = useState(null);
  const qrInputRef = useRef(null);

  // Manual Payment State
  const [payModal, setPayModal] = useState(null); // { id, total, paid, remaining, period }
  const [payAmount, setPayAmount] = useState('');
  const [payAmountDisplay, setPayAmountDisplay] = useState('');

  // Format number to Rupiah display
  const formatToRupiah = (num) => {
    if (!num) return '';
    return new Intl.NumberFormat('id-ID').format(num);
  };

  // Handle payment amount input with auto-format
  const handlePayAmountChange = (e) => {
    // Remove all non-digit characters
    const rawValue = e.target.value.replace(/\D/g, '');
    const numValue = parseInt(rawValue, 10) || 0;
    
    setPayAmount(rawValue); // Store raw number
    setPayAmountDisplay(rawValue ? formatToRupiah(numValue) : ''); // Display formatted
  };

  // Focus input when scanner modal opens
  useEffect(() => {
    if (showScanner && qrInputRef.current) {
      qrInputRef.current.focus();
    }
  }, [showScanner]);

  // Fetch payments
  const fetchData = async () => {
    setLoading(true);
    try {
      const params = {};
      if (filterStatus) params.status = filterStatus;
      
      const response = await getPayments(params);
      if (response.status) {
        let data = response.data || [];
        
        // Client-side search filtering (since backend might not support search by name yet)
        if (searchTerm) {
          const lowerTerm = searchTerm.toLowerCase();
          data = data.filter(p => 
            p.student_name?.toLowerCase().includes(lowerTerm) ||
            p.class?.toLowerCase().includes(lowerTerm)
          );
        }
        
        setPayments(data);
      }
    } catch (error) {
      console.error('Error fetching payments:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [filterStatus, searchTerm]);

  const handleViewDetail = async (payment) => {
    // Use data from list first, then fetch full detail if needed
    setSelectedPayment(payment);
    setShowModal(true);
    
    try {
      const detailRes = await getPaymentDetail(payment.id);
      if (detailRes.status) {
        setSelectedPayment(prev => ({ ...prev, ...detailRes.data }));
      }
    } catch (error) {
      console.error('Error fetching detail:', error);
    }
  };

  const handleVerify = async (status) => {
    if (!selectedPayment) return;
    if (!window.confirm(status === 'verified' ? 'Verifikasi pembayaran ini?' : 'Tolak pembayaran ini?')) return;

    setProcessing(true);
    try {
      await verifyPayment(selectedPayment.id, status);
      setShowModal(false);
      fetchData(); // Refresh list
    } catch (error) {
      console.error('Error verifying payment:', error);
      alert('Gagal memverifikasi pembayaran');
    } finally {
      setProcessing(false);
    }
  };

  const handleScan = async (e) => {
    e.preventDefault();
    if (!qrInput) return;

    setProcessing(true);
    setScanError(null);
    setScanResult(null);

    try {
      const response = await scanQueueQr(qrInput);
      if (response.status) {
        setLastScannedQr(qrInput); // Store for refresh
        setScanResult({
          ...response.data,
          bills: response.bills || []
        });
        setQrInput(''); // Clear input for next scan
      } else {
        setScanError(response.message || 'Antrian tidak ditemukan');
      }
    } catch (error) {
      console.error('Scan error:', error);
      setScanError(error.response?.data?.message || 'Gagal memproses QR Code');
    } finally {
      setProcessing(false);
      // Keep focus on input for continuous scanning
      if (qrInputRef.current) qrInputRef.current.focus();
    }
  };

  // Refresh scan result after payment
  const refreshScanResult = async () => {
    if (!lastScannedQr) return;
    
    try {
      const response = await scanQueueQr(lastScannedQr);
      if (response.status) {
        setScanResult({
          ...response.data,
          bills: response.bills || []
        });
      }
    } catch (error) {
      console.error('Refresh error:', error);
    }
  };

  const handleServeQueue = async () => {
    if (!scanResult) return;
    setProcessing(true);
    try {
      await serveQueue(scanResult.id);
      alert(`Antrian ${scanResult.queue_number} sekarang dilayani.`);
      // Optional: redirect to payment page filtered by this student
      setSearchTerm(scanResult.user.name);
      setShowScanner(false);
    } catch (error) {
      console.error('Serve error:', error);
      alert('Gagal memproses antrian');
    } finally {
      setProcessing(false);
    }
  };

  const handleViewStudentBills = () => {
    if (scanResult?.user?.name) {
      setSearchTerm(scanResult.user.name);
      setShowScanner(false);
    }
  };

  // Manual Payment Handlers
  const openPayModal = (bill) => {
    const total = Number(bill.jumlah);
    const paid = Number(bill.terbayar || 0);
    const remaining = total - paid;
    
    setPayModal({
      id: bill.id,
      total,
      paid,
      remaining,
      period: `${bill.bulan} ${bill.tahun}`
    });
    setPayAmount(String(remaining)); // Store raw number
    setPayAmountDisplay(formatToRupiah(remaining)); // Display formatted
  };

  const handlePaySubmit = async (e) => {
    e.preventDefault();
    if (!payModal || !payAmount) return;

    const amount = Number(payAmount);
    if (amount <= 0 || amount > payModal.remaining) {
      alert('Nominal tidak valid (harus > 0 dan <= sisa tagihan)');
      return;
    }

    setProcessing(true);
    try {
      const res = await processManualPayment(payModal.id, amount);
      if (res.status) {
        alert(res.message || 'Pembayaran berhasil!');
        setPayModal(null);
        setPayAmount('');
        setPayAmountDisplay('');
        
        // Refresh scan result from server
        await refreshScanResult();
        
        // Refresh main table
        fetchData();
      }
    } catch (error) {
      console.error('Payment error:', error);
      alert(error.response?.data?.message || 'Gagal memproses pembayaran');
    } finally {
      setProcessing(false);
    }
  };

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount);
  };

  const formatDate = (dateString) => {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleDateString('id-ID', { 
      day: 'numeric', month: 'long', year: 'numeric',
      hour: '2-digit', minute: '2-digit'
    });
  };

  return (
    <MainLayout>
      <div className="payments-page">
        {/* Header */}
        <div className="page-header">
          <div className="header-info">
            <h1 className="page-title">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <rect x="2" y="5" width="20" height="14" rx="2" />
                <line x1="2" y1="10" x2="22" y2="10" />
              </svg>
              Transaksi SPP
            </h1>
            <p className="page-subtitle">Kelola dan verifikasi pembayaran SPP siswa</p>
          </div>
          <button className="btn-scan" onClick={() => { setShowScanner(true); setScanResult(null); setScanError(null); }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M3 7V5a2 2 0 0 1 2-2h2"></path>
              <path d="M17 3h2a2 2 0 0 1 2 2v2"></path>
              <path d="M21 17v2a2 2 0 0 1-2 2h-2"></path>
              <path d="M7 21H5a2 2 0 0 1-2-2v-2"></path>
              <rect x="7" y="7" width="3" height="3"></rect>
              <rect x="14" y="7" width="3" height="3"></rect>
              <rect x="7" y="14" width="3" height="3"></rect>
              <line x1="14" y1="14" x2="17" y2="17"></line>
            </svg>
            Scan Antrian
          </button>
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
              placeholder="Cari nama siswa..." 
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
          <select 
            value={filterStatus} 
            onChange={(e) => setFilterStatus(e.target.value)}
            className="filter-select"
          >
            <option value="">Semua Status</option>
            <option value="unpaid">Belum Bayar</option>
            <option value="pending">Pending</option>
            <option value="partial">Cicilan</option>
            <option value="verified">Lunas</option>
            <option value="failed">Gagal</option>
          </select>
        </div>

        {/* Table */}
        <div className="table-container">
          {loading ? (
            <div className="loading-state">
              <div className="spinner"></div>
              <p>Memuat data transaksi...</p>
            </div>
          ) : payments.length === 0 ? (
            <div className="empty-state">
              <p>Tidak ada data transaksi ditemukan.</p>
            </div>
          ) : (
            <table className="data-table">
              <thead>
                <tr>
                  <th>Siswa</th>
                  <th>Tagihan</th>
                  <th>Total / Terbayar</th>
                  <th>Sisa</th>
                  <th>Tanggal Bayar</th>
                  <th>Metode</th>
                  <th>Status</th>
                  <th>Aksi</th>
                </tr>
              </thead>
              <tbody>
                {payments.map((payment) => (
                  <tr key={payment.id}>
                    <td>
                      <span className="student-name">{payment.student_name}</span>
                      <span className="student-class">{payment.class}</span>
                    </td>
                    <td>
                      {payment.bulan} {payment.tahun}
                    </td>
                    <td className="amount-cell">
                      <div className="payment-progress">
                        <div className="total-terbayar">
                          {formatCurrency(payment.amount)} / {formatCurrency(payment.terbayar || 0)}
                        </div>
                        <div className="amount-labels">
                          <small>Total / Terbayar</small>
                        </div>
                      </div>
                    </td>
                    <td className="remaining-cell">
                      <span className={payment.remaining > 0 ? 'remaining-amount' : 'fully-paid'}>
                        {formatCurrency(payment.remaining || 0)}
                      </span>
                    </td>
                    <td className="date-cell">
                      {formatDate(payment.tanggal_bayar)}
                    </td>
                    <td>
                      {payment.metode_bayar || '-'}
                    </td>
                    <td>
                      <span className={`status-badge status-${payment.status}`}>
                        {payment.status === 'verified' ? 'Lunas' : 
                         payment.status === 'pending' ? 'Pending' : 
                         payment.status === 'partial' ? 'Cicilan' :
                         payment.status === 'unpaid' ? 'Belum Bayar' : payment.status}
                      </span>
                    </td>
                    <td>
                      <button 
                        className="btn-detail"
                        onClick={() => handleViewDetail(payment)}
                      >
                        Detail
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        {/* Detail Modal */}
        {showModal && selectedPayment && (
          <div className="modal-overlay" onClick={() => setShowModal(false)}>
            <div className="modal-content" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h2 className="modal-title">Detail Pembayaran</h2>
                <button className="modal-close" onClick={() => setShowModal(false)}>
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                  </svg>
                </button>
              </div>
              <div className="modal-body">
                <div className="detail-row">
                  <span className="detail-label">Nama Siswa</span>
                  <span className="detail-value">{selectedPayment.student_name}</span>
                </div>
                <div className="detail-row">
                  <span className="detail-label">Kelas / Jurusan</span>
                  <span className="detail-value">{selectedPayment.class} {selectedPayment.jurusan ? `- ${selectedPayment.jurusan}` : ''}</span>
                </div>
                <div className="detail-row">
                  <span className="detail-label">NIS / NISN</span>
                  <span className="detail-value">{selectedPayment.nis} / {selectedPayment.nisn}</span>
                </div>
                <div className="detail-row">
                  <span className="detail-label">Tagihan Bulan</span>
                  <span className="detail-value">{selectedPayment.bulan} {selectedPayment.tahun}</span>
                </div>
                <div className="detail-row">
                  <span className="detail-label">Jumlah Pembayaran</span>
                  <span className="detail-value" style={{ color: '#059669' }}>
                    {formatCurrency(selectedPayment.amount || selectedPayment.jumlah)}
                  </span>
                </div>
                <div className="detail-row">
                  <span className="detail-label">Metode Pembayaran</span>
                  <span className="detail-value">{selectedPayment.metode_bayar || 'Belum dipilih'}</span>
                </div>
                <div className="detail-row">
                  <span className="detail-label">Tanggal Bayar</span>
                  <span className="detail-value">{formatDate(selectedPayment.tanggal_bayar)}</span>
                </div>
                <div className="detail-row">
                  <span className="detail-label">Status</span>
                  <span className="detail-value">
                    <span className={`status-badge status-${selectedPayment.status}`}>
                      {selectedPayment.status === 'verified' ? 'Lunas' : 
                       selectedPayment.status === 'pending' ? 'Menunggu Verifikasi' : selectedPayment.status}
                    </span>
                  </span>
                </div>
              </div>
              
              <div className="modal-actions">
                {selectedPayment.status === 'pending' ? (
                  <>
                    <button 
                      className="btn-reject" 
                      onClick={() => handleVerify('rejected')}
                      disabled={processing}
                    >
                      Tolak
                    </button>
                    <button 
                      className="btn-verify" 
                      onClick={() => handleVerify('verified')}
                      disabled={processing}
                    >
                      {processing ? 'Memproses...' : 'Verifikasi'}
                    </button>
                  </>
                ) : (
                  <button className="btn-close" onClick={() => setShowModal(false)}>
                    Tutup
                  </button>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Scanner Modal */}
        {showScanner && (
          <div className="modal-overlay" onClick={() => setShowScanner(false)}>
            <div className="modal-content scanner-modal" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h2 className="modal-title">Scan QR Antrian</h2>
                <button className="modal-close" onClick={() => setShowScanner(false)}>✕</button>
              </div>
              <div className="modal-body">
                <div className="scanner-input-container">
                  <p className="scanner-instruction">
                    Gunakan scanner atau ketik kode QR antrian di bawah ini.
                  </p>
                  <form onSubmit={handleScan} className="scanner-form">
                    <input 
                      ref={qrInputRef}
                      type="text" 
                      className="scanner-input"
                      placeholder="Klik di sini & scan QR Code..." 
                      value={qrInput} 
                      onChange={(e) => setQrInput(e.target.value)}
                      disabled={processing}
                      autoComplete="off"
                    />
                    <button type="submit" className="btn-scan-submit" disabled={processing}>
                      {processing ? 'Mencari...' : 'Cari'}
                    </button>
                  </form>
                </div>

                {scanError && (
                  <div className="scan-error-message">
                    ⚠️ {scanError}
                  </div>
                )}

                {scanResult && (
                  <div className="scan-result-card">
                    <div className="scan-result-header">
                      <span className="queue-number">{scanResult.queue_number}</span>
                      <span className={`queue-status status-${scanResult.status}`}>
                        {scanResult.status}
                      </span>
                    </div>
                    <div className="scan-result-info">
                      <div className="scan-info-row">
                        <span className="label">Siswa</span>
                        <span className="value">{scanResult.user?.name}</span>
                      </div>
                      <div className="scan-info-row">
                        <span className="label">Kelas</span>
                        <span className="value">{scanResult.user?.kelas} - {scanResult.user?.jurusan}</span>
                      </div>
                      <div className="scan-info-row">
                        <span className="label">Layanan</span>
                        <span className="value">{scanResult.service?.name || 'Pembayaran SPP'}</span>
                      </div>
                    </div>

                    {scanResult.bills && scanResult.bills.length > 0 ? (
                      <div className="scan-bills-section">
                        <div className="bills-header">
                          <h4 className="bills-title">Tagihan Belum Dibayar</h4>
                          <span className="bills-count">{scanResult.bills.length} Tagihan</span>
                        </div>
                        <div className="bills-list">
                          {scanResult.bills.slice(0, 3).map(bill => (
                            <div key={bill.id} className="bill-item">
                              <div className="bill-info-col">
                                <div className="bill-header-row">
                                  <span className="bill-period">{bill.bulan} {bill.tahun}</span>
                                  <span className={`bill-status status-${bill.status}`}>{bill.status}</span>
                                </div>
                                <div className="bill-progress-row">
                                  <small>Terbayar: {formatCurrency(bill.terbayar || 0)}</small>
                                </div>
                              </div>
                              <div className="bill-action-col">
                                <span className="bill-remaining">{formatCurrency(bill.jumlah - (bill.terbayar || 0))}</span>
                                <button className="btn-pay-small" onClick={() => openPayModal(bill)}>Bayar</button>
                              </div>
                            </div>
                          ))}
                          {scanResult.bills.length > 3 && (
                            <div className="bills-more">
                              + {scanResult.bills.length - 3} tagihan lainnya
                            </div>
                          )}
                        </div>
                        <div className="bills-total-row">
                          <span>Total Tunggakan</span>
                          <span className="total-amount">
                            {formatCurrency(scanResult.bills.reduce((a, b) => a + (Number(b.jumlah) - Number(b.terbayar || 0)), 0))}
                          </span>
                        </div>
                      </div>
                    ) : (
                      <div className="scan-bills-empty">
                        ✅ Tidak ada tagihan tertunggak
                      </div>
                    )}

                    <div className="scan-actions">
                      <button className="btn-action-serve" onClick={handleServeQueue} disabled={processing}>
                        Layani Antrian
                      </button>
                      <button className="btn-action-view" onClick={handleViewStudentBills}>
                        Lihat Semua Tagihan
                      </button>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Manual Payment Modal */}
        {payModal && (
          <div className="modal-overlay" style={{ zIndex: 1000 }}>
            <div className="modal-content payment-modal" onClick={(e) => e.stopPropagation()}>
              <div className="modal-header">
                <h3 className="modal-title">Pembayaran Tagihan</h3>
                <button className="modal-close" onClick={() => setPayModal(null)}>✕</button>
              </div>
              <form onSubmit={handlePaySubmit} className="modal-body">
                <div className="pay-info-box">
                  <div className="pay-row">
                    <span>Periode</span>
                    <strong>{payModal.period}</strong>
                  </div>
                  <div className="pay-row">
                    <span>Total Tagihan</span>
                    <span>{formatCurrency(payModal.total)}</span>
                  </div>
                  <div className="pay-row">
                    <span>Sudah Dibayar</span>
                    <span>{formatCurrency(payModal.paid)}</span>
                  </div>
                  <div className="pay-row highlight">
                    <span>Sisa Pembayaran</span>
                    <strong>{formatCurrency(payModal.remaining)}</strong>
                  </div>
                </div>
                
                <div className="form-group">
                  <label>Nominal Bayar</label>
                  <div className="input-rupiah">
                    <span className="rupiah-prefix">Rp</span>
                    <input 
                      type="text" 
                      className="form-control"
                      value={payAmountDisplay}
                      onChange={handlePayAmountChange}
                      placeholder="0"
                      required
                      autoFocus
                    />
                  </div>
                  <small className="form-hint">Masukkan nominal pembayaran (bisa sebagian)</small>
                </div>

                <div className="modal-actions">
                  <button type="button" className="btn-close" onClick={() => setPayModal(null)}>Batal</button>
                  <button type="submit" className="btn-verify" disabled={processing}>
                    {processing ? 'Memproses...' : 'Proses Pembayaran'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </MainLayout>
  );
};

export default Payments;
