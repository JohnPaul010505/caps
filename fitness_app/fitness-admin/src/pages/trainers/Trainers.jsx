import { useEffect, useState } from 'react'
import { supabase } from '../../services/supabase'
import Layout from '../../components/layout/Layout'

// Module-level cache — survives navigation, resets only on full page refresh
const _cache = { trainers: null, memberCounts: null }

const ALL_DAYS = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']

function card(style) {
  return {
    background: '#1a1a2e',
    border: '1px solid rgba(255,255,255,0.07)',
    borderRadius: '14px',
    padding: '24px',
    ...style
  }
}

function Avatar({ name, size = 36 }) {
  const initials = name?.split(' ').slice(0, 2).map(w => w[0]).join('').toUpperCase() || '??'
  const colors = ['#7c3aed','#2563eb','#059669','#d97706','#dc2626','#0891b2']
  const color  = colors[name?.charCodeAt(0) % colors.length] || '#7c3aed'
  return (
    <div style={{
      width: size, height: size, borderRadius: '50%',
      background: color + '33', border: `1.5px solid ${color}55`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: size * 0.33, fontWeight: '700', color, flexShrink: 0
    }}>{initials}</div>
  )
}

// ─── Create Trainer Account Modal ────────────────────────────────────────────

function CreateAccountModal({ trainer, onClose, onSuccess }) {
  const [email,    setEmail]    = useState('')
  const [password, setPassword] = useState('')
  const [showPw,   setShowPw]   = useState(false)
  const [loading,  setLoading]  = useState(false)
  const [error,    setError]    = useState('')

  async function handleSubmit(e) {
    e.preventDefault()
    if (!email.trim() || !password.trim()) { setError('Both fields are required.'); return }
    if (password.length < 6) { setError('Password must be at least 6 characters.'); return }

    setLoading(true)
    setError('')

    try {
      // Use the same RPC pattern — create_trainer_account function
      const { data, error: rpcErr } = await supabase.rpc('create_trainer_account', {
        p_email:      email.trim(),
        p_password:   password,
        p_trainer_id: trainer.id,
      })

      if (rpcErr) throw new Error(rpcErr.message)
      if (data?.error) throw new Error(data.error)

      onSuccess(trainer.id, data?.user_id)
    } catch (err) {
      setError(err.message || 'Failed to create account.')
      setLoading(false)
    }
  }

  const inputStyle = {
    width: '100%', boxSizing: 'border-box',
    background: 'rgba(255,255,255,0.05)',
    border: '1px solid rgba(255,255,255,0.1)',
    borderRadius: '10px', padding: '11px 14px',
    fontSize: '14px', color: '#e2e2f0', outline: 'none',
  }

  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.75)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50, padding: '20px' }}>
      <div style={{ background: '#1a1a2e', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '20px', padding: '32px', width: '100%', maxWidth: '420px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '24px' }}>
          <Avatar name={trainer.full_name} size={44} />
          <div>
            <h3 style={{ color: '#e2e2f0', fontWeight: '700', fontSize: '16px', margin: 0 }}>Create Trainer Account</h3>
            <p style={{ color: '#5a5a8a', fontSize: '12px', marginTop: '3px' }}>{trainer.full_name}{trainer.specialty ? ` · ${trainer.specialty}` : ''}</p>
          </div>
          <button onClick={onClose} style={{ marginLeft: 'auto', background: 'none', border: 'none', color: '#5a5a8a', cursor: 'pointer', fontSize: '20px', lineHeight: 1 }}>×</button>
        </div>

        <p style={{ color: '#6060a0', fontSize: '13px', marginBottom: '22px', lineHeight: 1.5 }}>
          Creates a login so this trainer can access the mobile app, view assigned members, and chat with them in real time.
        </p>

        {error && (
          <div style={{ background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.25)', borderRadius: '10px', padding: '11px 14px', marginBottom: '18px', color: '#f87171', fontSize: '13px' }}>
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div style={{ marginBottom: '16px' }}>
            <label style={{ display: 'block', fontSize: '11px', fontWeight: '600', color: '#4a4a6a', letterSpacing: '0.5px', marginBottom: '8px' }}>LOGIN EMAIL</label>
            <input type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="trainer@email.com" required disabled={loading} style={{ ...inputStyle, opacity: loading ? 0.6 : 1 }}
              onFocus={e => e.target.style.borderColor = 'rgba(124,58,237,0.6)'}
              onBlur={e  => e.target.style.borderColor = 'rgba(255,255,255,0.1)'}
            />
          </div>

          <div style={{ marginBottom: '24px' }}>
            <label style={{ display: 'block', fontSize: '11px', fontWeight: '600', color: '#4a4a6a', letterSpacing: '0.5px', marginBottom: '8px' }}>TEMPORARY PASSWORD</label>
            <div style={{ position: 'relative' }}>
              <input type={showPw ? 'text' : 'password'} value={password} onChange={e => setPassword(e.target.value)} placeholder="Min. 6 characters" required disabled={loading}
                style={{ ...inputStyle, paddingRight: '44px', opacity: loading ? 0.6 : 1 }}
                onFocus={e => e.target.style.borderColor = 'rgba(124,58,237,0.6)'}
                onBlur={e  => e.target.style.borderColor = 'rgba(255,255,255,0.1)'}
              />
              <button type="button" onClick={() => setShowPw(!showPw)} style={{ position: 'absolute', right: '12px', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: '#4a4a6a', padding: 0 }}>
                {showPw
                  ? <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                  : <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                }
              </button>
            </div>
            <p style={{ fontSize: '11px', color: '#3a3a5a', marginTop: '6px' }}>Share this with the trainer so they can log in to the app.</p>
          </div>

          <div style={{ display: 'flex', gap: '10px' }}>
            <button type="button" onClick={onClose} disabled={loading} style={{ flex: 1, padding: '11px', borderRadius: '10px', border: '1px solid rgba(255,255,255,0.1)', background: 'rgba(255,255,255,0.05)', color: '#a0a0c0', cursor: 'pointer', fontWeight: '600', fontSize: '13px' }}>Cancel</button>
            <button type="submit" disabled={loading} style={{ flex: 2, padding: '11px', borderRadius: '10px', border: 'none', background: loading ? 'rgba(124,58,237,0.5)' : 'linear-gradient(135deg, #7c3aed, #a855f7)', color: '#fff', cursor: loading ? 'not-allowed' : 'pointer', fontWeight: '700', fontSize: '13px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
              {loading ? (
                <>
                  <svg style={{ animation: 'spin 1s linear infinite' }} width="14" height="14" viewBox="0 0 24 24" fill="none">
                    <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
                    <circle opacity=".25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
                    <path opacity=".75" fill="currentColor" d="M4 12a8 8 0 018-8v8z"/>
                  </svg>
                  Creating…
                </>
              ) : '✓ Create Account'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─── Assigned Members Modal ──────────────────────────────────────────────────

function AssignedMembersModal({ trainer, onClose }) {
  const [members, setMembers] = useState(null)

  useEffect(() => {
    supabase
      .from('members')
      .select('id, full_name, goal, membership_type, user_id')
      .eq('trainer_id', trainer.id)
      .eq('membership_status', 'active')
      .then(({ data }) => setMembers(data || []))
  }, [trainer.id])

  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.75)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50, padding: '20px' }}>
      <div style={{ background: '#1a1a2e', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '20px', padding: '32px', width: '100%', maxWidth: '480px', maxHeight: '80vh', display: 'flex', flexDirection: 'column' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '20px' }}>
          <Avatar name={trainer.full_name} size={40} />
          <div>
            <h3 style={{ color: '#e2e2f0', fontWeight: '700', fontSize: '16px', margin: 0 }}>Assigned Members</h3>
            <p style={{ color: '#5a5a8a', fontSize: '12px', margin: 0 }}>{trainer.full_name}</p>
          </div>
          <button onClick={onClose} style={{ marginLeft: 'auto', background: 'none', border: 'none', color: '#5a5a8a', cursor: 'pointer', fontSize: '20px' }}>×</button>
        </div>

        <div style={{ overflowY: 'auto', flex: 1 }}>
          {members === null ? (
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '40px', color: '#5a5a8a' }}>Loading…</div>
          ) : members.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '40px', color: '#4a4a6a' }}>
              <p style={{ fontSize: '32px', marginBottom: '10px' }}>👥</p>
              <p style={{ fontWeight: '600', color: '#6a6a9a' }}>No members assigned yet</p>
              <p style={{ fontSize: '12px', color: '#3a3a5a', marginTop: '4px' }}>Assign members from the Members page</p>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
              {members.map(m => (
                <div key={m.id} style={{ display: 'flex', alignItems: 'center', gap: '12px', padding: '14px', background: 'rgba(255,255,255,0.03)', borderRadius: '10px', border: '1px solid rgba(255,255,255,0.06)' }}>
                  <Avatar name={m.full_name} size={36} />
                  <div style={{ flex: 1 }}>
                    <p style={{ fontSize: '13px', fontWeight: '600', color: '#e2e2f0', margin: 0 }}>{m.full_name}</p>
                    <p style={{ fontSize: '11px', color: '#5a5a8a', margin: '2px 0 0' }}>{m.goal || '—'} · {m.membership_type || '—'}</p>
                  </div>
                  {m.user_id
                    ? <span style={{ fontSize: '10px', background: 'rgba(34,197,94,0.15)', color: '#22c55e', border: '1px solid rgba(34,197,94,0.3)', borderRadius: '20px', padding: '2px 8px', fontWeight: '600' }}>✓ App</span>
                    : <span style={{ fontSize: '10px', background: 'rgba(245,158,11,0.15)', color: '#f59e0b', border: '1px solid rgba(245,158,11,0.3)', borderRadius: '20px', padding: '2px 8px', fontWeight: '600' }}>No App</span>
                  }
                </div>
              ))}
            </div>
          )}
        </div>

        <button onClick={onClose} style={{ marginTop: '20px', width: '100%', padding: '11px', borderRadius: '10px', border: '1px solid rgba(255,255,255,0.1)', background: 'rgba(255,255,255,0.05)', color: '#a0a0c0', cursor: 'pointer', fontWeight: '600', fontSize: '13px' }}>Close</button>
      </div>
    </div>
  )
}

// ─── Toast ───────────────────────────────────────────────────────────────────

function Toast({ message, onClose }) {
  useEffect(() => {
    const t = setTimeout(onClose, 3500)
    return () => clearTimeout(t)
  }, [onClose])
  return (
    <div style={{ position: 'fixed', bottom: '28px', right: '28px', zIndex: 100, background: 'rgba(34,197,94,0.15)', border: '1px solid rgba(34,197,94,0.35)', borderRadius: '12px', padding: '14px 18px', display: 'flex', alignItems: 'center', gap: '10px', color: '#22c55e', fontSize: '13px', fontWeight: '600', boxShadow: '0 8px 32px rgba(0,0,0,0.4)' }}>
      ✓ {message}
    </div>
  )
}

// ─── Main Component ──────────────────────────────────────────────────────────

export default function Trainers() {
  const [trainers,        setTrainers]        = useState(_cache.trainers)
  const [memberCounts,    setMemberCounts]    = useState(_cache.memberCounts ?? {})
  const [showForm,        setShowForm]        = useState(false)
  const [form,            setForm]            = useState({ full_name: '', specialty: '', available_days: [] })
  const [saving,          setSaving]          = useState(false)
  const [accountModal,    setAccountModal]    = useState(null) // trainer object
  const [membersModal,    setMembersModal]    = useState(null) // trainer object
  const [toast,           setToast]           = useState('')

  useEffect(() => { fetchTrainers() }, [])

  async function fetchTrainers() {
    // Serve cache immediately — skeleton only on very first load
    if (_cache.trainers) {
      setTrainers(_cache.trainers)
      setMemberCounts(_cache.memberCounts ?? {})
    }
    try {
      const { data, error: err } = await supabase
        .from('trainers')
        .select('*')
        .order('created_at', { ascending: false })
      if (err) throw err
      _cache.trainers = data || []
      setTrainers(_cache.trainers)

      // Fetch member counts per trainer
      if (data && data.length > 0) {
        const { data: members } = await supabase
          .from('members')
          .select('trainer_id')
          .eq('membership_status', 'active')
          .in('trainer_id', data.map(t => t.id))

        const counts = {}
        ;(members || []).forEach(m => {
          if (m.trainer_id) counts[m.trainer_id] = (counts[m.trainer_id] || 0) + 1
        })
        _cache.memberCounts = counts
        setMemberCounts(counts)
      }
    } catch {
      if (!_cache.trainers) setTrainers([])
    }
  }

  function toggleDay(day) {
    setForm(prev => ({
      ...prev,
      available_days: prev.available_days.includes(day)
        ? prev.available_days.filter(d => d !== day)
        : [...prev.available_days, day]
    }))
  }

  async function handleAdd(e) {
    e.preventDefault()
    if (!form.full_name.trim()) return
    setSaving(true)
    const { data } = await supabase.from('trainers').insert({
      full_name: form.full_name.trim(),
      specialty: form.specialty.trim() || null,
      available_days: form.available_days,
    }).select().single()
    if (data) {
      const updated = [data, ...(trainers || [])]
      _cache.trainers = updated
      setTrainers(updated)
    }
    setForm({ full_name: '', specialty: '', available_days: [] })
    setShowForm(false)
    setSaving(false)
    setToast('Trainer added successfully!')
  }

  async function handleDelete(id) {
    if (!window.confirm('Remove this trainer? Their assigned members will lose their trainer assignment.')) return
    await supabase.from('trainers').delete().eq('id', id)
    // Also unassign members
    await supabase.from('members').update({ trainer_id: null }).eq('trainer_id', id)
    const updated = (trainers || []).filter(t => t.id !== id)
    _cache.trainers = updated
    setTrainers(updated)
  }

  function handleAccountSuccess(trainerId, userId) {
    setAccountModal(null)
    setToast('Trainer account created! They can now log in to the app.')
    // Clear cache and refetch so UI reflects the new user_id immediately
    _cache.trainers = null
    _cache.memberCounts = null
    fetchTrainers()
  }

  const inputStyle = {
    background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.1)',
    borderRadius: '10px', padding: '10px 14px', fontSize: '13px', color: '#e2e2f0',
    outline: 'none', width: '100%', boxSizing: 'border-box',
  }

  return (
    <Layout>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '28px' }}>
        <div>
          <h2 style={{ fontSize: '24px', fontWeight: '800', color: '#fff', margin: 0 }}>Trainers</h2>
          <p style={{ color: '#5a5a8a', fontSize: '13px', marginTop: '4px' }}>Manage gym trainers, create app accounts, and view assigned members</p>
        </div>
        <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
          {trainers !== null && (
            <div style={{ background: 'rgba(124,58,237,0.15)', border: '1px solid rgba(124,58,237,0.3)', borderRadius: '10px', padding: '8px 16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span style={{ fontSize: '20px', fontWeight: '800', color: '#a78bfa' }}>{trainers.length}</span>
              <span style={{ fontSize: '12px', color: '#7060a0' }}>trainers</span>
            </div>
          )}
          <button
            onClick={() => setShowForm(!showForm)}
            style={{ background: 'linear-gradient(135deg, #7c3aed, #a855f7)', color: '#fff', border: 'none', borderRadius: '10px', padding: '10px 18px', fontSize: '13px', fontWeight: '600', cursor: 'pointer', boxShadow: '0 4px 15px rgba(124,58,237,0.4)' }}
          >+ Add Trainer</button>
        </div>
      </div>

      {/* How It Works info banner */}
      <div style={{ background: 'rgba(59,130,246,0.08)', border: '1px solid rgba(59,130,246,0.2)', borderRadius: '10px', padding: '14px 18px', marginBottom: '20px', fontSize: '13px', color: '#93c5fd', lineHeight: 1.6 }}>
        <strong style={{ color: '#60a5fa' }}>How trainer–member connection works:</strong>
        {' '}Add a trainer here → create their app account → go to Members and assign them to members who want a trainer → trainer logs into the mobile app and can chat with their members in real time.
      </div>

      {/* Add Trainer Form */}
      {showForm && (
        <div style={{ ...card({}), marginBottom: '20px' }}>
          <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#e2e2f0', marginBottom: '18px', margin: '0 0 18px' }}>New Trainer</h3>
          <form onSubmit={handleAdd}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '16px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '11px', fontWeight: '600', color: '#4a4a6a', marginBottom: '6px', letterSpacing: '0.5px' }}>FULL NAME *</label>
                <input type="text" placeholder="e.g. Mike Santos" value={form.full_name} required
                  onChange={e => setForm({ ...form, full_name: e.target.value })} style={inputStyle}
                  onFocus={e => e.target.style.borderColor = 'rgba(124,58,237,0.5)'}
                  onBlur={e  => e.target.style.borderColor = 'rgba(255,255,255,0.1)'}
                />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '11px', fontWeight: '600', color: '#4a4a6a', marginBottom: '6px', letterSpacing: '0.5px' }}>SPECIALTY</label>
                <input type="text" placeholder="e.g. Strength & Conditioning" value={form.specialty}
                  onChange={e => setForm({ ...form, specialty: e.target.value })} style={inputStyle}
                  onFocus={e => e.target.style.borderColor = 'rgba(124,58,237,0.5)'}
                  onBlur={e  => e.target.style.borderColor = 'rgba(255,255,255,0.1)'}
                />
              </div>
            </div>
            <div style={{ marginBottom: '20px' }}>
              <label style={{ display: 'block', fontSize: '11px', fontWeight: '600', color: '#4a4a6a', marginBottom: '10px', letterSpacing: '0.5px' }}>AVAILABLE DAYS</label>
              <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
                {ALL_DAYS.map(day => (
                  <button key={day} type="button" onClick={() => toggleDay(day)} style={{
                    padding: '6px 14px', borderRadius: '20px', fontSize: '12px', fontWeight: '600', cursor: 'pointer', transition: 'all 0.15s',
                    background: form.available_days.includes(day) ? 'linear-gradient(135deg, #7c3aed, #a855f7)' : 'rgba(255,255,255,0.05)',
                    color: form.available_days.includes(day) ? '#fff' : '#5a5a8a',
                    border: form.available_days.includes(day) ? '1px solid transparent' : '1px solid rgba(255,255,255,0.08)',
                  }}>{day}</button>
                ))}
              </div>
            </div>
            <div style={{ display: 'flex', gap: '10px' }}>
              <button type="submit" disabled={saving} style={{ background: 'linear-gradient(135deg, #7c3aed, #a855f7)', color: '#fff', border: 'none', borderRadius: '10px', padding: '10px 24px', fontSize: '13px', fontWeight: '600', cursor: 'pointer', opacity: saving ? 0.6 : 1 }}>
                {saving ? 'Saving…' : 'Save Trainer'}
              </button>
              <button type="button" onClick={() => { setShowForm(false); setForm({ full_name: '', specialty: '', available_days: [] }) }} style={{ background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.08)', color: '#7070a0', borderRadius: '10px', padding: '10px 20px', fontSize: '13px', fontWeight: '600', cursor: 'pointer' }}>Cancel</button>
            </div>
          </form>
        </div>
      )}

      {/* Trainer Cards */}
      {trainers === null ? (
        // Skeleton
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {Array.from({ length: 3 }).map((_, i) => (
            <div key={i} style={{ ...card({}), display: 'flex', gap: '16px', alignItems: 'center' }}>
              <div style={{ width: 44, height: 44, borderRadius: '50%', background: 'rgba(255,255,255,0.05)', flexShrink: 0 }} />
              <div style={{ flex: 1, display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: '12px' }}>
                {Array.from({ length: 4 }).map((__, j) => (
                  <div key={j} style={{ height: '12px', background: 'rgba(255,255,255,0.05)', borderRadius: '4px' }} />
                ))}
              </div>
            </div>
          ))}
        </div>
      ) : trainers.length === 0 ? (
        <div style={{ ...card({ padding: '80px 24px', textAlign: 'center' }) }}>
          <p style={{ fontSize: '40px', marginBottom: '12px' }}>💪</p>
          <p style={{ fontWeight: '700', color: '#6a6a9a', fontSize: '15px', marginBottom: '4px' }}>No trainers yet</p>
          <p style={{ fontSize: '13px', color: '#3a3a5a' }}>Click "Add Trainer" to get started</p>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {trainers.map(t => {
            const count = memberCounts[t.id] || 0
            return (
              <div key={t.id} style={card({})}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
                  {/* Avatar */}
                  <Avatar name={t.full_name} size={48} />

                  {/* Info */}
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap', marginBottom: '4px' }}>
                      <span style={{ fontSize: '15px', fontWeight: '700', color: '#e2e2f0' }}>{t.full_name}</span>
                      {/* Account status badge */}
                      {t.user_id
                        ? <span style={{ padding: '2px 10px', borderRadius: '20px', fontSize: '10.5px', fontWeight: '600', background: 'rgba(34,197,94,0.12)', color: '#22c55e', border: '1px solid rgba(34,197,94,0.3)' }}>✓ App Account</span>
                        : <span style={{ padding: '2px 10px', borderRadius: '20px', fontSize: '10.5px', fontWeight: '600', background: 'rgba(245,158,11,0.12)', color: '#f59e0b', border: '1px solid rgba(245,158,11,0.3)' }}>No Account</span>
                      }
                      {/* Member count badge */}
                      <span style={{ padding: '2px 10px', borderRadius: '20px', fontSize: '10.5px', fontWeight: '600', background: 'rgba(59,130,246,0.12)', color: '#60a5fa', border: '1px solid rgba(59,130,246,0.3)' }}>
                        👥 {count} member{count !== 1 ? 's' : ''}
                      </span>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px', flexWrap: 'wrap' }}>
                      {t.specialty && <span style={{ fontSize: '12px', color: '#7070a0' }}>{t.specialty}</span>}
                      {t.available_days?.length > 0 && (
                        <div style={{ display: 'flex', gap: '5px', flexWrap: 'wrap' }}>
                          {t.available_days.map(day => (
                            <span key={day} style={{ padding: '1px 7px', borderRadius: '20px', fontSize: '10px', fontWeight: '600', background: 'rgba(124,58,237,0.18)', color: '#a78bfa', border: '1px solid rgba(124,58,237,0.25)' }}>{day}</span>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Action buttons */}
                  <div style={{ display: 'flex', gap: '8px', flexShrink: 0 }}>
                    {/* View Members */}
                    <button
                      onClick={() => setMembersModal(t)}
                      style={{ padding: '7px 14px', borderRadius: '8px', background: 'rgba(59,130,246,0.1)', border: '1px solid rgba(59,130,246,0.25)', color: '#60a5fa', fontSize: '12px', fontWeight: '600', cursor: 'pointer' }}
                      onMouseEnter={e => e.currentTarget.style.background = 'rgba(59,130,246,0.2)'}
                      onMouseLeave={e => e.currentTarget.style.background = 'rgba(59,130,246,0.1)'}
                    >
                      View Members
                    </button>

                    {/* Create / Account already active */}
                    {!t.user_id ? (
                      <button
                        onClick={() => setAccountModal(t)}
                        style={{ padding: '7px 14px', borderRadius: '8px', background: 'rgba(124,58,237,0.12)', border: '1px solid rgba(124,58,237,0.3)', color: '#a78bfa', fontSize: '12px', fontWeight: '600', cursor: 'pointer' }}
                        onMouseEnter={e => e.currentTarget.style.background = 'rgba(124,58,237,0.22)'}
                        onMouseLeave={e => e.currentTarget.style.background = 'rgba(124,58,237,0.12)'}
                      >
                        + Create Account
                      </button>
                    ) : (
                      <div style={{ padding: '7px 14px', borderRadius: '8px', background: 'rgba(34,197,94,0.08)', border: '1px solid rgba(34,197,94,0.2)', color: '#22c55e', fontSize: '12px', fontWeight: '600' }}>
                        ✓ Active
                      </div>
                    )}

                    {/* Remove */}
                    <button
                      onClick={() => handleDelete(t.id)}
                      style={{ padding: '7px 14px', borderRadius: '8px', background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.2)', color: '#f87171', fontSize: '12px', fontWeight: '600', cursor: 'pointer' }}
                      onMouseEnter={e => e.currentTarget.style.background = 'rgba(239,68,68,0.18)'}
                      onMouseLeave={e => e.currentTarget.style.background = 'rgba(239,68,68,0.08)'}
                    >
                      Remove
                    </button>
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      )}

      {/* Footer stats */}
      {trainers !== null && trainers.length > 0 && (
        <p style={{ marginTop: '16px', fontSize: '12px', color: '#3a3a5a' }}>
          {trainers.length} trainer{trainers.length !== 1 ? 's' : ''} total
          {' · '}
          <span style={{ color: '#22c55e' }}>{trainers.filter(t => t.user_id).length} with app accounts</span>
          {' · '}
          <span style={{ color: '#f59e0b' }}>{trainers.filter(t => !t.user_id).length} without</span>
        </p>
      )}

      {/* Modals */}
      {accountModal && (
        <CreateAccountModal
          trainer={accountModal}
          onClose={() => setAccountModal(null)}
          onSuccess={handleAccountSuccess}
        />
      )}
      {membersModal && (
        <AssignedMembersModal
          trainer={membersModal}
          onClose={() => setMembersModal(null)}
        />
      )}

      {/* Toast */}
      {toast && <Toast message={toast} onClose={() => setToast('')} />}
    </Layout>
  )
}