import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { logout } from '../../api/auth';
import './Layout.css';

const Sidebar = () => {
  const navigate = useNavigate();
  const location = useLocation();

  // Get user data safely
  let user = { name: 'Admin', email: 'admin@sekolah.sch.id' };
  try {
    const userData = localStorage.getItem('user');
    if (userData) user = JSON.parse(userData);
  } catch (e) {}

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  const menuItems = [
    { path: '/dashboard', label: 'Dashboard', icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="3" width="7" height="7" rx="1"></rect><rect x="14" y="3" width="7" height="7" rx="1"></rect><rect x="14" y="14" width="7" height="7" rx="1"></rect><rect x="3" y="14" width="7" height="7" rx="1"></rect></svg> },
    { path: '/students', label: 'Data Siswa', icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg> },
    { path: '/classes', label: 'Data Kelas', icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"></path><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"></path></svg> },
    { path: '/payments', label: 'Transaksi SPP', icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"></rect><line x1="1" y1="10" x2="23" y2="10"></line></svg> },
    { path: '/content', label: 'Kelola Konten', icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg> },
    { path: '/reports', label: 'Laporan', icon: <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21.21 15.89A10 10 0 1 1 8 2.83"></path><path d="M22 12A10 10 0 0 0 12 2v10z"></path></svg> },
  ];

  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <div className="sidebar-logo-icon">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M22 10v6M2 10l10-5 10 5-10 5z"/>
            <path d="M6 12v5c3 3 9 3 12 0v-5"/>
          </svg>
        </div>
        <div className="sidebar-title">
          <span>SPP Admin</span>
          <small>Management System</small>
        </div>
      </div>

      <nav className="sidebar-nav">
        <div className="nav-section-title">Menu Utama</div>
        {menuItems.slice(0, 5).map((item) => (
          <a 
            key={item.path} 
            href="#" 
            className={`nav-item ${location.pathname === item.path ? 'active' : ''}`}
            onClick={(e) => { e.preventDefault(); navigate(item.path); }}
          >
            <span className="nav-icon">{item.icon}</span>
            <span className="nav-label">{item.label}</span>
          </a>
        ))}
        
        <div className="nav-section-title">Lainnya</div>
        {menuItems.slice(5).map((item) => (
          <a 
            key={item.path} 
            href="#" 
            className={`nav-item ${location.pathname === item.path ? 'active' : ''}`}
            onClick={(e) => { e.preventDefault(); navigate(item.path); }}
          >
            <span className="nav-icon">{item.icon}</span>
            <span className="nav-label">{item.label}</span>
          </a>
        ))}
      </nav>

      <div className="sidebar-footer">
        <div className="user-profile">
          <div className="user-avatar">
            {(user.name || 'A').charAt(0).toUpperCase()}
          </div>
          <div className="user-info">
            <div className="user-name">{user.name || 'Admin'}</div>
            <div className="user-role">Administrator</div>
          </div>
        </div>
        <button onClick={handleLogout} className="logout-btn">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
          <span>Keluar</span>
        </button>
      </div>
    </aside>
  );
};

export default Sidebar;
