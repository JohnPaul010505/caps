import { useState } from 'react'
import { NavLink, useNavigate } from 'react-router-dom'
import { useAuth } from '../../hooks/useAuth'

const mainLinks = [
  { to: '/dashboard', icon: (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/>
      <rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/>
    </svg>
  ), label: 'Dashboard' },
  { to: '/members', icon: (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
      <circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>
    </svg>
  ), label: 'Members' },
  { to: '/trainers', icon: (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="8" r="4"/><path d="M20 21a8 8 0 1 0-16 0"/>
    </svg>
  ), label: 'Trainers' },
  { to: '/approvals', icon: (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="9 11 12 14 22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>
    </svg>
  ), label: 'Approvals' },
  { to: '/qrcode', icon: (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="5" height="5"/><rect x="16" y="3" width="5" height="5"/>
      <rect x="3" y="16" width="5" height="5"/><path d="M21 16h-3a2 2 0 0 0-2 2v3"/>
      <path d="M21 21v.01"/><path d="M12 7v3a2 2 0 0 1-2 2H7"/><path d="M3 12h.01"/>
      <path d="M12 3h.01"/><path d="M12 16v.01"/><path d="M16 12h1"/><path d="M21 12v.01"/>
      <path d="M12 21v-1"/>
    </svg>
  ), label: 'QR Register' },
]

const sidebarStyle = {
  background: '#13131e',
  borderRight: '1px solid rgba(255,255,255,0.06)',
  width: '220px',
  minHeight: '100vh',
  display: 'flex',
  flexDirection: 'column',
}

export default function Sidebar() {
  const { user, signOut }             = useAuth()
  const navigate                      = useNavigate()
  const [showConfirm, setShowConfirm] = useState(false)

  async function handleLogout() {
    navigate('/login', { replace: true })
    try { await signOut() } catch { /* ignore */ }
  }

  const initials = user?.email?.slice(0, 2).toUpperCase() ?? 'AD'

  return (
    <>
      <aside style={sidebarStyle}>
        {/* Logo */}
        <div style={{ padding: '24px 20px 20px', borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div style={{
              width: '32px', height: '32px', borderRadius: '8px',
              background: 'linear-gradient(135deg, #7c3aed, #a855f7)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: '16px'
            }}>⚡</div>
            <span style={{ fontWeight: '700', fontSize: '17px', color: '#fff', letterSpacing: '-0.3px' }}>FitTrack</span>
          </div>
        </div>

        {/* Nav */}
        <nav style={{ flex: 1, padding: '20px 12px', display: 'flex', flexDirection: 'column', gap: '4px' }}>
          <p style={{ fontSize: '10px', fontWeight: '600', color: '#4a4a6a', letterSpacing: '1px', marginBottom: '8px', paddingLeft: '8px' }}>MAIN</p>
          {mainLinks.map(link => (
            <NavLink
              key={link.to}
              to={link.to}
              style={({ isActive }) => ({
                display: 'flex', alignItems: 'center', gap: '10px',
                padding: '9px 12px', borderRadius: '8px',
                fontSize: '13.5px', fontWeight: '500',
                textDecoration: 'none', transition: 'all 0.15s',
                color: isActive ? '#fff' : '#7070a0',
                background: isActive ? 'linear-gradient(135deg, rgba(124,58,237,0.25), rgba(168,85,247,0.15))' : 'transparent',
                borderLeft: isActive ? '2px solid #a855f7' : '2px solid transparent',
              })}
            >
              {link.icon}
              {link.label}
            </NavLink>
          ))}
        </nav>

        {/* User */}
        <div style={{ padding: '16px 12px', borderTop: '1px solid rgba(255,255,255,0.06)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '8px', borderRadius: '8px', marginBottom: '8px' }}>
            <div style={{
              width: '34px', height: '34px', borderRadius: '50%',
              background: 'linear-gradient(135deg, #7c3aed, #a855f7)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: '12px', fontWeight: '700', color: '#fff', flexShrink: 0
            }}>{initials}</div>
            <div>
              <p style={{ fontSize: '13px', fontWeight: '600', color: '#e2e2f0', lineHeight: 1.2 }}>Admin</p>
              <p style={{ fontSize: '11px', color: '#5050780' }}>Super user</p>
            </div>
          </div>
          <button
            onClick={() => setShowConfirm(true)}
            style={{
              width: '100%', display: 'flex', alignItems: 'center', gap: '8px',
              padding: '8px 12px', borderRadius: '8px', border: 'none',
              background: 'transparent', color: '#5a5a8a', fontSize: '13px',
              cursor: 'pointer', transition: 'all 0.15s',
            }}
            onMouseEnter={e => { e.currentTarget.style.background = 'rgba(239,68,68,0.1)'; e.currentTarget.style.color = '#ef4444' }}
            onMouseLeave={e => { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.color = '#5a5a8a' }}
          >
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/>
              <polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/>
            </svg>
            Logout
          </button>
        </div>
      </aside>

      {showConfirm && (
        <div style={{
          position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50
        }}>
          <div style={{
            background: '#1a1a2e', border: '1px solid rgba(255,255,255,0.1)',
            borderRadius: '16px', padding: '32px', width: '320px', textAlign: 'center'
          }}>
            <div style={{ fontSize: '36px', marginBottom: '12px' }}>👋</div>
            <h3 style={{ color: '#e2e2f0', fontWeight: '700', marginBottom: '6px' }}>Log out?</h3>
            <p style={{ color: '#6060a0', fontSize: '13px', marginBottom: '24px' }}>You will be returned to the login screen.</p>
            <div style={{ display: 'flex', gap: '10px' }}>
              <button onClick={() => setShowConfirm(false)} style={{
                flex: 1, padding: '10px', borderRadius: '10px', border: '1px solid rgba(255,255,255,0.1)',
                background: 'rgba(255,255,255,0.05)', color: '#a0a0c0', cursor: 'pointer', fontWeight: '600', fontSize: '13px'
              }}>Cancel</button>
              <button onClick={handleLogout} style={{
                flex: 1, padding: '10px', borderRadius: '10px', border: 'none',
                background: 'linear-gradient(135deg, #ef4444, #dc2626)', color: '#fff',
                cursor: 'pointer', fontWeight: '600', fontSize: '13px'
              }}>Yes, log out</button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}