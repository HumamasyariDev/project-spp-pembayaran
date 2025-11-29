import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { login } from '../../api/auth';
import './Login.css'; // We will create this file next

const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');
    
    try {
      const response = await login(email, password);
      
      // Response structure: { status: true, message: '...', data: { user: {...}, token: '...' } }
      const { data } = response;
      
      // Store token and user data
      localStorage.setItem('token', data.token);
      localStorage.setItem('user', JSON.stringify(data.user));
      
      console.log('Login successful, token saved:', data.token ? 'Yes' : 'No');
      
      // Redirect to dashboard
      navigate('/dashboard');
    } catch (err) {
      console.error('Login failed:', err);
      
      // Check for specific error messages from backend
      if (err.message === 'Unauthorized' || err.status === 401) {
        setError('Email atau password salah. Silakan coba lagi.');
      } else if (err.status === 422) {
        setError('Mohon periksa format email dan password Anda.');
      } else if (err.message === 'Network Error') {
        setError('Gagal terhubung ke server. Pastikan Docker/Backend berjalan.');
      } else {
        setError(err.message || 'Terjadi kesalahan saat login. Coba lagi nanti.');
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="login-container">
      {/* Left Side - Welcome Section */}
      <div className="login-branding">
        {/* Parallax Shapes */}
        <div className="parallax-shape shape-1"></div>
        <div className="parallax-shape shape-2"></div>
        <div className="parallax-shape shape-3"></div>

        <div className="welcome-container">
          <div className="brand-logo">
            <div className="logo-circle">
              <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <path d="M22 10v6M2 10l10-5 10 5-10 5z"/>
                <path d="M6 12v5c3 3 9 3 12 0v-5"/>
              </svg>
            </div>
            <span className="brand-name">SMK Taruna Jaya Prawira Tuban</span>
          </div>
          
          <div className="hero-content">
            <div className="hero-badge">Admin Portal</div>
            <h1 className="hero-title">
              Sistem Informasi<br/>
              <span className="text-highlight">Pembayaran SPP</span>
            </h1>
            
            <p className="hero-desc">
              Platform digital terpadu untuk pengelolaan administrasi keuangan sekolah yang lebih efisien, transparan, dan akuntabel.
            </p>
            
            <div className="stats-row">
              <div className="stat-item">
                <span className="stat-value">100%</span>
                <span className="stat-label">Digital</span>
              </div>
              <div className="stat-divider"></div>
              <div className="stat-item">
                <span className="stat-value">24/7</span>
                <span className="stat-label">Akses</span>
              </div>
              <div className="stat-divider"></div>
              <div className="stat-item">
                <span className="stat-value">Real</span>
                <span className="stat-label">Time</span>
              </div>
            </div>

            <div className="feature-list">
              <div className="feature-row">
                <div className="check-circle">✓</div>
                <span>Dashboard Monitoring Terpusat</span>
              </div>
              <div className="feature-row">
                <div className="check-circle">✓</div>
                <span>Pencatatan Transaksi Otomatis</span>
              </div>
              <div className="feature-row">
                <div className="check-circle">✓</div>
                <span>Laporan Keuangan Lengkap</span>
              </div>
            </div>
          </div>
          
          <div className="hero-footer">
            <p>© 2025 SMK Taruna Jaya Prawira Tuban</p>
          </div>
        </div>
      </div>

      {/* Right Side - Login Form */}
      <div className="login-card">
        {/* Right Side Floating Shapes */}
        <div className="parallax-shape shape-4"></div>
        <div className="parallax-shape shape-5"></div>
        <div className="parallax-shape shape-6"></div>

        <div className="login-form-container">
          <div className="login-header">
            <h2>Masuk ke Dashboard</h2>
            <p>Silakan masuk dengan akun admin Anda</p>
          </div>
          
          <form onSubmit={handleLogin} className="login-form">
            <div className="input-group">
              <label htmlFor="email">Email</label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@sekolah.sch.id"
                required
              />
            </div>
            
            <div className="input-group">
              <label htmlFor="password">Password</label>
              <div className="password-input-wrapper">
                <input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Masukkan password"
                  required
                />
                <button
                  type="button"
                  className="password-toggle"
                  onClick={() => setShowPassword(!showPassword)}
                  aria-label={showPassword ? 'Sembunyikan password' : 'Tampilkan password'}
                >
                  {showPassword ? (
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/>
                      <line x1="1" y1="1" x2="23" y2="23"/>
                    </svg>
                  ) : (
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                      <circle cx="12" cy="12" r="3"/>
                    </svg>
                  )}
                </button>
              </div>
            </div>
            
            <div className="form-options">
              <label className="checkbox-label">
                <input type="checkbox" />
                <span className="checkmark"></span>
                Ingat saya
              </label>
              <a href="#" className="forgot-link">Lupa password?</a>
            </div>
            
            {error && <div className="error-message">{error}</div>}
            
            <button type="submit" className="login-button" disabled={isLoading}>
              {isLoading ? 'Memproses...' : 'Masuk Dashboard'}
            </button>
          </form>
          
          <div className="login-footer">
            <p>&copy; 2025 SMK Taruna Jaya Prawira Tuban</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Login;
