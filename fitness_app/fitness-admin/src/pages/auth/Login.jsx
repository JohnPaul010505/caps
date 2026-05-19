import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../../hooks/useAuth'

export default function Login() {
  const { signIn }              = useAuth()
  const navigate                = useNavigate()
  const [email,    setEmail]    = useState('')
  const [password, setPassword] = useState('')
  const [error,    setError]    = useState('')
  const [loading,  setLoading]  = useState(false)
  const [showPw,   setShowPw]   = useState(false)

  async function handleLogin(e) {
    e.preventDefault()
    setLoading(true)
    setError('')

    const timeoutId = setTimeout(() => {
      setLoading(false)
      setError('Request timed out. Check your connection and try again.')
    }, 10000)

    try {
      const { error } = await signIn(email, password)
      clearTimeout(timeoutId)
      if (error) {
        setError(error.message || 'Invalid email or password.')
        setLoading(false)
      } else {
        navigate('/dashboard', { replace: true })
      }
    } catch {
      clearTimeout(timeoutId)
      setError('Network error. Please try again.')
      setLoading(false)
    }
  }

  return (
    <div style={{
      minHeight: '100vh',
      background: '#0b0d14',
      display: 'flex',
      fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
      position: 'relative',
      overflow: 'hidden',
    }}>
      {/* Decorative grid lines */}
      <div style={{
        position: 'absolute', inset: 0, pointerEvents: 'none',
        backgroundImage: `
          linear-gradient(rgba(255,255,255,0.018) 1px, transparent 1px),
          linear-gradient(90deg, rgba(255,255,255,0.018) 1px, transparent 1px)
        `,
        backgroundSize: '60px 60px',
      }} />

      {/* Left glow */}
      <div style={{
        position: 'absolute', top: '20%', left: '-10%',
        width: '500px', height: '500px', borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(37,99,235,0.12) 0%, transparent 65%)',
        pointerEvents: 'none',
      }} />

      {/* Right glow */}
      <div style={{
        position: 'absolute', bottom: '10%', right: '-5%',
        width: '400px', height: '400px', borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(124,58,237,0.08) 0%, transparent 65%)',
        pointerEvents: 'none',
      }} />

      {/* Left panel — branding */}
      <div style={{
        flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center',
        padding: '60px 80px', position: 'relative', zIndex: 1,
      }}>
        {/* Logo */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '64px' }}>
          <div style={{
            width: '40px', height: '40px', borderRadius: '10px',
            background: 'linear-gradient(135deg, #1d4ed8, #3b82f6)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 4px 16px rgba(59,130,246,0.4)',
          }}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/>
            </svg>
          </div>
          <div>
            <p style={{ fontSize: '16px', fontWeight: '800', color: '#f0f2f8', margin: 0, letterSpacing: '-0.2px' }}>FitTrack</p>
            <p style={{ fontSize: '9px', fontWeight: '700', color: '#2d3748', margin: 0, letterSpacing: '1.5px', textTransform: 'uppercase' }}>Elite Performance</p>
          </div>
        </div>

        <h1 style={{ fontSize: '42px', fontWeight: '900', color: '#f0f2f8', margin: '0 0 16px', lineHeight: 1.1, letterSpacing: '-1px', maxWidth: '440px' }}>
          Manage your gym,<br />
          <span style={{ background: 'linear-gradient(135deg, #3b82f6, #60a5fa)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text' }}>
            effortlessly.
          </span>
        </h1>
        <p style={{ fontSize: '15px', color: '#4a5568', maxWidth: '380px', lineHeight: 1.7, margin: 0 }}>
          A complete fitness management system for tracking members, trainers, and memberships in real time.
        </p>

        {/* Feature pills */}
        <div style={{ display: 'flex', gap: '8px', marginTop: '40px', flexWrap: 'wrap' }}>
          {['Member Management', 'Trainer Assignment', 'QR Registration', 'Live Approvals'].map(f => (
            <span key={f} style={{
              padding: '6px 12px', borderRadius: '6px', fontSize: '11.5px', fontWeight: '600',
              background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.07)',
              color: '#4a5568',
            }}>{f}</span>
          ))}
        </div>
      </div>

      {/* Vertical divider */}
      <div style={{
        width: '1px', background: 'rgba(255,255,255,0.05)',
        margin: '60px 0', flexShrink: 0, position: 'relative', zIndex: 1,
      }} />

      {/* Right panel — login form */}
      <div style={{
        width: '460px', flexShrink: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        padding: '40px 56px', position: 'relative', zIndex: 1,
      }}>
        <div style={{ width: '100%' }}>
          <div style={{ marginBottom: '32px' }}>
            <h2 style={{ fontSize: '22px', fontWeight: '800', color: '#e2e8f0', margin: '0 0 6px', letterSpacing: '-0.3px' }}>Welcome back</h2>
            <p style={{ fontSize: '13px', color: '#4a5568', margin: 0 }}>Sign in to your admin account</p>
          </div>

          {/* Error */}
          {error && (
            <div style={{
              background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.2)',
              borderRadius: '10px', padding: '11px 14px', fontSize: '12.5px', color: '#f87171',
              marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '8px',
            }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0 }}>
                <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
              </svg>
              {error}
            </div>
          )}

          <form onSubmit={handleLogin}>
            {/* Email */}
            <div style={{ marginBottom: '14px' }}>
              <label style={{ display: 'block', fontSize: '10.5px', fontWeight: '700', color: '#2d3748', letterSpacing: '0.8px', marginBottom: '8px', textTransform: 'uppercase' }}>Email Address</label>
              <input
                type="email" value={email} onChange={e => setEmail(e.target.value)}
                placeholder="admin@fittrack.com" required disabled={loading}
                style={{
                  width: '100%', boxSizing: 'border-box',
                  background: 'rgba(255,255,255,0.04)',
                  border: '1px solid rgba(255,255,255,0.08)',
                  borderRadius: '10px', padding: '12px 14px',
                  fontSize: '13.5px', color: '#e2e8f0', outline: 'none',
                  transition: 'border-color 0.2s', opacity: loading ? 0.6 : 1,
                }}
                onFocus={e => e.target.style.borderColor = 'rgba(59,130,246,0.5)'}
                onBlur={e  => e.target.style.borderColor = 'rgba(255,255,255,0.08)'}
              />
            </div>

            {/* Password */}
            <div style={{ marginBottom: '28px' }}>
              <label style={{ display: 'block', fontSize: '10.5px', fontWeight: '700', color: '#2d3748', letterSpacing: '0.8px', marginBottom: '8px', textTransform: 'uppercase' }}>Password</label>
              <div style={{ position: 'relative' }}>
                <input
                  type={showPw ? 'text' : 'password'} value={password}
                  onChange={e => setPassword(e.target.value)}
                  placeholder="••••••••" required disabled={loading}
                  style={{
                    width: '100%', boxSizing: 'border-box',
                    background: 'rgba(255,255,255,0.04)',
                    border: '1px solid rgba(255,255,255,0.08)',
                    borderRadius: '10px', padding: '12px 14px', paddingRight: '46px',
                    fontSize: '13.5px', color: '#e2e8f0', outline: 'none',
                    transition: 'border-color 0.2s', opacity: loading ? 0.6 : 1,
                  }}
                  onFocus={e => e.target.style.borderColor = 'rgba(59,130,246,0.5)'}
                  onBlur={e  => e.target.style.borderColor = 'rgba(255,255,255,0.08)'}
                />
                <button type="button" onClick={() => setShowPw(!showPw)} style={{
                  position: 'absolute', right: '13px', top: '50%', transform: 'translateY(-50%)',
                  background: 'none', border: 'none', cursor: 'pointer', color: '#4a5568', padding: 0,
                }}>
                  {showPw
                    ? <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                    : <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                  }
                </button>
              </div>
            </div>

            <button type="submit" disabled={loading} style={{
              width: '100%', padding: '13px',
              background: loading ? 'rgba(59,130,246,0.45)' : 'linear-gradient(135deg, #1d4ed8, #3b82f6)',
              color: '#fff', border: 'none', borderRadius: '10px',
              fontSize: '14px', fontWeight: '700',
              cursor: loading ? 'not-allowed' : 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px',
              boxShadow: loading ? 'none' : '0 4px 16px rgba(59,130,246,0.4)',
              transition: 'all 0.2s',
            }}>
              {loading ? (
                <>
                  <svg style={{ animation: 'spin 1s linear infinite' }} width="15" height="15" viewBox="0 0 24 24" fill="none">
                    <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
                    <circle opacity=".25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
                    <path opacity=".75" fill="currentColor" d="M4 12a8 8 0 018-8v8z"/>
                  </svg>
                  Signing in…
                </>
              ) : (
                <>
                  Sign In
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>
                </>
              )}
            </button>
          </form>

          <p style={{ textAlign: 'center', fontSize: '11.5px', color: '#2d3748', marginTop: '28px' }}>
            Admin access only · FitTrack v1.0
          </p>
        </div>
      </div>
    </div>
  )
}