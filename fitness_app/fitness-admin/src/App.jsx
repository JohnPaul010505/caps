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
    <div className="flex items-center justify-center h-screen bg-gray-100 gap-2 text-gray-400 text-sm">
      <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none">
        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8z" />
      </svg>
      Loading...
    </div>
  )
}

// Blocks unauthenticated users from accessing protected pages.
// Also blocks URL shortcuts like typing /dashboard directly — redirects to /login.
function ProtectedRoute({ children }) {
  const { user, loading } = useAuth()
  if (loading) return <Spinner />           // wait for session check to finish
  if (!user)   return <Navigate to="/login" replace />  // not logged in → login
  return children
}

// Prevents already-logged-in users from seeing the login page.
function PublicRoute({ children }) {
  const { user, loading } = useAuth()
  if (loading) return <Spinner />           // wait — don't flash login then redirect
  if (user)    return <Navigate to="/dashboard" replace />  // already logged in
  return children
}

export default function App() {
  return (
    // AuthProvider is outermost — getSession() runs ONCE here and is shared
    // to every component via useAuth(). Pages never call getSession() themselves.
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          {/* / and any unknown URL → always go to login first */}
          <Route path="/"  element={<Navigate to="/login" replace />} />
          <Route path="*"  element={<Navigate to="/login" replace />} />

          {/* Public — redirect to dashboard if already logged in */}
          <Route path="/login"    element={<PublicRoute><Login /></PublicRoute>} />
          <Route path="/register" element={<Register />} />
          <Route path="/qrcode"   element={<QRCode />} />

          {/* Protected — redirect to login if not authenticated */}
          <Route path="/dashboard" element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
          <Route path="/members"   element={<ProtectedRoute><Members /></ProtectedRoute>} />
          <Route path="/trainers"  element={<ProtectedRoute><Trainers /></ProtectedRoute>} />
          <Route path="/approvals" element={<ProtectedRoute><Approvals /></ProtectedRoute>} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}