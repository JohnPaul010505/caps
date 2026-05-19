import { useLocation } from 'react-router-dom'
import Sidebar from './Sidebar'
import { useAuth } from '../../hooks/useAuth'

const PAGE_TITLES = {
  '/dashboard': { label: 'Dashboard',       crumb: null },
  '/members':   { label: 'Members',         crumb: null },
  '/trainers':  { label: 'Trainer Management', crumb: 'Trainers' },
  '/approvals': { label: 'Approvals',       crumb: null },
  '/qrcode':    { label: 'QR Registration', crumb: 'Register' },
}

export default function Layout({ children }) {
  const location = useLocation()
  const { user } = useAuth()
  const page = PAGE_TITLES[location.pathname] ?? { label: 'FitTrack', crumb: null }
  const initials = user?.email?.slice(0, 2).toUpperCase() ?? 'AD'

  return (
    <div style={{ display: 'flex', minHeight: '100vh', background: '#0b0d14', color: '#e8eaf0', fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif" }}>
      <Sidebar />

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        {/* Top Header Bar */}
        <header style={{
          height: '60px', display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '0 28px', borderBottom: '1px solid rgba(255,255,255,0.05)',
          background: 'rgba(11,13,20,0.95)', backdropFilter: 'blur(12px)',
          position: 'sticky', top: 0, zIndex: 20, flexShrink: 0,
        }}>
          {/* Breadcrumb */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span style={{ fontSize: '13px', color: '#4a5568', fontWeight: '500' }}>FitTrack</span>
            <span style={{ color: '#2d3748', fontSize: '13px' }}>/</span>
            <span style={{ fontSize: '13px', fontWeight: '600', color: '#a0aec0' }}>{page.label}</span>
          </div>

          {/* Right Controls */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            {/* Bell */}
            <button style={{ width: '36px', height: '36px', borderRadius: '8px', background: 'transparent', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#4a5568', transition: 'all 0.15s' }}
              onMouseEnter={e => { e.currentTarget.style.background = 'rgba(255,255,255,0.05)'; e.currentTarget.style.color = '#a0aec0' }}
              onMouseLeave={e => { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.color = '#4a5568' }}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/>
              </svg>
            </button>

            {/* Settings */}
            <button style={{ width: '36px', height: '36px', borderRadius: '8px', background: 'transparent', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#4a5568', transition: 'all 0.15s' }}
              onMouseEnter={e => { e.currentTarget.style.background = 'rgba(255,255,255,0.05)'; e.currentTarget.style.color = '#a0aec0' }}
              onMouseLeave={e => { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.color = '#4a5568' }}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/>
              </svg>
            </button>

            {/* Divider */}
            <div style={{ width: '1px', height: '20px', background: 'rgba(255,255,255,0.07)', margin: '0 4px' }} />

            {/* User Chip */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '5px 10px', borderRadius: '10px', background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.06)', cursor: 'default' }}>
              <div style={{ textAlign: 'right' }}>
                <p style={{ fontSize: '11px', fontWeight: '700', color: '#a0aec0', margin: 0, letterSpacing: '0.3px' }}>ADMIN</p>
                <p style={{ fontSize: '10px', color: '#4a5568', margin: 0 }}>System Access</p>
              </div>
              <div style={{
                width: '30px', height: '30px', borderRadius: '8px',
                background: 'linear-gradient(135deg, #2563eb, #3b82f6)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: '11px', fontWeight: '800', color: '#fff',
              }}>{initials}</div>
            </div>
          </div>
        </header>

        {/* Page Content */}
        <main style={{ flex: 1, padding: '28px 32px', overflowY: 'auto' }}>
          {children}
        </main>
      </div>
    </div>
  )
}