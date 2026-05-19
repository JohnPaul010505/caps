import { useEffect, useState } from 'react'
import { supabase } from '../../services/supabase'
import Layout from '../../components/layout/Layout'

const _cache = { trainers: null, memberCounts: null }
const ALL_DAYS = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']

const C = {
  card: { background: '#141824', border: '1px solid rgba(255,255,255,0.06)', borderRadius: '12px', padding: '20px 22px' },
}

function Avatar({ name, size = 52 }) {
  const initials = name?.split(' ').slice(0, 2).map(w => w[0]).join('').toUpperCase() || '??'
  const palette = ['#2563eb','#7c3aed','#059669','#d97706','#dc2626','#0891b2']
  const color   = palette[name?.charCodeAt(0) % palette.length] || '#2563eb'
  return (
    <div style={{
      width: size, height: size, borderRadius: '12px', flexShrink: 0,
      background: color + '20', border: `1.5px solid ${color}35`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: size * 0.3, fontWeight: '800', color,
    }}>{initials}</div>
  )
}

// ─── Create Trainer Account Modal ─────────────────────────────────────────────
function CreateAccountModal({ trainer, onClose, onSuccess }) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPw, setShowPw] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function handleSubmit(e) {
    e.preventDefault()
    if (!email.trim() || !password.trim()) { setError('Both fields are required.'); return }
    if (password.length < 6) { setError('Password must be at least 6 characters.'); return }
    setLoading(true); setError('')
    try {
      const { data, error: rpcErr } = await supabase.rpc('create_trainer_account', { p_email: email.trim(), p_password: password, p_trainer_id: trainer.id })
      if (rpcErr) throw new Error(rpcErr.message)
      if (data?.error) throw new Error(data.error)
      onSuccess(trainer.id, data?.user_id)
    } catch (err) { setError(err.message || 'Failed to create account.'); setLoading(false) }
  }

  const inp = { width: '100%', boxSizing: 'border-box', background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: '10px', padding: '11px 14px', fontSize: '13.5px', color: '#e2e8f0', outline: 'none' }

  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50, backdropFilter: 'blur(4px)' }}>
      <div style={{ background: '#141824', border: '1px solid rgba(255,255,255,0.08)', borderRadius: '16px', padding: '28px', width: '420px', boxShadow: '0 20px 60px rgba(0,0,0,0.5)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '20px' }}>
          <Avatar name={trainer.full_name} size={42} />
          <div>
            <h3 style={{ color: '#e2e8f0', fontWeight: '700', fontSize: '15px', margin: 0 }}>Create Trainer Account</h3>
            <p style={{ color: '#4a5568', fontSize: '12px', margin: '2px 0 0' }}>{trainer.full_name}{trainer.specialty ? ` · ${trainer.specialty}` : ''}</p>
          </div>
          <button onClick={onClose} style={{ marginLeft: 'auto', background: 'none', border: 'none', color: '#4a5568', cursor: 'pointer', fontSize: '20px' }}>×</button>
        </div>
        <p style={{ color: '#4a5568', fontSize: '12.5px', marginBottom: '20px', lineHeight: 1.5 }}>Creates a login so this trainer can access the mobile app and chat with members.</p>
        {error && <div style={{ background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.2)', borderRadius: '10px', padding: '10px 14px', marginBottom: '14px', color: '#f87171', fontSize: '13px' }}>{error}</div>}
        <form onSubmit={handleSubmit}>
          <div style={{ marginBottom: '14px' }}>
            <label style={{ display: 'block', fontSize: '10.5px', fontWeight: '700', color: '#2d3748', letterSpacing: '0.8px', marginBottom: '7px', textTransform: 'uppercase' }}>Login Email</label>
            <input type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="trainer@email.com" required disabled={loading} style={{ ...inp, opacity: loading ? 0.6 : 1 }}
              onFocus={e => e.target.style.borderColor = 'rgba(59,130,246,0.5)'} onBlur={e => e.target.style.borderColor = 'rgba(255,255,255,0.08)'} />
          </div>
          <div style={{ marginBottom: '20px' }}>
            <label style={{ display: 'block', fontSize: '10.5px', fontWeight: '700', color: '#2d3748', letterSpacing: '0.8px', marginBottom: '7px', textTransform: 'uppercase' }}>Temporary Password</label>
            <div style={{ position: 'relative' }}>
              <input type={showPw ? 'text' : 'password'} value={password} onChange={e => setPassword(e.target.value)} placeholder="Min. 6 characters" required disabled={loading}
                style={{ ...inp, paddingRight: '44px', opacity: loading ? 0.6 : 1 }}
                onFocus={e => e.target.style.borderColor = 'rgba(59,130,246,0.5)'} onBlur={e => e.target.style.borderColor = 'rgba(255,255,255,0.08)'} />
              <button type="button" onClick={() => setShowPw(!showPw)} style={{ position: 'absolute', right: '12px', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: '#4a5568', padding: 0 }}>
                {showPw ? <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                : <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>}
              </button>
            </div>
          </div>
          <div style={{ display: 'flex', gap: '10px' }}>
            <button type="button" onClick={onClose} disabled={loading} style={{ flex: 1, padding: '10px', borderRadius: '10px', border: '1px solid rgba(255,255,255,0.08)', background: 'rgba(255,255,255,0.03)', color: '#718096', cursor: 'pointer', fontWeight: '600', fontSize: '13px' }}>Cancel</button>
            <button type="submit" disabled={loading} style={{ flex: 2, padding: '10px', borderRadius: '10px', border: 'none', background: loading ? 'rgba(59,130,246,0.4)' : 'linear-gradient(135deg, #1d4ed8, #3b82f6)', color: '#fff', cursor: loading ? 'not-allowed' : 'pointer', fontWeight: '700', fontSize: '13px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '7px' }}>
              {loading ? (<><svg style={{ animation: 'spin 1s linear infinite' }} width="13" height="13" viewBox="0 0 24 24" fill="none"><style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style><circle opacity=".25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/><path opacity=".75" fill="currentColor" d="M4 12a8 8 0 018-8v8z"/></svg>Creating…</>) : '✓ Create Account'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─── Assigned Members Modal ────────────────────────────────────────────────────
function AssignedMembersModal({ trainer, onClose }) {
  const [members, setMembers] = useState(null)
  useEffect(() => {
    supabase.from('members').select('id, full_name, goal, membership_type, user_id').eq('trainer_id', trainer.id).eq('membership_status', 'active')
      .then(({ data }) => setMembers(data || []))
  }, [trainer.id])

  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50, backdropFilter: 'blur(4px)' }}>
      <div style={{ background: '#141824', border: '1px solid rgba(255,255,255,0.08)', borderRadius: '16px', padding: '28px', width: '460px', maxHeight: '80vh', display: 'flex', flexDirection: 'column', boxShadow: '0 20px 60px rgba(0,0,0,0.5)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '18px' }}>
          <Avatar name={trainer.full_name} size={38} />
          <div>
            <h3 style={{ color: '#e2e8f0', fontWeight: '700', fontSize: '15px', margin: 0 }}>Assigned Members</h3>
            <p style={{ color: '#4a5568', fontSize: '11.5px', margin: 0 }}>{trainer.full_name}</p>
          </div>
          <button onClick={onClose} style={{ marginLeft: 'auto', background: 'none', border: 'none', color: '#4a5568', cursor: 'pointer', fontSize: '20px' }}>×</button>
        </div>
        <div style={{ overflowY: 'auto', flex: 1 }}>
          {members === null ? <div style={{ textAlign: 'center', padding: '40px', color: '#4a5568' }}>Loading…</div>
          : members.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '40px' }}>
              <p style={{ fontSize: '32px', marginBottom: '8px' }}>👥</p>
              <p style={{ fontWeight: '600', color: '#4a5568', fontSize: '13px' }}>No members assigned yet</p>
            </div>
          ) : members.map(m => {
            const palette = ['#2563eb','#7c3aed','#059669','#d97706','#dc2626','#0891b2']
            const color = palette[m.full_name?.charCodeAt(0) % palette.length] || '#2563eb'
            const initials = m.full_name?.split(' ').slice(0, 2).map(w => w[0]).join('').toUpperCase() || '??'
            return (
              <div key={m.id} style={{ display: 'flex', alignItems: 'center', gap: '11px', padding: '12px', background: 'rgba(255,255,255,0.02)', borderRadius: '10px', marginBottom: '8px', border: '1px solid rgba(255,255,255,0.04)' }}>
                <div style={{ width: 34, height: 34, borderRadius: '8px', background: color + '20', border: `1px solid ${color}30`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '11px', fontWeight: '700', color, flexShrink: 0 }}>{initials}</div>
                <div style={{ flex: 1 }}>
                  <p style={{ fontSize: '13px', fontWeight: '600', color: '#c8d0e0', margin: 0 }}>{m.full_name}</p>
                  <p style={{ fontSize: '10.5px', color: '#4a5568', margin: '2px 0 0' }}>{m.goal || '—'} · {m.membership_type || '—'}</p>
                </div>
                {m.user_id
                  ? <span style={{ fontSize: '10px', background: 'rgba(34,197,94,0.12)', color: '#22c55e', border: '1px solid rgba(34,197,94,0.25)', borderRadius: '6px', padding: '2px 8px', fontWeight: '600' }}>✓ App</span>
                  : <span style={{ fontSize: '10px', background: 'rgba(245,158,11,0.12)', color: '#f59e0b', border: '1px solid rgba(245,158,11,0.25)', borderRadius: '6px', padding: '2px 8px', fontWeight: '600' }}>No App</span>}
              </div>
            )
          })}
        </div>
        <button onClick={onClose} style={{ marginTop: '16px', width: '100%', padding: '10px', borderRadius: '10px', border: '1px solid rgba(255,255,255,0.08)', background: 'rgba(255,255,255,0.03)', color: '#718096', cursor: 'pointer', fontWeight: '600', fontSize: '13px' }}>Close</button>
      </div>
    </div>
  )
}

function Toast({ message, onClose }) {
  useEffect(() => { const t = setTimeout(onClose, 3500); return () => clearTimeout(t) }, [onClose])
  return (
    <div style={{ position: 'fixed', bottom: '28px', right: '28px', zIndex: 100, background: 'rgba(34,197,94,0.12)', border: '1px solid rgba(34,197,94,0.3)', borderRadius: '12px', padding: '13px 18px', display: 'flex', alignItems: 'center', gap: '9px', color: '#22c55e', fontSize: '13px', fontWeight: '600', boxShadow: '0 8px 32px rgba(0,0,0,0.4)' }}>
      ✓ {message}
    </div>
  )
}

// ─── Main Component ────────────────────────────────────────────────────────────
export default function Trainers() {
  const [trainers,     setTrainers]     = useState(_cache.trainers)
  const [memberCounts, setMemberCounts] = useState(_cache.memberCounts ?? {})
  const [showForm,     setShowForm]     = useState(false)
  const [form,         setForm]         = useState({ full_name: '', specialty: '', available_days: [] })
  const [saving,       setSaving]       = useState(false)
  const [accountModal, setAccountModal] = useState(null)
  const [membersModal, setMembersModal] = useState(null)
  const [toast,        setToast]        = useState('')

  useEffect(() => { fetchTrainers() }, [])

  async function fetchTrainers() {
    if (_cache.trainers) { setTrainers(_cache.trainers); setMemberCounts(_cache.memberCounts ?? {}) }
    try {
      const { data, error: err } = await supabase.from('trainers').select('*').order('created_at', { ascending: false })
      if (err) throw err
      _cache.trainers = data || []
      setTrainers(_cache.trainers)
      if (data && data.length > 0) {
        const { data: members } = await supabase.from('members').select('trainer_id').eq('membership_status', 'active').in('trainer_id', data.map(t => t.id))
        const counts = {};
        (members || []).forEach(m => { if (m.trainer_id) counts[m.trainer_id] = (counts[m.trainer_id] || 0) + 1 })
        _cache.memberCounts = counts; setMemberCounts(counts)
      }
    } catch { if (!_cache.trainers) setTrainers([]) }
  }

  function toggleDay(day) {
    setForm(prev => ({ ...prev, available_days: prev.available_days.includes(day) ? prev.available_days.filter(d => d !== day) : [...prev.available_days, day] }))
  }

  async function handleAdd(e) {
    e.preventDefault()
    if (!form.full_name.trim()) return
    setSaving(true)
    const { data } = await supabase.from('trainers').insert({ full_name: form.full_name.trim(), specialty: form.specialty.trim() || null, available_days: form.available_days }).select().single()
    if (data) { const updated = [data, ...(trainers || [])]; _cache.trainers = updated; setTrainers(updated) }
    setForm({ full_name: '', specialty: '', available_days: [] })
    setShowForm(false); setSaving(false); setToast('Trainer added successfully!')
  }

  async function handleDelete(id) {
    if (!window.confirm('Remove this trainer? Their assigned members will lose their trainer assignment.')) return
    await supabase.from('trainers').delete().eq('id', id)
    await supabase.from('members').update({ trainer_id: null }).eq('trainer_id', id)
    const updated = (trainers || []).filter(t => t.id !== id)
    _cache.trainers = updated; setTrainers(updated)
  }

  function handleAccountSuccess() {
    setAccountModal(null); setToast('Trainer account created!')
    _cache.trainers = null; _cache.memberCounts = null; fetchTrainers()
  }

  const inputStyle = { background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: '9px', padding: '10px 13px', fontSize: '13px', color: '#e2e8f0', outline: 'none', width: '100%', boxSizing: 'border-box' }

  const activeCount  = (trainers || []).filter(t => t.user_id).length
  const pendingCount = (trainers || []).filter(t => !t.user_id).length
  const totalMembers = Object.values(memberCounts).reduce((a, b) => a + b, 0)

  return (
    <Layout>
      {/* Page Header */}
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '22px' }}>
        <div>
          <h1 style={{ fontSize: '22px', fontWeight: '800', color: '#f0f2f8', margin: '0 0 4px', letterSpacing: '-0.3px' }}>Trainer Management</h1>
          <p style={{ color: '#4a5568', fontSize: '13px', margin: 0 }}>Manage gym trainers, create app accounts, and view assigned members.</p>
        </div>
        <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
          {trainers !== null && (
            <div style={{ background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.07)', borderRadius: '10px', padding: '8px 16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span style={{ fontSize: '20px', fontWeight: '800', color: '#c8d0e0' }}>{trainers.length}</span>
              <span style={{ fontSize: '11px', color: '#4a5568', fontWeight: '500' }}>Total Trainers</span>
            </div>
          )}
          <button
            onClick={() => setShowForm(!showForm)}
            style={{ background: 'linear-gradient(135deg, #1d4ed8, #3b82f6)', color: '#fff', border: 'none', borderRadius: '10px', padding: '10px 18px', fontSize: '13px', fontWeight: '700', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '7px', boxShadow: '0 4px 14px rgba(59,130,246,0.35)' }}
          >
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            Add New Trainer
          </button>
        </div>
      </div>

      {/* Info Banner */}
      <div style={{ background: 'rgba(59,130,246,0.06)', border: '1px solid rgba(59,130,246,0.15)', borderRadius: '10px', padding: '13px 16px', marginBottom: '20px', display: 'flex', gap: '10px', alignItems: 'flex-start' }}>
        <div style={{ width: '20px', height: '20px', borderRadius: '50%', background: 'rgba(59,130,246,0.2)', border: '1px solid rgba(59,130,246,0.35)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, marginTop: '1px' }}>
          <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#60a5fa" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="17" x2="12" y2="11"/><line x1="12" y1="7" x2="12.01" y2="7"/></svg>
        </div>
        <p style={{ fontSize: '12.5px', color: '#60a5fa', margin: 0, lineHeight: 1.6 }}>
          <strong>How trainer–member connection works:</strong> Add a trainer here → create their app account → go to Members and assign them to members who want a trainer → trainer logs into the mobile app and can chat with their members in real time.
        </p>
      </div>

      {/* Add Trainer Form */}
      {showForm && (
        <div style={{ ...C.card, marginBottom: '18px' }}>
          <h3 style={{ fontSize: '14px', fontWeight: '700', color: '#c8d0e0', marginBottom: '18px', margin: '0 0 18px' }}>New Trainer</h3>
          <form onSubmit={handleAdd}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '14px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '10.5px', fontWeight: '700', color: '#2d3748', letterSpacing: '0.8px', marginBottom: '6px', textTransform: 'uppercase' }}>Full Name *</label>
                <input type="text" placeholder="e.g. Mike Santos" value={form.full_name} required onChange={e => setForm({ ...form, full_name: e.target.value })} style={inputStyle}
                  onFocus={e => e.target.style.borderColor = 'rgba(59,130,246,0.45)'} onBlur={e => e.target.style.borderColor = 'rgba(255,255,255,0.08)'} />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '10.5px', fontWeight: '700', color: '#2d3748', letterSpacing: '0.8px', marginBottom: '6px', textTransform: 'uppercase' }}>Specialty</label>
                <input type="text" placeholder="e.g. Strength & Conditioning" value={form.specialty} onChange={e => setForm({ ...form, specialty: e.target.value })} style={inputStyle}
                  onFocus={e => e.target.style.borderColor = 'rgba(59,130,246,0.45)'} onBlur={e => e.target.style.borderColor = 'rgba(255,255,255,0.08)'} />
              </div>
            </div>
            <div style={{ marginBottom: '18px' }}>
              <label style={{ display: 'block', fontSize: '10.5px', fontWeight: '700', color: '#2d3748', letterSpacing: '0.8px', marginBottom: '10px', textTransform: 'uppercase' }}>Available Days</label>
              <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
                {ALL_DAYS.map(day => (
                  <button key={day} type="button" onClick={() => toggleDay(day)} style={{ padding: '5px 13px', borderRadius: '6px', fontSize: '11.5px', fontWeight: '700', cursor: 'pointer', transition: 'all 0.15s', background: form.available_days.includes(day) ? 'rgba(59,130,246,0.25)' : 'rgba(255,255,255,0.04)', color: form.available_days.includes(day) ? '#60a5fa' : '#4a5568', border: form.available_days.includes(day) ? '1px solid rgba(59,130,246,0.4)' : '1px solid rgba(255,255,255,0.07)', letterSpacing: '0.3px' }}>{day.toUpperCase()}</button>
                ))}
              </div>
            </div>
            <div style={{ display: 'flex', gap: '10px' }}>
              <button type="submit" disabled={saving} style={{ background: 'linear-gradient(135deg, #1d4ed8, #3b82f6)', color: '#fff', border: 'none', borderRadius: '9px', padding: '10px 22px', fontSize: '13px', fontWeight: '700', cursor: 'pointer', opacity: saving ? 0.6 : 1 }}>{saving ? 'Saving…' : 'Save Trainer'}</button>
              <button type="button" onClick={() => { setShowForm(false); setForm({ full_name: '', specialty: '', available_days: [] }) }} style={{ background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.07)', color: '#718096', borderRadius: '9px', padding: '10px 18px', fontSize: '13px', fontWeight: '600', cursor: 'pointer' }}>Cancel</button>
            </div>
          </form>
        </div>
      )}

      {/* Trainer Cards */}
      {trainers === null ? (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
          {Array.from({ length: 3 }).map((_, i) => (
            <div key={i} style={{ ...C.card, display: 'flex', gap: '16px', alignItems: 'center' }}>
              <div style={{ width: 52, height: 52, borderRadius: '12px', background: 'rgba(255,255,255,0.04)', flexShrink: 0 }} />
              <div style={{ flex: 1, display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: '10px' }}>
                {Array.from({ length: 4 }).map((__, j) => <div key={j} style={{ height: '11px', background: 'rgba(255,255,255,0.04)', borderRadius: '4px' }} />)}
              </div>
            </div>
          ))}
        </div>
      ) : trainers.length === 0 ? (
        <div style={{ ...C.card, padding: '70px 24px', textAlign: 'center' }}>
          <div style={{ fontSize: '36px', marginBottom: '10px' }}>💪</div>
          <p style={{ fontWeight: '700', color: '#4a5568', fontSize: '14px', marginBottom: '4px' }}>No trainers yet</p>
          <p style={{ fontSize: '12.5px', color: '#2d3748' }}>Click "Add New Trainer" to get started</p>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
          {trainers.map(t => {
            const count = memberCounts[t.id] || 0
            return (
              <div key={t.id} style={{ ...C.card, transition: 'border-color 0.15s' }}
                onMouseEnter={e => e.currentTarget.style.borderColor = 'rgba(255,255,255,0.1)'}
                onMouseLeave={e => e.currentTarget.style.borderColor = 'rgba(255,255,255,0.06)'}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                  {/* Avatar */}
                  <Avatar name={t.full_name} size={52} />

                  {/* Info */}
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '6px', flexWrap: 'wrap' }}>
                      <span style={{ fontSize: '15px', fontWeight: '800', color: '#e2e8f0', letterSpacing: '-0.2px' }}>{t.full_name}</span>
                      {/* Status badge */}
                      {t.user_id
                        ? <span style={{ padding: '2px 9px', borderRadius: '6px', fontSize: '10.5px', fontWeight: '700', background: 'rgba(34,197,94,0.12)', color: '#22c55e', border: '1px solid rgba(34,197,94,0.25)', letterSpacing: '0.3px' }}>ACTIVE</span>
                        : <span style={{ padding: '2px 9px', borderRadius: '6px', fontSize: '10.5px', fontWeight: '700', background: 'rgba(245,158,11,0.12)', color: '#f59e0b', border: '1px solid rgba(245,158,11,0.25)', letterSpacing: '0.3px' }}>PENDING SETUP</span>
                      }
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
                      {t.specialty && <span style={{ fontSize: '12px', color: '#718096', fontWeight: '500' }}>{t.specialty}</span>}
                      {t.specialty && t.available_days?.length > 0 && <span style={{ color: '#2d3748', fontSize: '11px' }}>·</span>}
                      {t.available_days?.length > 0 && (
                        <div style={{ display: 'flex', gap: '4px', flexWrap: 'wrap' }}>
                          {t.available_days.map(day => (
                            <span key={day} style={{ padding: '2px 8px', borderRadius: '5px', fontSize: '9.5px', fontWeight: '700', background: 'rgba(59,130,246,0.12)', color: '#60a5fa', border: '1px solid rgba(59,130,246,0.2)', letterSpacing: '0.5px' }}>{day.toUpperCase()}</span>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Members + App Account */}
                  <div style={{ display: 'flex', alignItems: 'center', gap: '20px', flexShrink: 0 }}>
                    <div style={{ textAlign: 'center' }}>
                      <p style={{ fontSize: '18px', fontWeight: '800', color: '#c8d0e0', margin: 0, lineHeight: 1 }}>{count}</p>
                      <p style={{ fontSize: '10px', color: '#4a5568', margin: '2px 0 0', fontWeight: '500' }}>Members</p>
                    </div>
                    <div style={{ textAlign: 'center' }}>
                      {t.user_id
                        ? <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                            <div style={{ width: '18px', height: '18px', borderRadius: '50%', background: 'rgba(34,197,94,0.15)', border: '1px solid rgba(34,197,94,0.3)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                              <svg width="9" height="9" viewBox="0 0 24 24" fill="none" stroke="#22c55e" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
                            </div>
                            <span style={{ fontSize: '10.5px', color: '#22c55e', fontWeight: '600' }}>App Account</span>
                          </div>
                        : <div style={{ fontSize: '10.5px', color: '#4a5568', fontWeight: '500' }}>No Account</div>
                      }
                    </div>
                  </div>

                  {/* Actions */}
                  <div style={{ display: 'flex', gap: '7px', flexShrink: 0 }}>
                    <button onClick={() => setMembersModal(t)} style={{ padding: '8px 14px', borderRadius: '8px', background: 'rgba(59,130,246,0.08)', border: '1px solid rgba(59,130,246,0.2)', color: '#60a5fa', fontSize: '12px', fontWeight: '600', cursor: 'pointer', transition: 'all 0.15s' }}
                      onMouseEnter={e => e.currentTarget.style.background = 'rgba(59,130,246,0.16)'} onMouseLeave={e => e.currentTarget.style.background = 'rgba(59,130,246,0.08)'}>
                      View Members
                    </button>

                    {!t.user_id ? (
                      <button onClick={() => setAccountModal(t)} style={{ padding: '8px 14px', borderRadius: '8px', background: 'rgba(245,158,11,0.08)', border: '1px solid rgba(245,158,11,0.2)', color: '#f59e0b', fontSize: '12px', fontWeight: '600', cursor: 'pointer', transition: 'all 0.15s', whiteSpace: 'nowrap' }}
                        onMouseEnter={e => e.currentTarget.style.background = 'rgba(245,158,11,0.15)'} onMouseLeave={e => e.currentTarget.style.background = 'rgba(245,158,11,0.08)'}>
                        Create Account
                      </button>
                    ) : (
                      <div style={{ padding: '8px 14px', borderRadius: '8px', background: 'rgba(34,197,94,0.06)', border: '1px solid rgba(34,197,94,0.15)', color: '#22c55e', fontSize: '12px', fontWeight: '600' }}>✓ Active</div>
                    )}

                    <button onClick={() => handleDelete(t.id)} style={{ width: '34px', height: '34px', borderRadius: '8px', background: 'rgba(239,68,68,0.06)', border: '1px solid rgba(239,68,68,0.15)', color: '#f87171', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', transition: 'all 0.15s', flexShrink: 0 }}
                      onMouseEnter={e => e.currentTarget.style.background = 'rgba(239,68,68,0.15)'} onMouseLeave={e => e.currentTarget.style.background = 'rgba(239,68,68,0.06)'}>
                      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4h6v2"/></svg>
                    </button>
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      )}

      {/* Footer Stats */}
      {trainers !== null && trainers.length > 0 && (
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginTop: '16px', padding: '12px 16px', background: '#141824', border: '1px solid rgba(255,255,255,0.05)', borderRadius: '10px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <div style={{ width: '6px', height: '6px', borderRadius: '50%', background: '#22c55e' }} />
            <span style={{ fontSize: '11.5px', color: '#4a5568' }}><strong style={{ color: '#22c55e' }}>{activeCount}</strong> Active Accounts</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <div style={{ width: '6px', height: '6px', borderRadius: '50%', background: '#f59e0b' }} />
            <span style={{ fontSize: '11.5px', color: '#4a5568' }}><strong style={{ color: '#f59e0b' }}>{pendingCount}</strong> Pending Setup</span>
          </div>
          <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span style={{ fontSize: '11.5px', color: '#2d3748' }}>Capacity</span>
            <div style={{ width: '120px', height: '4px', background: 'rgba(255,255,255,0.06)', borderRadius: '2px', overflow: 'hidden' }}>
              <div style={{ width: `${Math.min((totalMembers / 220) * 100, 100)}%`, height: '100%', background: 'linear-gradient(90deg, #2563eb, #3b82f6)', borderRadius: '2px' }} />
            </div>
            <span style={{ fontSize: '11px', color: '#4a5568', fontWeight: '600' }}>{totalMembers} / 220 Slots</span>
          </div>
        </div>
      )}

      {accountModal && <CreateAccountModal trainer={accountModal} onClose={() => setAccountModal(null)} onSuccess={handleAccountSuccess} />}
      {membersModal && <AssignedMembersModal trainer={membersModal} onClose={() => setMembersModal(null)} />}
      {toast && <Toast message={toast} onClose={() => setToast('')} />}
    </Layout>
  )
}