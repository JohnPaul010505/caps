import { useState, useEffect } from 'react'
import { supabase } from '../../services/supabase'
import Layout from '../../components/layout/Layout'

// Module-level cache — survives navigation, resets only on full page refresh
const _cache = { members: null, trainers: null }

function card(style) {
  return {
    background: '#1a1a2e',
    border: '1px solid rgba(255,255,255,0.07)',
    borderRadius: '14px',
    padding: '24px',
    ...style
  }
}

function Avatar({ name, size = 40 }) {
  const initials = name?.split(' ').slice(0, 2).map(w => w[0]).join('').toUpperCase() || '??'
  const colors = ['#7c3aed','#2563eb','#059669','#d97706','#dc2626','#0891b2']
  const color = colors[name?.charCodeAt(0) % colors.length] || '#7c3aed'
  return (
    <div style={{
      width: size, height: size, borderRadius: '50%',
      background: color + '33', border: `1.5px solid ${color}55`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: size * 0.33, fontWeight: '700', color, flexShrink: 0
    }}>{initials}</div>
  )
}

function Field({ label, value }) {
  return (
    <div>
      <p style={{ fontSize: '10px', fontWeight: '600', color: '#3a3a5a', letterSpacing: '0.5px', marginBottom: '3px' }}>{label}</p>
      <p style={{ fontSize: '13px', color: '#c0c0e0' }}>{value ?? '—'}</p>
    </div>
  )
}

// ─── Create Account Modal ────────────────────────────────────────────────────

function CreateAccountModal({ member, onClose, onSuccess }) {
  const [email,    setEmail]    = useState(member.email || '')
  const [password, setPassword] = useState('')
  const [showPw,   setShowPw]   = useState(false)
  const [loading,  setLoading]  = useState(false)
  const [error,    setError]    = useState('')

  async function handleCreate(e) {
    e.preventDefault()
    if (!email.trim() || !password.trim()) {
      setError('Email and password are required.')
      return
    }
    if (password.length < 6) {
      setError('Password must be at least 6 characters.')
      return
    }

    setLoading(true)
    setError('')

    try {
      // Call the Supabase RPC function that creates a user via service role
      const { data, error: rpcErr } = await supabase.rpc('create_member_account', {
        p_email:     email.trim(),
        p_password:  password,
        p_member_id: member.id,
      })

      if (rpcErr) throw new Error(rpcErr.message)
      if (data?.error) throw new Error(data.error)

      onSuccess()
    } catch (err) {
      setError(err.message || 'Failed to create account. Please try again.')
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
    <div style={{
      position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.75)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      zIndex: 50, padding: '20px',
    }}>
      <div style={{
        background: '#1a1a2e',
        border: '1px solid rgba(255,255,255,0.1)',
        borderRadius: '20px', padding: '32px',
        width: '100%', maxWidth: '420px',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '24px' }}>
          <Avatar name={member.full_name} size={44} />
          <div>
            <h3 style={{ color: '#e2e2f0', fontWeight: '700', fontSize: '16px', margin: 0 }}>Create Member Account</h3>
            <p style={{ color: '#5a5a8a', fontSize: '12px', marginTop: '3px' }}>{member.full_name}</p>
          </div>
          <button onClick={onClose} style={{ marginLeft: 'auto', background: 'none', border: 'none', color: '#5a5a8a', cursor: 'pointer', fontSize: '20px', lineHeight: 1 }}>×</button>
        </div>

        <p style={{ color: '#6060a0', fontSize: '13px', marginBottom: '22px', lineHeight: 1.5 }}>
          This creates a login so the member can access the mobile app, log workouts, chat with their trainer, and track progress.
        </p>

        {error && (
          <div style={{ background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.25)', borderRadius: '10px', padding: '11px 14px', marginBottom: '18px', color: '#f87171', fontSize: '13px' }}>
            {error}
          </div>
        )}

        <form onSubmit={handleCreate}>
          <div style={{ marginBottom: '16px' }}>
            <label style={{ display: 'block', fontSize: '11px', fontWeight: '600', color: '#4a4a6a', letterSpacing: '0.5px', marginBottom: '8px' }}>LOGIN EMAIL</label>
            <input
              type="email" value={email} onChange={e => setEmail(e.target.value)}
              placeholder="member@email.com" required disabled={loading}
              style={{ ...inputStyle, opacity: loading ? 0.6 : 1 }}
              onFocus={e => e.target.style.borderColor = 'rgba(124,58,237,0.6)'}
              onBlur={e  => e.target.style.borderColor = 'rgba(255,255,255,0.1)'}
            />
          </div>

          <div style={{ marginBottom: '24px' }}>
            <label style={{ display: 'block', fontSize: '11px', fontWeight: '600', color: '#4a4a6a', letterSpacing: '0.5px', marginBottom: '8px' }}>TEMPORARY PASSWORD</label>
            <div style={{ position: 'relative' }}>
              <input
                type={showPw ? 'text' : 'password'} value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="Min. 6 characters" required disabled={loading}
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
            <p style={{ fontSize: '11px', color: '#3a3a5a', marginTop: '6px' }}>Share this with the member — they can change it after first login.</p>
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

// ─── Assign Trainer Modal ────────────────────────────────────────────────────

function AssignTrainerModal({ member, trainers, onClose, onSuccess }) {
  const [selectedId, setSelectedId] = useState(member.trainer_id || '')
  const [loading,    setLoading]    = useState(false)
  const [error,      setError]      = useState('')

  async function handleAssign(e) {
    e.preventDefault()
    setLoading(true)
    setError('')
    try {
      const { error: updateErr } = await supabase
        .from('members')
        .update({ trainer_id: selectedId || null })
        .eq('id', member.id)
      if (updateErr) throw updateErr
      onSuccess(selectedId || null)
    } catch (err) {
      setError(err.message || 'Failed to assign trainer.')
      setLoading(false)
    }
  }

  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.75)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 50, padding: '20px' }}>
      <div style={{ background: '#1a1a2e', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '20px', padding: '32px', width: '100%', maxWidth: '400px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px' }}>
          <h3 style={{ color: '#e2e2f0', fontWeight: '700', fontSize: '16px', margin: 0 }}>Assign Trainer</h3>
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: '#5a5a8a', cursor: 'pointer', fontSize: '20px' }}>×</button>
        </div>
        <p style={{ color: '#6060a0', fontSize: '13px', marginBottom: '20px' }}>Select a trainer for <strong style={{ color: '#a0a0d0' }}>{member.full_name}</strong></p>

        {error && <div style={{ background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.25)', borderRadius: '10px', padding: '11px 14px', marginBottom: '16px', color: '#f87171', fontSize: '13px' }}>{error}</div>}

        <form onSubmit={handleAssign}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '20px', maxHeight: '260px', overflowY: 'auto' }}>
            {/* No trainer option */}
            <label style={{ display: 'flex', alignItems: 'center', gap: '12px', padding: '12px', borderRadius: '10px', border: `1px solid ${selectedId === '' ? 'rgba(239,68,68,0.4)' : 'rgba(255,255,255,0.08)'}`, background: selectedId === '' ? 'rgba(239,68,68,0.08)' : 'rgba(255,255,255,0.02)', cursor: 'pointer' }}>
              <input type="radio" name="trainer" value="" checked={selectedId === ''} onChange={() => setSelectedId('')} style={{ accentColor: '#ef4444' }} />
              <span style={{ fontSize: '13px', color: '#7070a0' }}>No trainer (remove assignment)</span>
            </label>

            {trainers.filter(t => t.user_id).map(trainer => (
              <label key={trainer.id} style={{ display: 'flex', alignItems: 'center', gap: '12px', padding: '12px', borderRadius: '10px', border: `1px solid ${selectedId === trainer.id ? 'rgba(124,58,237,0.4)' : 'rgba(255,255,255,0.08)'}`, background: selectedId === trainer.id ? 'rgba(124,58,237,0.1)' : 'rgba(255,255,255,0.02)', cursor: 'pointer' }}>
                <input type="radio" name="trainer" value={trainer.id} checked={selectedId === trainer.id} onChange={() => setSelectedId(trainer.id)} style={{ accentColor: '#a855f7' }} />
                <Avatar name={trainer.full_name} size={32} />
                <div>
                  <p style={{ fontSize: '13px', fontWeight: '600', color: '#e2e2f0', margin: 0 }}>{trainer.full_name}</p>
                  {trainer.specialty && <p style={{ fontSize: '11px', color: '#5a5a8a', margin: 0 }}>{trainer.specialty}</p>}
                </div>
                <span style={{ marginLeft: 'auto', fontSize: '11px', background: 'rgba(34,197,94,0.15)', color: '#22c55e', border: '1px solid rgba(34,197,94,0.3)', borderRadius: '20px', padding: '2px 8px', fontWeight: '600' }}>✓ Has account</span>
              </label>
            ))}

            {trainers.filter(t => !t.user_id).length > 0 && (
              <p style={{ fontSize: '11px', color: '#3a3a5a', margin: '4px 0 0', paddingLeft: '4px' }}>
                {trainers.filter(t => !t.user_id).length} trainer(s) without app accounts cannot be assigned yet.
              </p>
            )}
          </div>

          <div style={{ display: 'flex', gap: '10px' }}>
            <button type="button" onClick={onClose} style={{ flex: 1, padding: '11px', borderRadius: '10px', border: '1px solid rgba(255,255,255,0.1)', background: 'rgba(255,255,255,0.05)', color: '#a0a0c0', cursor: 'pointer', fontWeight: '600', fontSize: '13px' }}>Cancel</button>
            <button type="submit" disabled={loading} style={{ flex: 2, padding: '11px', borderRadius: '10px', border: 'none', background: loading ? 'rgba(124,58,237,0.5)' : 'linear-gradient(135deg, #7c3aed, #a855f7)', color: '#fff', cursor: loading ? 'not-allowed' : 'pointer', fontWeight: '700', fontSize: '13px' }}>
              {loading ? 'Saving…' : 'Assign Trainer'}
            </button>
          </div>
        </form>
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

// ─── Main Members Component ──────────────────────────────────────────────────

export default function Members() {
  const [members,       setMembers]       = useState(_cache.members)
  const [trainers,      setTrainers]      = useState(_cache.trainers ?? [])
  const [expandedId,    setExpandedId]    = useState(null)
  const [accountModal,  setAccountModal]  = useState(null) // member object
  const [trainerModal,  setTrainerModal]  = useState(null) // member object
  const [toast,         setToast]         = useState('')

  useEffect(() => {
    fetchMembers()
    fetchTrainers()
  }, [])

  async function fetchTrainers() {
    const { data } = await supabase.from('trainers').select('*').order('full_name')
    if (data) { _cache.trainers = data; setTrainers(data) }
  }

  async function fetchMembers() {
    // If cache exists, show it immediately — skeleton only on very first load
    if (_cache.members) setMembers(_cache.members)
    try {
      const { data, error: err } = await supabase
        .from('members')
        .select('*')
        .eq('membership_status', 'active')
        .order('created_at', { ascending: false })
      if (err) throw err
      _cache.members = data || []
      setMembers(_cache.members)
    } catch {
      if (!_cache.members) setMembers([])
    }
  }

  function handleAccountSuccess() {
    setAccountModal(null)
    setToast('Member account created! They can now log in to the app.')
    _cache.members = null
    fetchMembers()
  }

  function handleTrainerSuccess(trainerId) {
    const trainerName = trainerId ? trainers.find(t => t.id === trainerId)?.full_name : null
    setTrainerModal(null)
    setToast(trainerName ? `Assigned to ${trainerName}` : 'Trainer removed.')
    // Clear cache and refetch so trainer name badge updates immediately
    _cache.members = null
    fetchMembers()
  }

  function getTrainerName(trainerId) {
    if (!trainerId) return null
    return trainers.find(t => t.id === trainerId)?.full_name || null
  }

  return (
    <Layout>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '28px' }}>
        <div>
          <h2 style={{ fontSize: '24px', fontWeight: '800', color: '#fff', margin: 0 }}>Members</h2>
          <p style={{ color: '#5a5a8a', fontSize: '13px', marginTop: '4px' }}>Manage active members, accounts, and trainer assignments</p>
        </div>
        {members !== null && (
          <div style={{ background: 'rgba(124,58,237,0.15)', border: '1px solid rgba(124,58,237,0.3)', borderRadius: '10px', padding: '8px 16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '20px', fontWeight: '800', color: '#a78bfa' }}>{members.length}</span>
            <span style={{ fontSize: '12px', color: '#7060a0' }}>active</span>
          </div>
        )}
      </div>

      {/* Content */}
      {members === null ? (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          {Array.from({ length: 3 }).map((_, i) => (
            <div key={i} style={{ ...card({}), display: 'flex', gap: '16px', alignItems: 'center' }}>
              <div style={{ width: 40, height: 40, borderRadius: '50%', background: 'rgba(255,255,255,0.05)' }} />
              <div style={{ flex: 1, display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: '12px' }}>
                {Array.from({ length: 6 }).map((__, j) => (
                  <div key={j} style={{ height: '12px', background: 'rgba(255,255,255,0.05)', borderRadius: '4px' }} />
                ))}
              </div>
            </div>
          ))}
        </div>
      ) : members.length === 0 ? (
        <div style={{ ...card({ padding: '80px 24px', textAlign: 'center' }) }}>
          <p style={{ fontSize: '40px', marginBottom: '12px' }}>👥</p>
          <p style={{ fontWeight: '700', color: '#6a6a9a', fontSize: '15px', marginBottom: '4px' }}>No active members</p>
          <p style={{ fontSize: '13px', color: '#3a3a5a' }}>Members will appear here after approval</p>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          {members.map(member => {
            const trainerName = getTrainerName(member.trainer_id)
            return (
              <div key={member.id} style={card({})}>
                {/* Collapsed row */}
                <div
                  style={{ display: 'flex', alignItems: 'flex-start', gap: '16px', cursor: 'pointer' }}
                  onClick={() => setExpandedId(expandedId === member.id ? null : member.id)}
                >
                  <Avatar name={member.full_name} />
                  <div style={{ flex: 1 }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap', marginBottom: '4px' }}>
                      <p style={{ fontSize: '15px', fontWeight: '700', color: '#e2e2f0', margin: 0 }}>{member.full_name}</p>
                      {/* Account badge */}
                      {member.user_id
                        ? <span style={{ background: 'rgba(34,197,94,0.15)', color: '#22c55e', border: '1px solid rgba(34,197,94,0.3)', padding: '2px 8px', borderRadius: '20px', fontSize: '10px', fontWeight: '600' }}>✓ Account</span>
                        : <span style={{ background: 'rgba(245,158,11,0.15)', color: '#f59e0b', border: '1px solid rgba(245,158,11,0.3)', padding: '2px 8px', borderRadius: '20px', fontSize: '10px', fontWeight: '600' }}>⚠ No Account</span>
                      }
                      {/* Trainer badge */}
                      {trainerName
                        ? <span style={{ background: 'rgba(59,130,246,0.15)', color: '#60a5fa', border: '1px solid rgba(59,130,246,0.3)', padding: '2px 8px', borderRadius: '20px', fontSize: '10px', fontWeight: '600' }}>👤 {trainerName}</span>
                        : member.wants_trainer
                          ? <span style={{ background: 'rgba(239,68,68,0.1)', color: '#f87171', border: '1px solid rgba(239,68,68,0.25)', padding: '2px 8px', borderRadius: '20px', fontSize: '10px', fontWeight: '600' }}>No trainer assigned</span>
                          : null
                      }
                    </div>
                    <p style={{ fontSize: '13px', color: '#5a5a8a', margin: 0 }}>{member.email}</p>
                  </div>
                  <div style={{ color: '#5a5a8a', fontSize: '12px' }}>{expandedId === member.id ? '▼' : '▶'}</div>
                </div>

                {/* Expanded detail */}
                {expandedId === member.id && (
                  <div style={{ marginTop: '20px', paddingTop: '20px', borderTop: '1px solid rgba(255,255,255,0.07)' }}>
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '14px 24px', marginBottom: '20px' }}>
                      <Field label="AGE / GENDER" value={`${member.age ?? '—'} / ${member.gender ?? '—'}`} />
                      <Field label="CONTACT" value={member.contact_number} />
                      <Field label="MEMBERSHIP" value={member.membership_type} />
                      <Field label="GOAL" value={member.goal} />
                      <Field label="HEIGHT / WEIGHT" value={`${member.height ? member.height + ' cm' : '—'} / ${member.weight ? member.weight + ' kg' : '—'}`} />
                      <Field label="EXPIRES" value={member.expiration_date || '—'} />
                      <Field label="EMERGENCY CONTACT" value={member.emergency_contact} />
                    </div>

                    {/* Action buttons */}
                    <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                      {/* Create / Account created */}
                      {!member.user_id ? (
                        <button
                          onClick={() => setAccountModal(member)}
                          style={{ flex: 1, minWidth: '160px', padding: '10px', borderRadius: '10px', background: 'rgba(124,58,237,0.15)', border: '1px solid rgba(124,58,237,0.3)', color: '#a78bfa', fontSize: '13px', fontWeight: '600', cursor: 'pointer' }}
                          onMouseEnter={e => e.currentTarget.style.background = 'rgba(124,58,237,0.25)'}
                          onMouseLeave={e => e.currentTarget.style.background = 'rgba(124,58,237,0.15)'}
                        >
                          + Create Account
                        </button>
                      ) : (
                        <div style={{ flex: 1, minWidth: '160px', padding: '10px', borderRadius: '10px', background: 'rgba(34,197,94,0.1)', border: '1px solid rgba(34,197,94,0.25)', color: '#22c55e', fontSize: '13px', fontWeight: '600', textAlign: 'center' }}>
                          ✓ Account active
                        </div>
                      )}

                      {/* Assign Trainer */}
                      {member.wants_trainer && (
                        <button
                          onClick={() => setTrainerModal(member)}
                          style={{ flex: 1, minWidth: '160px', padding: '10px', borderRadius: '10px', background: trainerName ? 'rgba(59,130,246,0.15)' : 'rgba(245,158,11,0.12)', border: `1px solid ${trainerName ? 'rgba(59,130,246,0.3)' : 'rgba(245,158,11,0.3)'}`, color: trainerName ? '#60a5fa' : '#f59e0b', fontSize: '13px', fontWeight: '600', cursor: 'pointer' }}
                          onMouseEnter={e => e.currentTarget.style.opacity = '0.8'}
                          onMouseLeave={e => e.currentTarget.style.opacity = '1'}
                        >
                          {trainerName ? `👤 Change Trainer` : '+ Assign Trainer'}
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

      {/* Modals */}
      {accountModal && (
        <CreateAccountModal
          member={accountModal}
          onClose={() => setAccountModal(null)}
          onSuccess={handleAccountSuccess}
        />
      )}
      {trainerModal && (
        <AssignTrainerModal
          member={trainerModal}
          trainers={trainers}
          onClose={() => setTrainerModal(null)}
          onSuccess={handleTrainerSuccess}
        />
      )}

      {/* Toast */}
      {toast && <Toast message={toast} onClose={() => setToast('')} />}
    </Layout>
  )
}