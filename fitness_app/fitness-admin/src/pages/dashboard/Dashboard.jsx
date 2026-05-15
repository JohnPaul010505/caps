import { useEffect, useState } from 'react'
import { supabase } from '../../services/supabase'
import Layout from '../../components/layout/Layout'

// Module-level cache — survives navigation, resets only on full page refresh
const _cache = { stats: null, recent: null, pending: null }

function StatCard({ icon, label, value, sub, color = '#7c3aed' }) {
  return (
    <div style={{
      background: '#1a1a2e',
      border: '1px solid rgba(255,255,255,0.07)',
      borderRadius: '14px',
      padding: '22px 24px',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
        <span style={{ fontSize: '22px' }}>{icon}</span>
        <div style={{
          width: '8px', height: '8px', borderRadius: '50%',
          background: color, boxShadow: `0 0 8px ${color}`,
        }} />
      </div>
      <p style={{ fontSize: '28px', fontWeight: '800', color: '#fff', margin: '0 0 4px', lineHeight: 1 }}>{value}</p>
      <p style={{ fontSize: '13px', color: '#7070a0', margin: 0 }}>{label}</p>
      {sub && <p style={{ fontSize: '11px', color: '#4a4a6a', margin: '6px 0 0' }}>{sub}</p>}
    </div>
  )
}

function RecentItem({ name, label, time, dot = '#7c3aed' }) {
  const initials = name?.split(' ').slice(0, 2).map(w => w[0]).join('').toUpperCase() || '??'
  const colors = ['#7c3aed','#2563eb','#059669','#d97706','#dc2626','#0891b2']
  const color  = colors[name?.charCodeAt(0) % colors.length] || '#7c3aed'
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: '12px', padding: '12px 0', borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
      <div style={{
        width: 36, height: 36, borderRadius: '50%', flexShrink: 0,
        background: color + '22', border: `1.5px solid ${color}44`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: '12px', fontWeight: '700', color,
      }}>{initials}</div>
      <div style={{ flex: 1 }}>
        <p style={{ fontSize: '13px', fontWeight: '600', color: '#e2e2f0', margin: 0 }}>{name}</p>
        <p style={{ fontSize: '11px', color: '#5a5a8a', margin: '2px 0 0' }}>{label}</p>
      </div>
      <p style={{ fontSize: '11px', color: '#4a4a6a', flexShrink: 0 }}>{time}</p>
    </div>
  )
}

function fmt(dateStr) {
  if (!dateStr) return '—'
  const d = new Date(dateStr)
  const now = new Date()
  const diff = Math.floor((now - d) / 1000)
  if (diff < 60)  return 'just now'
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`
  return `${Math.floor(diff / 86400)}d ago`
}

export default function Dashboard() {
  const [stats,    setStats]    = useState(_cache.stats)
  const [recent,   setRecent]   = useState(_cache.recent ?? [])
  const [pending,  setPending]  = useState(_cache.pending ?? [])
  const [loading,  setLoading]  = useState(!_cache.stats)

  useEffect(() => { load() }, [])

  async function load() {
    // If cache exists, show immediately — no skeleton flash on navigation
    if (_cache.stats) {
      setStats(_cache.stats)
      setRecent(_cache.recent ?? [])
      setPending(_cache.pending ?? [])
      setLoading(false)
    }
    try {
      const [
        { count: activeCount },
        { count: pendingCount },
        { count: trainerCount },
        { data: recentMembers },
        { data: pendingMembers },
        { data: expiringMembers },
      ] = await Promise.all([
        supabase.from('members').select('*', { count: 'exact', head: true }).eq('membership_status', 'active'),
        supabase.from('members').select('*', { count: 'exact', head: true }).eq('membership_status', 'pending'),
        supabase.from('trainers').select('*', { count: 'exact', head: true }),
        supabase.from('members').select('id, full_name, membership_type, created_at').eq('membership_status', 'active').order('created_at', { ascending: false }).limit(5),
        supabase.from('members').select('id, full_name, membership_type, created_at').eq('membership_status', 'pending').order('created_at', { ascending: false }).limit(5),
        supabase.from('members').select('id, full_name, expiration_date').eq('membership_status', 'active').lte('expiration_date', new Date(Date.now() + 7 * 86400000).toISOString().split('T')[0]).gte('expiration_date', new Date().toISOString().split('T')[0]),
      ])

      _cache.stats = {
        active:   activeCount  || 0,
        pending:  pendingCount || 0,
        trainers: trainerCount || 0,
        expiring: expiringMembers?.length || 0,
      }
      _cache.recent  = recentMembers  || []
      _cache.pending = pendingMembers || []

      setStats(_cache.stats)
      setRecent(_cache.recent)
      setPending(_cache.pending)
    } catch {
      // fail silently — show zeros only if no cache
      if (!_cache.stats) setStats({ active: 0, pending: 0, trainers: 0, expiring: 0 })
    }
    setLoading(false)
  }

  return (
    <Layout>
      {/* Header */}
      <div style={{ marginBottom: '28px' }}>
        <h2 style={{ fontSize: '24px', fontWeight: '800', color: '#fff', margin: 0 }}>Dashboard</h2>
        <p style={{ color: '#5a5a8a', fontSize: '13px', marginTop: '4px' }}>Welcome back, Admin — here's what's happening today</p>
      </div>

      {/* Stat Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '14px', marginBottom: '28px' }}>
        {loading ? (
          Array.from({ length: 4 }).map((_, i) => (
            <div key={i} style={{ background: '#1a1a2e', border: '1px solid rgba(255,255,255,0.07)', borderRadius: '14px', padding: '22px 24px', height: '110px' }}>
              <div style={{ height: '12px', background: 'rgba(255,255,255,0.05)', borderRadius: '4px', marginBottom: '16px', width: '50%' }} />
              <div style={{ height: '28px', background: 'rgba(255,255,255,0.05)', borderRadius: '6px', marginBottom: '10px', width: '40%' }} />
              <div style={{ height: '10px', background: 'rgba(255,255,255,0.04)', borderRadius: '4px', width: '70%' }} />
            </div>
          ))
        ) : (
          <>
            <StatCard icon="👥" label="Active Members"   value={stats?.active}   color="#22c55e"  sub="Currently enrolled" />
            <StatCard icon="⏳" label="Pending Approval" value={stats?.pending}  color="#f59e0b"  sub="Waiting for review" />
            <StatCard icon="💪" label="Trainers"          value={stats?.trainers} color="#7c3aed"  sub="On the team" />
            <StatCard icon="⚠️" label="Expiring Soon"    value={stats?.expiring} color="#ef4444"  sub="Within 7 days" />
          </>
        )}
      </div>

      {/* Lower grid */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '18px' }}>

        {/* Recent Active Members */}
        <div style={{ background: '#1a1a2e', border: '1px solid rgba(255,255,255,0.07)', borderRadius: '14px', padding: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '4px' }}>
            <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#e2e2f0', margin: 0 }}>Recent Members</h3>
            <span style={{ fontSize: '11px', color: '#4a4a6a' }}>Latest active</span>
          </div>
          <p style={{ fontSize: '12px', color: '#4a4a6a', margin: '0 0 16px' }}>Most recently approved</p>
          {loading ? (
            Array.from({ length: 4 }).map((_, i) => (
              <div key={i} style={{ display: 'flex', gap: '12px', alignItems: 'center', padding: '12px 0', borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                <div style={{ width: 36, height: 36, borderRadius: '50%', background: 'rgba(255,255,255,0.05)', flexShrink: 0 }} />
                <div style={{ flex: 1 }}>
                  <div style={{ height: '12px', background: 'rgba(255,255,255,0.05)', borderRadius: '4px', marginBottom: '6px', width: '60%' }} />
                  <div style={{ height: '10px', background: 'rgba(255,255,255,0.04)', borderRadius: '4px', width: '40%' }} />
                </div>
              </div>
            ))
          ) : recent.length === 0 ? (
            <p style={{ color: '#4a4a6a', fontSize: '13px', textAlign: 'center', padding: '24px 0' }}>No active members yet</p>
          ) : (
            recent.map(m => (
              <RecentItem key={m.id} name={m.full_name} label={m.membership_type || 'Member'} time={fmt(m.created_at)} />
            ))
          )}
        </div>

        {/* Pending Approvals */}
        <div style={{ background: '#1a1a2e', border: '1px solid rgba(255,255,255,0.07)', borderRadius: '14px', padding: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '4px' }}>
            <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#e2e2f0', margin: 0 }}>Pending Approvals</h3>
            {stats?.pending > 0 && (
              <span style={{ background: 'rgba(245,158,11,0.15)', color: '#f59e0b', border: '1px solid rgba(245,158,11,0.3)', borderRadius: '20px', padding: '2px 10px', fontSize: '11px', fontWeight: '700' }}>
                {stats.pending} waiting
              </span>
            )}
          </div>
          <p style={{ fontSize: '12px', color: '#4a4a6a', margin: '0 0 16px' }}>Registrations needing review</p>
          {loading ? (
            Array.from({ length: 4 }).map((_, i) => (
              <div key={i} style={{ display: 'flex', gap: '12px', alignItems: 'center', padding: '12px 0', borderBottom: '1px solid rgba(255,255,255,0.04)' }}>
                <div style={{ width: 36, height: 36, borderRadius: '50%', background: 'rgba(255,255,255,0.05)', flexShrink: 0 }} />
                <div style={{ flex: 1 }}>
                  <div style={{ height: '12px', background: 'rgba(255,255,255,0.05)', borderRadius: '4px', marginBottom: '6px', width: '60%' }} />
                  <div style={{ height: '10px', background: 'rgba(255,255,255,0.04)', borderRadius: '4px', width: '40%' }} />
                </div>
              </div>
            ))
          ) : pending.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '24px 0' }}>
              <p style={{ fontSize: '28px', marginBottom: '8px' }}>✅</p>
              <p style={{ color: '#4a4a6a', fontSize: '13px' }}>All caught up!</p>
            </div>
          ) : (
            pending.map(m => (
              <RecentItem key={m.id} name={m.full_name} label={m.membership_type || 'Pending'} time={fmt(m.created_at)} dot="#f59e0b" />
            ))
          )}
        </div>
      </div>

      {/* Quick Guide */}
      <div style={{ marginTop: '18px', background: 'rgba(124,58,237,0.06)', border: '1px solid rgba(124,58,237,0.15)', borderRadius: '14px', padding: '20px 24px' }}>
        <h3 style={{ fontSize: '14px', fontWeight: '700', color: '#a78bfa', margin: '0 0 12px' }}>⚡ Admin Quick Guide</h3>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '14px' }}>
          {[
            { step: '1', title: 'Register Member', desc: 'Use QR page or let them scan the QR code to self-register', color: '#059669' },
            { step: '2', title: 'Approve Member', desc: 'Go to Approvals → Accept to activate their membership', color: '#7c3aed' },
            { step: '3', title: 'Create Account', desc: 'Go to Members → Create Account so they can log into the app', color: '#2563eb' },
            { step: '4', title: 'Assign Trainer', desc: 'Go to Trainers → create trainer account, then Members → Assign Trainer', color: '#d97706' },
          ].map(({ step, title, desc, color }) => (
            <div key={step} style={{ padding: '14px', background: 'rgba(255,255,255,0.02)', borderRadius: '10px', border: '1px solid rgba(255,255,255,0.05)' }}>
              <div style={{ width: '24px', height: '24px', borderRadius: '50%', background: color + '25', border: `1px solid ${color}55`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '11px', fontWeight: '800', color, marginBottom: '10px' }}>{step}</div>
              <p style={{ fontSize: '12px', fontWeight: '700', color: '#c0c0e0', margin: '0 0 5px' }}>{title}</p>
              <p style={{ fontSize: '11px', color: '#5a5a8a', margin: 0, lineHeight: 1.5 }}>{desc}</p>
            </div>
          ))}
        </div>
      </div>
    </Layout>
  )
}