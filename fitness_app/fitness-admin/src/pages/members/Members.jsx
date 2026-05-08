import { useEffect, useState } from 'react'
import { supabase } from '../../services/supabase'
import Layout from '../../components/layout/Layout'

function withTimeout(promise, ms = 30000) {
  return Promise.race([
    promise,
    new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), ms))
  ])
}

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

function StatusBadge({ status }) {
  const map = {
    active:   { bg: '#22c55e1a', color: '#22c55e', border: '#22c55e40' },
    inactive: { bg: '#6b728020', color: '#9ca3af', border: '#6b728040' },
    expired:  { bg: '#ef44441a', color: '#f87171', border: '#ef444440' },
    terminated: { bg: '#6b728020', color: '#6b7280', border: '#6b728040' },
  }
  const s = map[status] || map.inactive
  return (
    <span style={{
      padding: '3px 10px', borderRadius: '20px', fontSize: '11.5px',
      fontWeight: '600', background: s.bg, color: s.color, border: `1px solid ${s.border}`,
      textTransform: 'capitalize'
    }}>{status}</span>
  )
}

export default function Members() {
  const [members, setMembers] = useState(null)
  const [search,  setSearch]  = useState('')
  const [error,   setError]   = useState(false)
  const [waking,  setWaking]  = useState(false)

  useEffect(() => { fetchMembers() }, [])

  async function fetchMembers() {
    setError(false)
    setMembers(null)
    setWaking(false)
    const wakingTimer = setTimeout(() => setWaking(true), 5000)
    try {
      const { data, error: err } = await withTimeout(
        supabase.from('members').select('*').neq('membership_status', 'pending').order('created_at', { ascending: false })
      )
      clearTimeout(wakingTimer)
      setWaking(false)
      if (err) throw err
      setMembers(data || [])
    } catch {
      clearTimeout(wakingTimer)
      setWaking(false)
      setError(true)
      setMembers([])
    }
  }

  const filtered = (members || []).filter(m =>
    m.full_name?.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <Layout>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '28px' }}>
        <div>
          <h2 style={{ fontSize: '24px', fontWeight: '800', color: '#fff', margin: 0 }}>Members</h2>
          <p style={{ color: '#5a5a8a', fontSize: '13px', marginTop: '4px' }}>Manage all gym members</p>
        </div>
        {error && (
          <button onClick={fetchMembers} style={{
            background: 'linear-gradient(135deg, #7c3aed, #a855f7)',
            color: '#fff', border: 'none', borderRadius: '10px',
            padding: '10px 18px', fontSize: '13px', fontWeight: '600', cursor: 'pointer'
          }}>↻ Retry</button>
        )}
      </div>

      {/* Banners */}
      {waking && !error && (
        <div style={{ background: 'rgba(124,58,237,0.15)', border: '1px solid rgba(124,58,237,0.3)', borderRadius: '10px', padding: '12px 16px', marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '10px', color: '#a78bfa', fontSize: '13px' }}>
          <svg style={{ animation: 'spin 1s linear infinite', flexShrink: 0 }} width="15" height="15" viewBox="0 0 24 24" fill="none">
            <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
            <circle opacity=".25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
            <path opacity=".75" fill="currentColor" d="M4 12a8 8 0 018-8v8z"/>
          </svg>
          Waking up database… please wait.
        </div>
      )}
      {error && (
        <div style={{ background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.25)', borderRadius: '10px', padding: '12px 16px', marginBottom: '20px', color: '#f87171', fontSize: '13px' }}>
          ⚠️ Could not load members. Check your Supabase project is active, then retry.
        </div>
      )}

      {/* Table Card */}
      <div style={card({})}>
        {/* Search */}
        <div style={{ marginBottom: '20px' }}>
          <div style={{ position: 'relative', maxWidth: '320px' }}>
            <svg style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#4a4a6a' }} width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
            <input
              type="text"
              placeholder="Search members..."
              value={search}
              onChange={e => setSearch(e.target.value)}
              style={{
                width: '100%', background: 'rgba(255,255,255,0.04)',
                border: '1px solid rgba(255,255,255,0.08)', borderRadius: '10px',
                padding: '9px 14px 9px 36px', fontSize: '13px', color: '#e2e2f0',
                outline: 'none', boxSizing: 'border-box',
              }}
              onFocus={e => e.target.style.borderColor = 'rgba(124,58,237,0.5)'}
              onBlur={e  => e.target.style.borderColor = 'rgba(255,255,255,0.08)'}
            />
          </div>
        </div>

        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
              {['Member','Age','Goal','Status','Expiration'].map(h => (
                <th key={h} style={{ padding: '0 12px 12px 0', textAlign: 'left', fontSize: '11px', fontWeight: '600', color: '#4a4a6a', letterSpacing: '0.5px' }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {members === null ? (
              Array.from({ length: 6 }).map((_, i) => (
                <tr key={i} style={{ borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                  {[160,40,100,70,90].map((w, j) => (
                    <td key={j} style={{ padding: '14px 12px 14px 0' }}>
                      <div style={{ height: '12px', background: 'rgba(255,255,255,0.05)', borderRadius: '4px', width: w }} />
                    </td>
                  ))}
                </tr>
              ))
            ) : filtered.length === 0 ? (
              <tr><td colSpan={5}>
                <div style={{ textAlign: 'center', padding: '60px 0', color: '#4a4a6a' }}>
                  <p style={{ fontSize: '32px', marginBottom: '10px' }}>👥</p>
                  <p style={{ fontWeight: '600', color: '#6a6a9a', marginBottom: '4px' }}>{search ? 'No members match your search' : 'No members yet'}</p>
                  <p style={{ fontSize: '12px' }}>Approved members will appear here</p>
                </div>
              </td></tr>
            ) : filtered.map((m, i) => (
              <tr key={m.id} style={{ borderBottom: i < filtered.length - 1 ? '1px solid rgba(255,255,255,0.04)' : 'none' }}>
                <td style={{ padding: '13px 12px 13px 0' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <Avatar name={m.full_name} />
                    <span style={{ fontSize: '13px', fontWeight: '600', color: '#e2e2f0' }}>{m.full_name}</span>
                  </div>
                </td>
                <td style={{ padding: '13px 12px 13px 0', fontSize: '13px', color: '#7070a0' }}>{m.age ?? '—'}</td>
                <td style={{ padding: '13px 12px 13px 0', fontSize: '13px', color: '#7070a0' }}>{m.goal ?? '—'}</td>
                <td style={{ padding: '13px 12px 13px 0' }}><StatusBadge status={m.membership_status} /></td>
                <td style={{ padding: '13px 0 13px 0', fontSize: '13px', color: '#7070a0' }}>{m.expiration_date ?? '—'}</td>
              </tr>
            ))}
          </tbody>
        </table>

        {/* Footer count */}
        {members !== null && filtered.length > 0 && (
          <p style={{ marginTop: '16px', fontSize: '12px', color: '#3a3a5a', borderTop: '1px solid rgba(255,255,255,0.04)', paddingTop: '14px' }}>
            Showing {filtered.length} of {members.length} members
          </p>
        )}
      </div>
    </Layout>
  )
}