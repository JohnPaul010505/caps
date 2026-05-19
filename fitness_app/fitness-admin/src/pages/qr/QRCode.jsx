import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '../../services/supabase'
import Layout from '../../components/layout/Layout'

const REGISTRATION_URL = `${window.location.origin}/register`

const GOALS = ['Weight Loss','Muscle Gain','General Fitness','Endurance','Flexibility','Rehabilitation']
const MEMBERSHIPS = [
  { label: 'Basic – ₱999/mo',    value: 'Basic'     },
  { label: 'Quarterly – ₱2,499', value: 'Quarterly' },
  { label: '6 Months – ₱4,499',  value: '6 Months'  },
  { label: 'Annual – ₱7,999',    value: 'Annual'    },
]

const EMPTY = {
  full_name: '', age: '', gender: '', email: '',
  contact_number: '', height: '', weight: '',
  goal: 'Weight Loss', membership_type: 'Basic',
  wants_trainer: false, emergency_contact: '', auto_approve: false,
}

function Lbl({ children }) {
  return <label style={{ display: 'block', fontSize: '10px', fontWeight: '700', color: '#2d3748', letterSpacing: '0.8px', marginBottom: '6px', textTransform: 'uppercase' }}>{children}</label>
}

const inp = (focused) => ({
  width: '100%', boxSizing: 'border-box',
  background: focused ? 'rgba(59,130,246,0.05)' : 'rgba(255,255,255,0.04)',
  border: `1px solid ${focused ? 'rgba(59,130,246,0.4)' : 'rgba(255,255,255,0.07)'}`,
  borderRadius: '8px', padding: '9px 12px',
  fontSize: '12.5px', color: '#e2e8f0', outline: 'none', transition: 'all 0.18s',
})

const sel = (focused) => ({
  width: '100%', boxSizing: 'border-box',
  backgroundColor: focused ? 'rgba(59,130,246,0.05)' : 'rgba(255,255,255,0.04)',
  backgroundImage: `url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='11' height='11' viewBox='0 0 24 24' fill='none' stroke='%236b7280' stroke-width='2'%3E%3Cpolyline points='6 9 12 15 18 9'/%3E%3C/svg%3E")`,
  backgroundRepeat: 'no-repeat', backgroundPosition: 'right 11px center',
  border: `1px solid ${focused ? 'rgba(59,130,246,0.4)' : 'rgba(255,255,255,0.07)'}`,
  borderRadius: '8px', padding: '9px 12px', paddingRight: '30px',
  fontSize: '12.5px', color: '#e2e8f0', outline: 'none', transition: 'all 0.18s',
  cursor: 'pointer', appearance: 'none',
})

export default function QRCodePage() {
  const navigate      = useNavigate()
  const [qrKey,  setQrKey]  = useState(0)
  const [form,   setForm]   = useState(EMPTY)
  const [focus,  setFocus]  = useState('')
  const [saving, setSaving] = useState(false)
  const [err,    setErr]    = useState('')

  const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=${encodeURIComponent(REGISTRATION_URL)}&v=${qrKey}`

  function set(k, v) { setForm(p => ({ ...p, [k]: v })); setErr('') }
  function fp(n) { return { onFocus: () => setFocus(n), onBlur: () => setFocus('') } }

  async function handleDownload() {
    try {
      const res  = await fetch(qrUrl)
      const blob = await res.blob()
      const url  = URL.createObjectURL(blob)
      const a    = document.createElement('a')
      a.href = url; a.download = 'fittrack-qr.png'; a.click()
      URL.revokeObjectURL(url)
    } catch { /* silent */ }
  }

  async function handleSubmit(e) {
    e.preventDefault()
    if (!form.full_name.trim()) { setErr('Full name is required.'); return }
    setSaving(true); setErr('')
    try {
      let expiration_date = null
      if (form.auto_approve) {
        const months = form.membership_type === 'Quarterly' ? 3 : form.membership_type === '6 Months' ? 6 : form.membership_type === 'Annual' ? 12 : 1
        const exp = new Date(); exp.setMonth(exp.getMonth() + months)
        expiration_date = exp.toISOString().split('T')[0]
      }
      const payload = {
        full_name: form.full_name.trim(),
        age: form.age ? parseInt(form.age) : null,
        gender: form.gender || null,
        email: form.email || null,
        contact_number: form.contact_number || null,
        height: form.height ? parseFloat(form.height) : null,
        weight: form.weight ? parseFloat(form.weight) : null,
        goal: form.goal || null,
        membership_type: form.membership_type,
        wants_trainer: form.wants_trainer,
        emergency_contact: form.emergency_contact || null,
        membership_status: form.auto_approve ? 'active' : 'pending',
        expiration_date,
      }
      const { error: insertErr } = await supabase.from('members').insert(payload)
      if (insertErr) { setErr(insertErr.message || 'Failed to save member.'); setSaving(false); return }
      setSaving(false)
      navigate(form.auto_approve ? '/members' : '/approvals')
    } catch (e) { setErr(e?.message || 'Unexpected error. Please try again.'); setSaving(false) }
  }

  const cardStyle = { background: '#141824', border: '1px solid rgba(255,255,255,0.06)', borderRadius: '12px' }

  return (
    <Layout>
      <div style={{ marginBottom: '22px' }}>
        <h1 style={{ fontSize: '22px', fontWeight: '800', color: '#f0f2f8', margin: '0 0 4px', letterSpacing: '-0.3px' }}>QR Registration</h1>
        <p style={{ color: '#4a5568', fontSize: '13px', margin: 0 }}>Generate a QR code for new member self-registration, or register manually</p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.7fr', gap: '18px', alignItems: 'start' }}>

        {/* QR Panel */}
        <div style={{ ...cardStyle, padding: '28px 24px', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '18px' }}>
          <div>
            <p style={{ fontSize: '13px', fontWeight: '700', color: '#8892a4', textAlign: 'center', margin: '0 0 16px' }}>Member Self-Registration</p>
            <div style={{ background: '#fff', borderRadius: '10px', padding: '14px', display: 'inline-block', boxShadow: '0 4px 20px rgba(0,0,0,0.3)' }}>
              <img src={qrUrl} alt="QR Code" width={180} height={180} style={{ display: 'block', borderRadius: '4px' }} />
            </div>
          </div>

          <div style={{ width: '100%', padding: '12px 14px', background: 'rgba(255,255,255,0.02)', border: '1px solid rgba(255,255,255,0.05)', borderRadius: '8px' }}>
            <p style={{ fontSize: '10px', fontWeight: '700', color: '#2d3748', letterSpacing: '0.8px', margin: '0 0 4px', textTransform: 'uppercase' }}>Registration URL</p>
            <p style={{ fontSize: '10.5px', color: '#4a5568', margin: 0, wordBreak: 'break-all', lineHeight: 1.5 }}>{REGISTRATION_URL}</p>
          </div>

          <div style={{ display: 'flex', gap: '8px', width: '100%' }}>
            <button onClick={handleDownload} style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px', padding: '9px', borderRadius: '9px', background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.07)', color: '#718096', fontSize: '12.5px', fontWeight: '600', cursor: 'pointer', transition: 'all 0.15s' }}
              onMouseEnter={e => e.currentTarget.style.background = 'rgba(255,255,255,0.07)'} onMouseLeave={e => e.currentTarget.style.background = 'rgba(255,255,255,0.04)'}>
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
              Download
            </button>
            <button onClick={() => setQrKey(k => k + 1)} style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '6px', padding: '9px', borderRadius: '9px', background: 'rgba(34,197,94,0.1)', border: '1px solid rgba(34,197,94,0.2)', color: '#22c55e', fontSize: '12.5px', fontWeight: '600', cursor: 'pointer', transition: 'all 0.15s' }}
              onMouseEnter={e => e.currentTarget.style.background = 'rgba(34,197,94,0.18)'} onMouseLeave={e => e.currentTarget.style.background = 'rgba(34,197,94,0.1)'}>
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="23 4 23 10 17 10"/><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/></svg>
              Refresh
            </button>
          </div>

          {/* Scan hint */}
          <div style={{ width: '100%', background: 'rgba(59,130,246,0.06)', border: '1px solid rgba(59,130,246,0.14)', borderRadius: '9px', padding: '11px 14px', display: 'flex', gap: '9px', alignItems: 'flex-start' }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#60a5fa" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0, marginTop: '1px' }}><circle cx="12" cy="12" r="10"/><line x1="12" y1="17" x2="12" y2="11"/><line x1="12" y1="7" x2="12.01" y2="7"/></svg>
            <p style={{ fontSize: '11.5px', color: '#60a5fa', margin: 0, lineHeight: 1.5 }}>Members can scan this QR code with their phone to fill out the registration form themselves.</p>
          </div>
        </div>

        {/* Form Panel */}
        <div style={{ ...cardStyle, padding: '24px 26px' }}>
          <div style={{ marginBottom: '20px' }}>
            <p style={{ fontSize: '14px', fontWeight: '700', color: '#c8d0e0', margin: '0 0 4px' }}>Register Member Manually</p>
            <p style={{ fontSize: '11.5px', color: '#4a5568', margin: 0 }}>Fill this form on behalf of a member who cannot scan the QR code</p>
          </div>

          {err && (
            <div style={{ background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.2)', borderRadius: '9px', padding: '10px 14px', marginBottom: '14px', color: '#f87171', fontSize: '12.5px', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink: 0 }}><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              {err}
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div style={{ display: 'grid', gridTemplateColumns: '1.5fr 1fr', gap: '10px', marginBottom: '10px' }}>
              <div><Lbl>Full Name *</Lbl><input type="text" placeholder="Juan Dela Cruz" value={form.full_name} onChange={e => set('full_name', e.target.value)} style={inp(focus === 'full_name')} {...fp('full_name')} required /></div>
              <div><Lbl>Age</Lbl><input type="number" placeholder="28" min="10" max="100" value={form.age} onChange={e => set('age', e.target.value)} style={inp(focus === 'age')} {...fp('age')} /></div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginBottom: '10px' }}>
              <div><Lbl>Gender</Lbl>
                <select value={form.gender} onChange={e => set('gender', e.target.value)} style={sel(focus === 'gender')} {...fp('gender')}>
                  <option value="">Select gender</option>
                  <option>Male</option><option>Female</option><option>Other</option>
                </select>
              </div>
              <div><Lbl>Email</Lbl><input type="email" placeholder="juan@email.com" value={form.email} onChange={e => set('email', e.target.value)} style={inp(focus === 'email')} {...fp('email')} /></div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginBottom: '10px' }}>
              <div><Lbl>Contact Number</Lbl><input type="tel" placeholder="09171234567" value={form.contact_number} onChange={e => set('contact_number', e.target.value)} style={inp(focus === 'contact')} {...fp('contact')} /></div>
              <div><Lbl>Emergency Contact</Lbl><input type="text" placeholder="Name & number" value={form.emergency_contact} onChange={e => set('emergency_contact', e.target.value)} style={inp(focus === 'emergency')} {...fp('emergency')} /></div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginBottom: '10px' }}>
              <div><Lbl>Height (cm)</Lbl><input type="number" placeholder="170" value={form.height} onChange={e => set('height', e.target.value)} style={inp(focus === 'height')} {...fp('height')} /></div>
              <div><Lbl>Weight (kg)</Lbl><input type="number" placeholder="65" value={form.weight} onChange={e => set('weight', e.target.value)} style={inp(focus === 'weight')} {...fp('weight')} /></div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginBottom: '12px' }}>
              <div><Lbl>Fitness Goal</Lbl>
                <select value={form.goal} onChange={e => set('goal', e.target.value)} style={sel(focus === 'goal')} {...fp('goal')}>
                  {GOALS.map(g => <option key={g}>{g}</option>)}
                </select>
              </div>
              <div><Lbl>Membership Type</Lbl>
                <select value={form.membership_type} onChange={e => set('membership_type', e.target.value)} style={sel(focus === 'membership')} {...fp('membership')}>
                  {MEMBERSHIPS.map(m => <option key={m.value} value={m.value}>{m.label}</option>)}
                </select>
              </div>
            </div>

            {/* Checkboxes */}
            <div style={{ display: 'flex', gap: '20px', marginBottom: '12px' }}>
              {[
                { k: 'wants_trainer', label: 'Wants a personal trainer' },
                { k: 'auto_approve',  label: 'Approve immediately (skip pending)' },
              ].map(({ k, label }) => (
                <label key={k} style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer' }}>
                  <div onClick={() => set(k, !form[k])} style={{ width: '15px', height: '15px', borderRadius: '4px', flexShrink: 0, border: `1.5px solid ${form[k] ? 'rgba(59,130,246,0.8)' : 'rgba(255,255,255,0.12)'}`, background: form[k] ? 'rgba(59,130,246,0.2)' : 'rgba(255,255,255,0.03)', display: 'flex', alignItems: 'center', justifyContent: 'center', transition: 'all 0.15s', cursor: 'pointer' }}>
                    {form[k] && <svg width="9" height="9" viewBox="0 0 24 24" fill="none" stroke="#60a5fa" strokeWidth="3.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>}
                  </div>
                  <span style={{ fontSize: '12px', color: '#718096', userSelect: 'none' }}>{label}</span>
                </label>
              ))}
            </div>

            {/* Status hint */}
            <div style={{ background: form.auto_approve ? 'rgba(34,197,94,0.06)' : 'rgba(245,158,11,0.06)', border: `1px solid ${form.auto_approve ? 'rgba(34,197,94,0.18)' : 'rgba(245,158,11,0.18)'}`, borderRadius: '8px', padding: '10px 13px', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px', fontSize: '11.5px', color: form.auto_approve ? '#22c55e' : '#f59e0b' }}>
              <span>{form.auto_approve ? '✅' : '⏳'}</span>
              {form.auto_approve
                ? "Member will be set as Active and you'll be taken to Members."
                : "Member will be added as Pending — you'll be taken to Approvals to review."}
            </div>

            <button type="submit" disabled={saving} style={{ width: '100%', padding: '12px', background: saving ? 'rgba(59,130,246,0.4)' : 'linear-gradient(135deg, #1d4ed8, #3b82f6)', color: '#fff', border: 'none', borderRadius: '9px', fontSize: '13.5px', fontWeight: '700', cursor: saving ? 'not-allowed' : 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px', boxShadow: saving ? 'none' : '0 4px 16px rgba(59,130,246,0.35)', transition: 'all 0.2s' }}>
              {saving ? (
                <><svg style={{ animation: 'spin2 1s linear infinite' }} width="14" height="14" viewBox="0 0 24 24" fill="none"><style>{`@keyframes spin2{to{transform:rotate(360deg)}}`}</style><circle opacity=".25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/><path opacity=".75" fill="currentColor" d="M4 12a8 8 0 018-8v8z"/></svg>Saving…</>
              ) : 'Submit Registration'}
            </button>
          </form>
        </div>
      </div>
    </Layout>
  )
}