import { useState, useEffect } from 'react'
import { supabase } from '../../services/supabase'
import Layout from '../../components/layout/Layout'

const _cache = { members: null, trainers: null }

const C = {
  card: { background: '#141824', border: '1px solid rgba(255,255,255,0.06)', borderRadius: '12px', padding: '18px 20px' },
}

function Avatar({ name, size = 40 }) {
  const initials = name?.split(' ').slice(0, 2).map(w => w[0]).join('').toUpperCase() || '??'
  const palette = ['#2563eb','#7c3aed','#059669','#d97706','#dc2626','#0891b2']
  const color   = palette[name?.charCodeAt(0) % palette.length] || '#2563eb'
  return (
    <div style={{
      width: size, height: size, borderRadius: '10px', flexShrink: 0,
      background: color + '20', border: `1.5px solid ${color}35`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: size * 0.3, fontWeight: '800', color,
    }}>{initials}</div>
  )
}

function Field({ label, value }) {
  return (
    <div>
      <p style={{ fontSize: '9.5px', fontWeight: '700', color: '#2d3748', letterSpacing: '0.8px', marginBottom: '3px', textTransform: 'uppercase' }}>{label}</p>
      <p style={{ fontSize: '12.5px', color: '#8892a4' }}>{value ?? '—'}</p>
    </div>
  )
}

// ─── Create Account Modal ──────────────────────────────────────────────────────
function CreateAccountModal({ member, onClose, onSuccess }) {
  const [email, setEmail] = useState(member.email || '')
  const [password, setPassword] = useState('')
  const [showPw, setShowPw] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function handleCreate(e) {
    e.preventDefault()
    if (!email.trim() || !password.trim()) { setError('Email and password are required.'); return }
    if (password.length < 6) { setError('Password must be at least 6 characters.'); return }
    setLoading(true); setError('')
    try {
      const { data, error: rpcErr } = await supabase.rpc('create_member_account', { p_email: email.trim(), p_password: password, p_member_id: member.id })
      if (rpcErr) throw new Error(rpcErr.message)
      if (data?.error) throw new Error(data.error)
      onSuccess()
    } catch (err) { setError(err.message || 'Failed to create account. Please try again.'); setLoading(false) }
  }

  const inp = { width: '100%', boxSizing: 'border-box', background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.08)', borderRadius: '10px', padding: '11px 14px', fontSize: '13.5px', color: '#e2e8f0', outline: 'none' }

  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50, backdropFilter: 'blur(4px)' }}>
      <div style={{ background: '#141824', border: '1px solid rgba(255,255,255,0.08)', borderRadius: '16px', padding: '28px', width: '420px', boxShadow: '0 20px 60px rgba(0,0,0,0.5)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '18px' }}>
          <Avatar name={member.full_name} size={40} />
          <div>
            <h3 style={{ color: '#e2e8f0', fontWeight: '700', fontSize: '15px', margin: 0 }}>Create Member Account</h3>
            <p style={{ color: '#4a5568', fontSize: '12px', margin: '2px 0 0' }}>{member.full_name}</p>
          </div>
          <button onClick={onClose} style={{ marginLeft: 'auto', background: 'none', border: 'none', color: '#4a5568', cursor: 'pointer', fontSize: '20px' }}>×</button>
        </div>
        <p style={{ color: '#4a5568', fontSize: '12.5px', marginBottom: '20px', lineHeight: 1.5 }}>Creates a login so the member can access the mobile app, log workouts, chat with their trainer, and track progress.</p>
        {error && <div style={{ background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.2)', borderRadius: '10px', padding: '10px 14px', marginBottom: '14px', color: '#f87171', fontSize: '13px' }}>{error}</div>}
        <form onSubmit={handleCreate}>
          <div style={{ marginBottom: '14px' }}>
            <label style={{ display: 'block', fontSize: '10.5px', fontWeight: '700', color: '#2d3748', letterSpacing: '0.8px', marginBottom: '7px', textTransform: 'uppercase' }}>Login Email</label>
            <input type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="member@email.com" required disabled={loading} style={{ ...inp, opacity: loading ? 0.6 : 1 }}
              onFocus={e => e.target.style.borderColor = 'rgba(59,130,246,0.5)'} onBlur={e => e.target.style.borderColor = 'rgba(255,255,255,0.08)'} />
          </div>
          <div style={{ marginBottom: '20px' }}>
            <label style={{ display: 'block', fontSize: '10.5px', fontWeight: '700', color: '#2d3748', letterSpacing: '0.8px', marginBottom: '7px', textTransform: 'uppercase' }}>Temporary Password</label>
            <div style={{ position: 'relative' }}>
              <input type={showPw ? 'text' : 'password'} value={password} onChange={e => setPassword(e.target.value)} placeholder="Min. 6 characters" required disabled={loading} style={{ ...inp, paddingRight: '44px', opacity: loading ? 0.6 : 1 }}
                onFocus={e => e.target.style.borderColor = 'rgba(59,130,246,0.5)'} onBlur={e => e.target.style.borderColor = 'rgba(255,255,255,0.08)'} />
              <button type="button" onClick={() => setShowPw(!showPw)} style={{ position: 'absolute', right: '12px', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: '#4a5568', padding: 0 }}>
                {showPw ? <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
                : <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>}
              </button>
            </div>
            <p style={{ fontSize: '10.5px', color: '#2d3748', marginTop: '5px' }}>Share this with the member — they can change it after first login.</p>
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

// ─── Assign Trainer Modal ──────────────────────────────────────────────────────
function AssignTrainerModal({ member, trainers, onClose, onSuccess }) {
  const [selectedId, setSelectedId] = useState(member.trainer_id || '')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function handleAssign(e) {
    e.preventDefault(); setLoading(true); setError('')
    try {
      const { error: updateErr } = await supabase.from('members').update({ trainer_id: selectedId || null }).eq('id', member.id)
      if (updateErr) throw updateErr
      onSuccess(selectedId || null)
    } catch (err) { setError(err.message || 'Failed to assign trainer.'); setLoading(false) }
  }

  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50, backdropFilter: 'blur(4px)' }}>
      <div style={{ background: '#141824', border: '1px solid rgba(255,255,255,0.08)', borderRadius: '16px', padding: '28px', width: '400px', boxShadow: '0 20px 60px rgba(0,0,0,0.5)' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px' }}>
          <h3 style={{ color: '#e2e8f0', fontWeight: '700', fontSize: '15px', margin: 0 }}>Assign Trainer</h3>
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: '#4a5568', cursor: 'pointer', fontSize: '20px' }}>×</button>
        </div>
        <p style={{ color: '#4a5568', fontSize: '12.5px', marginBottom: '16px' }}>Select a trainer for <strong style={{ color: '#8892a4' }}>{member.full_name}</strong></p>
        {error && <div style={{ background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.2)', borderRadius: '10px', padding: '10px 14px', marginBottom: '14px', color: '#f87171', fontSize: '13px' }}>{error}</div>}
        <form onSubmit={handleAssign}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', marginBottom: '18px', maxHeight: '260px', overflowY: 'auto' }}>
            <label style={{ display: 'flex', alignItems: 'center', gap: '11px', padding: '11px 12px', borderRadius: '9px', border: `1px solid ${selectedId === '' ? 'rgba(239,68,68,0.35)' : 'rgba(255,255,255,0.07)'}`, background: selectedId === '' ? 'rgba(239,68,68,0.07)' : 'rgba(255,255,255,0.02)', cursor: 'pointer' }}>
              <input type="radio" name="trainer" value="" checked={selectedId === ''} onChange={() => setSelectedId('')} style={{ accentColor: '#ef4444' }} />
              <span style={{ fontSize: '12.5px', color: '#718096' }}>No trainer (remove assignment)</span>
            </label>
            {trainers.filter(t => t.user_id).map(trainer => {
              const palette = ['#2563eb','#7c3aed','#059669','#d97706','#dc2626','#0891b2']
              const color = palette[trainer.full_name?.charCodeAt(0) % palette.length] || '#2563eb'
              const initials = trainer.full_name?.split(' ').slice(0, 2).map(w => w[0]).join('').toUpperCase() || '??'
              return (
                <label key={trainer.id} style={{ display: 'flex', alignItems: 'center', gap: '11px', padding: '11px 12px', borderRadius: '9px', border: `1px solid ${selectedId === trainer.id ? 'rgba(59,130,246,0.35)' : 'rgba(255,255,255,0.07)'}`, background: selectedId === trainer.id ? 'rgba(59,130,246,0.08)' : 'rgba(255,255,255,0.02)', cursor: 'pointer' }}>
                  <input type="radio" name="trainer" value={trainer.id} checked={selectedId === trainer.id} onChange={() => setSelectedId(trainer.id)} style={{ accentColor: '#3b82f6' }} />
                  <div style={{ width: 30, height: 30, borderRadius: '7px', background: color + '20', border: `1px solid ${color}30`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '10px', fontWeight: '700', color }}>{initials}</div>
                  <div>
                    <p style={{ fontSize: '12.5px', fontWeight: '600', color: '#c8d0e0', margin: 0 }}>{trainer.full_name}</p>
                    {trainer.specialty && <p style={{ fontSize: '10.5px', color: '#4a5568', margin: 0 }}>{trainer.specialty}</p>}
                  </div>
                  <span style={{ marginLeft: 'auto', fontSize: '10px', background: 'rgba(34,197,94,0.12)', color: '#22c55e', border: '1px solid rgba(34,197,94,0.25)', borderRadius: '5px', padding: '2px 7px', fontWeight: '600' }}>✓ Has account</span>
                </label>
              )
            })}
            {trainers.filter(t => !t.user_id).length > 0 && <p style={{ fontSize: '10.5px', color: '#2d3748', margin: '4px 0 0', paddingLeft: '4px' }}>{trainers.filter(t => !t.user_id).length} trainer(s) without app accounts cannot be assigned yet.</p>}
          </div>
          <div style={{ display: 'flex', gap: '10px' }}>
            <button type="button" onClick={onClose} style={{ flex: 1, padding: '10px', borderRadius: '10px', border: '1px solid rgba(255,255,255,0.08)', background: 'rgba(255,255,255,0.03)', color: '#718096', cursor: 'pointer', fontWeight: '600', fontSize: '13px' }}>Cancel</button>
            <button type="submit" disabled={loading} style={{ flex: 2, padding: '10px', borderRadius: '10px', border: 'none', background: loading ? 'rgba(59,130,246,0.4)' : 'linear-gradient(135deg, #1d4ed8, #3b82f6)', color: '#fff', cursor: loading ? 'not-allowed' : 'pointer', fontWeight: '700', fontSize: '13px' }}>{loading ? 'Saving…' : 'Assign Trainer'}</button>
          </div>
        </form>
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

// ─── Main Members Component ────────────────────────────────────────────────────
export default function Members() {
  const [members,      setMembers]      = useState(_cache.members)
  const [trainers,     setTrainers]     = useState(_cache.trainers ?? [])
  const [expandedId,   setExpandedId]   = useState(null)
  const [accountModal, setAccountModal] = useState(null)
  const [trainerModal, setTrainerModal] = useState(null)
  const [toast,        setToast]        = useState('')

  useEffect(() => { fetchMembers(); fetchTrainers() }, [])

  async function fetchTrainers() {
    const { data } = await supabase.from('trainers').select('*').order('full_name')
    if (data) { _cache.trainers = data; setTrainers(data) }
  }

  async function fetchMembers() {
    if (_cache.members) setMembers(_cache.members)
    try {
      const { data, error: err } = await supabase.from('members').select('*').eq('membership_status', 'active').order('created_at', { ascending: false })
      if (err) throw err
      _cache.members = data || []; setMembers(_cache.members)
    } catch { if (!_cache.members) setMembers([]) }
  }

  function handleAccountSuccess() { setAccountModal(null); setToast('Member account created!'); _cache.members = null; fetchMembers() }
  function handleTrainerSuccess(trainerId) {
    const name = trainerId ? trainers.find(t => t.id === trainerId)?.full_name : null
    setTrainerModal(null); setToast(name ? `Assigned to ${name}` : 'Trainer removed.')
    _cache.members = null; fetchMembers()
  }
  function getTrainerName(trainerId) { return trainerId ? trainers.find(t => t.id === trainerId)?.full_name || null : null }

  return (
    <Layout>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '22px' }}>
        <div>
          <h1 style={{ fontSize: '22px', fontWeight: '800', color: '#f0f2f8', margin: '0 0 4px', letterSpacing: '-0.3px' }}>Members</h1>
          <p style={{ color: '#4a5568', fontSize: '13px', margin: 0 }}>Manage active members, accounts, and trainer assignments</p>
        </div>
        {members !== null && (
          <div style={{ background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.07)', borderRadius: '10px', padding: '8px 16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '20px', fontWeight: '800', color: '#c8d0e0' }}>{members.length}</span>
            <span style={{ fontSize: '11px', color: '#4a5568', fontWeight: '500' }}>Active Members</span>
          </div>
        )}
      </div>

      {/* Content */}
      {members === null ? (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
          {Array.from({ length: 3 }).map((_, i) => (
            <div key={i} style={{ ...C.card, display: 'flex', gap: '14px', alignItems: 'center' }}>
              <div style={{ width: 40, height: 40, borderRadius: '10px', background: 'rgba(255,255,255,0.04)' }} />
              <div style={{ flex: 1, display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: '10px' }}>
                {Array.from({ length: 6 }).map((__, j) => <div key={j} style={{ height: '10px', background: 'rgba(255,255,255,0.04)', borderRadius: '4px' }} />)}
              </div>
            </div>
          ))}
        </div>
      ) : members.length === 0 ? (
        <div style={{ ...C.card, padding: '70px 24px', textAlign: 'center' }}>
          <div style={{ fontSize: '36px', marginBottom: '10px' }}>👥</div>
          <p style={{ fontWeight: '700', color: '#4a5568', fontSize: '14px', marginBottom: '4px' }}>No active members</p>
          <p style={{ fontSize: '12.5px', color: '#2d3748' }}>Members will appear here after approval</p>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
          {members.map(member => {
            const trainerName = getTrainerName(member.trainer_id)
            const isOpen = expandedId === member.id
            return (
              <div key={member.id} style={{ ...C.card, transition: 'border-color 0.15s', borderColor: isOpen ? 'rgba(59,130,246,0.25)' : 'rgba(255,255,255,0.06)' }}>
                {/* Collapsed Row */}
                <div style={{ display: 'flex', alignItems: 'center', gap: '14px', cursor: 'pointer' }} onClick={() => setExpandedId(isOpen ? null : member.id)}>
                  <Avatar name={member.full_name} size={40} />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap', marginBottom: '3px' }}>
                      <p style={{ fontSize: '14px', fontWeight: '700', color: '#e2e8f0', margin: 0 }}>{member.full_name}</p>
                      {member.user_id
                        ? <span style={{ background: 'rgba(34,197,94,0.12)', color: '#22c55e', border: '1px solid rgba(34,197,94,0.25)', padding: '1px 7px', borderRadius: '5px', fontSize: '9.5px', fontWeight: '700' }}>✓ Account</span>
                        : <span style={{ background: 'rgba(245,158,11,0.12)', color: '#f59e0b', border: '1px solid rgba(245,158,11,0.25)', padding: '1px 7px', borderRadius: '5px', fontSize: '9.5px', fontWeight: '700' }}>No Account</span>
                      }
                      {trainerName
                        ? <span style={{ background: 'rgba(59,130,246,0.1)', color: '#60a5fa', border: '1px solid rgba(59,130,246,0.2)', padding: '1px 7px', borderRadius: '5px', fontSize: '9.5px', fontWeight: '600' }}>👤 {trainerName}</span>
                        : member.wants_trainer ? <span style={{ background: 'rgba(239,68,68,0.08)', color: '#f87171', border: '1px solid rgba(239,68,68,0.2)', padding: '1px 7px', borderRadius: '5px', fontSize: '9.5px', fontWeight: '600' }}>No trainer</span> : null
                      }
                    </div>
                    <p style={{ fontSize: '11.5px', color: '#4a5568', margin: 0 }}>{member.email}</p>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <span style={{ fontSize: '11px', color: '#2d3748', background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.06)', borderRadius: '5px', padding: '2px 8px', fontWeight: '500' }}>{member.membership_type}</span>
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#2d3748" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ transform: isOpen ? 'rotate(180deg)' : 'rotate(0deg)', transition: 'transform 0.2s' }}><polyline points="6 9 12 15 18 9"/></svg>
                  </div>
                </div>

                {/* Expanded Detail */}
                {isOpen && (
                  <div style={{ marginTop: '16px', paddingTop: '16px', borderTop: '1px solid rgba(255,255,255,0.05)' }}>
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '12px 20px', marginBottom: '18px' }}>
                      <Field label="Age / Gender"       value={`${member.age ?? '—'} / ${member.gender ?? '—'}`} />
                      <Field label="Contact"            value={member.contact_number} />
                      <Field label="Goal"               value={member.goal} />
                      <Field label="Height / Weight"    value={`${member.height ? member.height + ' cm' : '—'} / ${member.weight ? member.weight + ' kg' : '—'}`} />
                      <Field label="Expires"            value={member.expiration_date || '—'} />
                      <Field label="Emergency Contact"  value={member.emergency_contact} />
                    </div>
                    <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
                      {!member.user_id ? (
                        <button onClick={() => setAccountModal(member)} style={{ flex: 1, minWidth: '150px', padding: '9px 14px', borderRadius: '9px', background: 'rgba(59,130,246,0.1)', border: '1px solid rgba(59,130,246,0.25)', color: '#60a5fa', fontSize: '12.5px', fontWeight: '600', cursor: 'pointer', transition: 'all 0.15s' }}
                          onMouseEnter={e => e.currentTarget.style.background = 'rgba(59,130,246,0.18)'} onMouseLeave={e => e.currentTarget.style.background = 'rgba(59,130,246,0.1)'}>
                          + Create Account
                        </button>
                      ) : (
                        <div style={{ flex: 1, minWidth: '150px', padding: '9px 14px', borderRadius: '9px', background: 'rgba(34,197,94,0.07)', border: '1px solid rgba(34,197,94,0.2)', color: '#22c55e', fontSize: '12.5px', fontWeight: '600', textAlign: 'center' }}>✓ Account active</div>
                      )}
                      {member.wants_trainer && (
                        <button onClick={() => setTrainerModal(member)} style={{ flex: 1, minWidth: '150px', padding: '9px 14px', borderRadius: '9px', background: trainerName ? 'rgba(59,130,246,0.1)' : 'rgba(245,158,11,0.08)', border: `1px solid ${trainerName ? 'rgba(59,130,246,0.25)' : 'rgba(245,158,11,0.25)'}`, color: trainerName ? '#60a5fa' : '#f59e0b', fontSize: '12.5px', fontWeight: '600', cursor: 'pointer', transition: 'all 0.15s' }}
                          onMouseEnter={e => e.currentTarget.style.opacity = '0.8'} onMouseLeave={e => e.currentTarget.style.opacity = '1'}>
                          {trainerName ? '👤 Change Trainer' : '+ Assign Trainer'}
                        </button>
                      )}
                    </div>
                  </div>
                )}
              </div>
            )
          })}
        </div>
      )}

      {accountModal && <CreateAccountModal member={accountModal} onClose={() => setAccountModal(null)} onSuccess={handleAccountSuccess} />}
      {trainerModal && <AssignTrainerModal member={trainerModal} trainers={trainers} onClose={() => setTrainerModal(null)} onSuccess={handleTrainerSuccess} />}
      {toast && <Toast message={toast} onClose={() => setToast('')} />}
    </Layout>
  )
}