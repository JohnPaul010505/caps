import { useEffect, useState } from 'react'
import { supabase } from '../../services/supabase'
import Layout from '../../components/layout/Layout'

const ALL_DAYS = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']

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

export default function Trainers() {
  const [trainers, setTrainers] = useState(null)
  const [error,    setError]    = useState(false)
  const [waking,   setWaking]   = useState(false)
  const [showForm, setShowForm] = useState(false)
  const [form,     setForm]     = useState({ full_name: '', specialty: '', available_days: [] })
  const [saving,   setSaving]   = useState(false)

  useEffect(() => { fetchTrainers() }, [])

  async function fetchTrainers() {
    setError(false)
    setTrainers(null)
    setWaking(false)
    const wakingTimer = setTimeout(() => setWaking(true), 5000)
    try {
      const { data, error: err } = await withTimeout(
        supabase.from('trainers').select('*').order('created_at', { ascending: false })
      )
      clearTimeout(wakingTimer)
      setWaking(false)
      if (err) throw err
      setTrainers(data || [])
    } catch {
      clearTimeout(wakingTimer)
      setWaking(false)
      setError(true)
      setTrainers([])
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
    setSaving(true)
    const { data } = await supabase.from('trainers').insert({
      full_name: form.full_name, specialty: form.specialty, available_days: form.available_days,
    }).select().single()
    if (data) setTrainers(prev => [data, ...(prev || [])])
    setForm({ full_name: '', specialty: '', available_days: [] })
    setShowForm(false)
    setSaving(false)
  }

  async function handleDelete(id) {
    await supabase.from('trainers').delete().eq('id', id)
    setTrainers(prev => (prev || []).filter(t => t.id !== id))
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
          <p style={{ color: '#5a5a8a', fontSize: '13px', marginTop: '4px' }}>Manage all gym trainers</p>
        </div>
        <div style={{ display: 'flex', gap: '10px' }}>
          {error && (
            <button onClick={fetchTrainers} style={{ background: 'rgba(255,255,255,0.06)', border: '1px solid rgba(255,255,255,0.1)', color: '#9090c0', borderRadius: '10px', padding: '10px 16px', fontSize: '13px', fontWeight: '600', cursor: 'pointer' }}>↻ Retry</button>
          )}
          <button onClick={() => setShowForm(!showForm)} style={{
            background: 'linear-gradient(135deg, #7c3aed, #a855f7)',
            color: '#fff', border: 'none', borderRadius: '10px',
            padding: '10px 18px', fontSize: '13px', fontWeight: '600',
            cursor: 'pointer', boxShadow: '0 4px 15px rgba(124,58,237,0.4)'
          }}>+ Add Trainer</button>
        </div>
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
          ⚠️ Could not load trainers. Check your Supabase project is active, then retry.
        </div>
      )}

      {/* Add Form */}
      {showForm && (
        <div style={{ ...card({}), marginBottom: '20px' }}>
          <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#e2e2f0', marginBottom: '18px' }}>New Trainer</h3>
          <form onSubmit={handleAdd}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '16px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '11px', fontWeight: '600', color: '#4a4a6a', marginBottom: '6px', letterSpacing: '0.5px' }}>FULL NAME *</label>
                <input type="text" placeholder="e.g. Mike Santos" value={form.full_name} required
                  onChange={e => setForm({ ...form, full_name: e.target.value })}
                  style={inputStyle}
                  onFocus={e => e.target.style.borderColor = 'rgba(124,58,237,0.5)'}
                  onBlur={e  => e.target.style.borderColor = 'rgba(255,255,255,0.1)'}
                />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '11px', fontWeight: '600', color: '#4a4a6a', marginBottom: '6px', letterSpacing: '0.5px' }}>SPECIALTY</label>
                <input type="text" placeholder="e.g. Strength & Conditioning" value={form.specialty}
                  onChange={e => setForm({ ...form, specialty: e.target.value })}
                  style={inputStyle}
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
                    padding: '6px 14px', borderRadius: '20px', fontSize: '12px', fontWeight: '600',
                    cursor: 'pointer', transition: 'all 0.15s',
                    background: form.available_days.includes(day) ? 'linear-gradient(135deg, #7c3aed, #a855f7)' : 'rgba(255,255,255,0.05)',
                    color: form.available_days.includes(day) ? '#fff' : '#5a5a8a',
                    border: form.available_days.includes(day) ? '1px solid transparent' : '1px solid rgba(255,255,255,0.08)',
                  }}>{day}</button>
                ))}
              </div>
            </div>
            <div style={{ display: 'flex', gap: '10px' }}>
              <button type="submit" disabled={saving} style={{
                background: 'linear-gradient(135deg, #7c3aed, #a855f7)', color: '#fff',
                border: 'none', borderRadius: '10px', padding: '10px 24px',
                fontSize: '13px', fontWeight: '600', cursor: 'pointer', opacity: saving ? 0.6 : 1
              }}>{saving ? 'Saving…' : 'Save Trainer'}</button>
              <button type="button" onClick={() => { setShowForm(false); setForm({ full_name: '', specialty: '', available_days: [] }) }} style={{
                background: 'rgba(255,255,255,0.05)', border: '1px solid rgba(255,255,255,0.08)',
                color: '#7070a0', borderRadius: '10px', padding: '10px 20px',
                fontSize: '13px', fontWeight: '600', cursor: 'pointer'
              }}>Cancel</button>
            </div>
          </form>
        </div>
      )}

      {/* Table */}
      <div style={card({})}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.06)' }}>
              {['Trainer','Specialty','Available Days','Actions'].map(h => (
                <th key={h} style={{ padding: '0 12px 12px 0', textAlign: 'left', fontSize: '11px', fontWeight: '600', color: '#4a4a6a', letterSpacing: '0.5px' }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {trainers === null ? (
              Array.from({ length: 4 }).map((_, i) => (
                <tr key={i} style={{ borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                  {[160,120,200,60].map((w, j) => (
                    <td key={j} style={{ padding: '14px 12px 14px 0' }}>
                      <div style={{ height: '12px', background: 'rgba(255,255,255,0.05)', borderRadius: '4px', width: w }} />
                    </td>
                  ))}
                </tr>
              ))
            ) : trainers.length === 0 ? (
              <tr><td colSpan={4}>
                <div style={{ textAlign: 'center', padding: '60px 0', color: '#4a4a6a' }}>
                  <p style={{ fontSize: '32px', marginBottom: '10px' }}>💪</p>
                  <p style={{ fontWeight: '600', color: '#6a6a9a', marginBottom: '4px' }}>No trainers yet</p>
                  <p style={{ fontSize: '12px' }}>Click Add Trainer to get started</p>
                </div>
              </td></tr>
            ) : trainers.map((t, i) => (
              <tr key={t.id} style={{ borderBottom: i < trainers.length - 1 ? '1px solid rgba(255,255,255,0.04)' : 'none' }}>
                <td style={{ padding: '13px 12px 13px 0' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <Avatar name={t.full_name} />
                    <span style={{ fontSize: '13px', fontWeight: '600', color: '#e2e2f0' }}>{t.full_name}</span>
                  </div>
                </td>
                <td style={{ padding: '13px 12px 13px 0', fontSize: '13px', color: '#7070a0' }}>{t.specialty ?? '—'}</td>
                <td style={{ padding: '13px 12px 13px 0' }}>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: '5px' }}>
                    {t.available_days?.length > 0
                      ? t.available_days.map(day => (
                          <span key={day} style={{ padding: '2px 9px', borderRadius: '20px', fontSize: '11px', fontWeight: '600', background: 'rgba(124,58,237,0.2)', color: '#a78bfa', border: '1px solid rgba(124,58,237,0.3)' }}>{day}</span>
                        ))
                      : <span style={{ color: '#3a3a5a', fontSize: '13px' }}>—</span>
                    }
                  </div>
                </td>
                <td style={{ padding: '13px 0 13px 0' }}>
                  <button onClick={() => handleDelete(t.id)}
                    style={{ background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.2)', color: '#f87171', borderRadius: '8px', padding: '5px 12px', fontSize: '12px', fontWeight: '600', cursor: 'pointer' }}
                    onMouseEnter={e => { e.currentTarget.style.background = 'rgba(239,68,68,0.2)' }}
                    onMouseLeave={e => { e.currentTarget.style.background = 'rgba(239,68,68,0.1)' }}
                  >Remove</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Layout>
  )
}