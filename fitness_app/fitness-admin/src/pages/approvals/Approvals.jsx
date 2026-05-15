import { useEffect, useState } from 'react'
import { supabase } from '../../services/supabase'
import Layout from '../../components/layout/Layout'

// Module-level cache — survives navigation, resets only on full page refresh
const _cache = { pending: null }

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

function Field({ label, value }) {
  return (
    <div>
      <p style={{ fontSize: '10px', fontWeight: '600', color: '#3a3a5a', letterSpacing: '0.5px', marginBottom: '3px' }}>{label}</p>
      <p style={{ fontSize: '13px', color: '#c0c0e0' }}>{value ?? '—'}</p>
    </div>
  )
}

export default function Approvals() {
  const [pending,       setPending]       = useState(_cache.pending)
  const [actionLoading, setActionLoading] = useState(null)

  useEffect(() => { fetchPending() }, [])

  async function fetchPending() {
    // Serve cache immediately — skeleton only on very first load
    if (_cache.pending) setPending(_cache.pending)
    try {
      const { data, error: err } = await supabase
        .from('members')
        .select('*')
        .eq('membership_status', 'pending')
        .order('created_at', { ascending: false })
      if (err) throw err
      _cache.pending = data || []
      setPending(_cache.pending)
    } catch {
      if (!_cache.pending) setPending([])
    }
  }

  async function handleAccept(member) {
    setActionLoading(member.id)
    try {
      let months = 1
      if (member.membership_type === 'Quarterly') months = 3
      else if (member.membership_type === '6 Months') months = 6
      else if (member.membership_type === 'Annual')   months = 12
      const exp = new Date()
      exp.setMonth(exp.getMonth() + months)
      const expiration_date = exp.toISOString().split('T')[0]
      await supabase.from('members').update({ membership_status: 'active', expiration_date }).eq('id', member.id)
      const updated = (pending || []).filter(m => m.id !== member.id)
      _cache.pending = updated
      setPending(updated)
    } catch { /* ignore */ }
    finally { setActionLoading(null) }
  }

  async function handleReject(id) {
    setActionLoading(id)
    try {
      await supabase.from('members').delete().eq('id', id)
      const updated = (pending || []).filter(m => m.id !== id)
      _cache.pending = updated
      setPending(updated)
    } catch { /* ignore */ }
    finally { setActionLoading(null) }
  }

  return (
    <Layout>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '28px' }}>
        <div>
          <h2 style={{ fontSize: '24px', fontWeight: '800', color: '#fff', margin: 0 }}>Approvals</h2>
          <p style={{ color: '#5a5a8a', fontSize: '13px', marginTop: '4px' }}>Review and approve pending member registrations</p>
        </div>
        {pending !== null && (
          <div style={{ background: 'rgba(124,58,237,0.15)', border: '1px solid rgba(124,58,237,0.3)', borderRadius: '10px', padding: '8px 16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '20px', fontWeight: '800', color: '#a78bfa' }}>{pending.length}</span>
            <span style={{ fontSize: '12px', color: '#7060a0' }}>pending</span>
          </div>
        )}
      </div>

      {/* Content */}
      {pending === null ? (
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
      ) : pending.length === 0 ? (
        <div style={{ ...card({ padding: '80px 24px', textAlign: 'center' }) }}>
          <p style={{ fontSize: '40px', marginBottom: '12px' }}>✅</p>
          <p style={{ fontWeight: '700', color: '#6a6a9a', fontSize: '15px', marginBottom: '4px' }}>No pending registrations</p>
          <p style={{ fontSize: '13px', color: '#3a3a5a' }}>All registrations have been reviewed</p>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          {pending.map(member => (
            <div key={member.id} style={{
              ...card({}),
              borderColor: actionLoading === member.id ? 'rgba(124,58,237,0.3)' : 'rgba(255,255,255,0.07)',
              transition: 'border-color 0.2s'
            }}>
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: '16px' }}>
                {/* Avatar + name */}
                <Avatar name={member.full_name} />
                <div style={{ flex: 1 }}>
                  <p style={{ fontSize: '15px', fontWeight: '700', color: '#e2e2f0', marginBottom: '14px' }}>{member.full_name}</p>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '14px 24px' }}>
                    <Field label="AGE / GENDER"        value={`${member.age ?? '—'} / ${member.gender ?? '—'}`} />
                    <Field label="EMAIL"               value={member.email} />
                    <Field label="CONTACT"             value={member.contact_number} />
                    <Field label="MEMBERSHIP"          value={member.membership_type} />
                    <Field label="GOAL"                value={member.goal} />
                    <Field label="HEIGHT / WEIGHT"     value={`${member.height ? member.height + ' cm' : '—'} / ${member.weight ? member.weight + ' kg' : '—'}`} />
                    <Field label="WANTS TRAINER"       value={member.wants_trainer ? 'Yes' : 'No'} />
                    <Field label="EMERGENCY CONTACT"   value={member.emergency_contact} />
                    <Field label="SUBMITTED"           value={member.created_at ? new Date(member.created_at).toLocaleString() : '—'} />
                  </div>
                </div>

                {/* Actions */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', minWidth: '110px' }}>
                  <button
                    onClick={() => handleAccept(member)}
                    disabled={actionLoading === member.id}
                    style={{
                      background: actionLoading === member.id ? 'rgba(34,197,94,0.15)' : 'rgba(34,197,94,0.15)',
                      border: '1px solid rgba(34,197,94,0.3)', color: '#22c55e',
                      borderRadius: '10px', padding: '9px 0', fontSize: '13px',
                      fontWeight: '600', cursor: 'pointer', opacity: actionLoading === member.id ? 0.5 : 1,
                      transition: 'all 0.15s',
                    }}
                    onMouseEnter={e => { if (actionLoading !== member.id) e.currentTarget.style.background = 'rgba(34,197,94,0.25)' }}
                    onMouseLeave={e => { e.currentTarget.style.background = 'rgba(34,197,94,0.15)' }}
                  >
                    {actionLoading === member.id ? '…' : '✓ Accept'}
                  </button>
                  <button
                    onClick={() => handleReject(member.id)}
                    disabled={actionLoading === member.id}
                    style={{
                      background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.25)',
                      color: '#f87171', borderRadius: '10px', padding: '9px 0',
                      fontSize: '13px', fontWeight: '600', cursor: 'pointer',
                      opacity: actionLoading === member.id ? 0.5 : 1, transition: 'all 0.15s',
                    }}
                    onMouseEnter={e => { if (actionLoading !== member.id) e.currentTarget.style.background = 'rgba(239,68,68,0.2)' }}
                    onMouseLeave={e => { e.currentTarget.style.background = 'rgba(239,68,68,0.1)' }}
                  >
                    {actionLoading === member.id ? '…' : '✕ Reject'}
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </Layout>
  )
}