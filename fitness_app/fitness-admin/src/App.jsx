import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider } from './context/AuthContext'
import { useAuth } from './hooks/useAuth'
import Login     from './pages/auth/Login'
import Dashboard from './pages/dashboard/Dashboard'
import Members   from './pages/members/Members'
import Trainers  from './pages/trainers/Trainers'
import Approvals from './pages/approvals/Approvals'
import QRCode    from './pages/qr/QRCode'
import Register  from './pages/register/Register'

function Spinner() {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      height: '100vh', background: '#0d0d14', gap: '8px',
      color: '#5a5a8a', fontSize: '14px',
    }}>
      <svg style={{ animation: 'spin 1s linear infinite' }} width="16" height="16" viewBox="0 0 24 24" fill="none">
        <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
        <circle opacity=".25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
        <path opacity=".75" fill="currentColor" d="M4 12a8 8 0 018-8v8z" />
      </svg>
      Loading…
    </div>
  )
}

// Blocks unauthenticated users. Also blocks direct URL access — redirects to /login.
function ProtectedRoute({ children }) {
  const { user, loading } = useAuth()
  if (loading) return <Spinner />
  if (!user)   return <Navigate to="/login" replace />
  return children
}

// Prevents already-logged-in admins from seeing the login page.
function PublicRoute({ children }) {
  const { user, loading } = useAuth()
  if (loading) return <Spinner />
  if (user)    return <Navigate to="/dashboard" replace />
  return children
}

export default function App() {
  return (
    // AuthProvider is outermost — getSession() runs ONCE here and is shared
    // to every component via useAuth(). Pages never call getSession() themselves.
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          {/* / and unknown URLs → always go to login first */}
          <Route path="/"  element={<Navigate to="/login" replace />} />
          <Route path="*"  element={<Navigate to="/login" replace />} />

          {/* Public — redirect to dashboard if already logged in */}
          <Route path="/login"    element={<PublicRoute><Login /></PublicRoute>} />

          {/* Member self-registration via QR scan (public — no auth needed) */}
          <Route path="/register" element={<Register />} />

          {/* Protected — redirect to /login if not authenticated */}
          <Route path="/dashboard" element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
          <Route path="/members"   element={<ProtectedRoute><Members /></ProtectedRoute>} />
          <Route path="/trainers"  element={<ProtectedRoute><Trainers /></ProtectedRoute>} />
          <Route path="/approvals" element={<ProtectedRoute><Approvals /></ProtectedRoute>} />
          <Route path="/qrcode"    element={<ProtectedRoute><QRCode /></ProtectedRoute>} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}