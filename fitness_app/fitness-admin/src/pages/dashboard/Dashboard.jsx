import { useEffect, useState } from 'react'
import { supabase } from '../../services/supabase'
import Layout from '../../components/layout/Layout'

const _cache = { stats: null, recent: null, pending: null }

const C = {
  card: { background: '#141824', border: '1px solid rgba(255,255,255,0.06)', borderRadius: '12px' },
}

function StatCard({ icon, label, value, sub, color = '#3b82f6', loading }) {
  return (
    <div style={{ ...C.card, padding: '20px 22px' }}>
      {loading ? (
        <>
          <div style={{ width: '32px', height: '32px', borderRadius: '8px', background: 'rgba(255,255,255,0.04)', marginBottom: '14px' }} />
          <div style={{ height: '26px', background: 'rgba(255,255,255,0.04)', borderRadius: '6px', width: '45%', marginBottom: '8px' }} />
          <div style={{ height: '10px', background: 'rgba(255,255,255,0.03)', borderRadius: '4px', width: '70%' }} />
        </>
      ) : (
        <>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
            <div style={{
              width: '34px', height: '34px', borderRadius: '9px',
              background: color + '18', border: `1px solid ${color}30`,
              display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '17px',
            }}>{icon}</div>
            <div style={{ width: '6px', height: '6px', borderRadius: '50%', background: color, boxShadow: `0 0 6px ${color}` }} />
          </div>
          <p style={{ fontSize: '28px', fontWeight: '800', color: '#f0f2f8', margin: '0 0 3px', lineHeight: 1, letterSpacing: '-0.5px' }}>{value ?? 0}</p>
          <p style={{ fontSize: '12.5px', color: '#4a5568', margin: 0, fontWeight: '500' }}>{label}</p>
          {sub && <p style={{ fontSize: '10.5px', color: '#2d3748', margin: '4px 0 0' }}>{sub}</p>}
        </>
      )}
    </div>
  )
}

function MemberRow({ name, label, time }) {
  const initials = name?.split(' ').slice(0, 2).map(w => w[0]).join('').toUpperCase() || '??'
  const palette = ['#2563eb', '#7c3aed', '#059669', '#d97706', '#dc2626', '#0891b2']
  const color = palette[name?.charCodeAt(0) % palette.length] || '#2563eb'
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: '11px', padding: '11px 0', borderBottom: '1px solid rgba(255,255,255,0.035)' }}>
      <div style={{
        width: 34, height: 34, borderRadius: '8px', flexShrink: 0,
        background: color + '20', border: `1px solid ${color}35`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: '11px', fontWeight: '700', color,
      }}>{initials}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <p style={{ fontSize: '12.5px', fontWeight: '600', color: '#c8d0e0', margin: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{name}</p>
        <p style={{ fontSize: '10.5px', color: '#4a5568', margin: '2px 0 0' }}>{label}</p>
      </div>
      <p style={{ fontSize: '10px', color: '#2d3748', flexShrink: 0 }}>{time}</p>
    </div>
  )
}

function fmt(dateStr) {
  if (!dateStr) return '—'
  const d = new Date(dateStr)
  const now = new Date()
  const diff = Math.floor((now - d) / 1000)
  if (diff < 60)    return 'just now'
  if (diff < 3600)  return `${Math.floor(diff / 60)}m ago`
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`
  return `${Math.floor(diff / 86400)}d ago`
}

function SkeletonRow() {
  return (
    <div style={{ display: 'flex', gap: '11px', alignItems: 'center', padding: '11px 0', borderBottom: '1px solid rgba(255,255,255,0.035)' }}>
      <div style={{ width: 34, height: 34, borderRadius: '8px', background: 'rgba(255,255,255,0.04)', flexShrink: 0 }} />
      <div style={{ flex: 1 }}>
        <div style={{ height: '11px', background: 'rgba(255,255,255,0.04)', borderRadius: '4px', width: '55%', marginBottom: '6px' }} />
        <div style={{ height: '9px', background: 'rgba(255,255,255,0.03)', borderRadius: '4px', width: '35%' }} />
      </div>
    </div>
  )
}

export default function Dashboard() {
  const [stats,   setStats]   = useState(_cache.stats)
  const [recent,  setRecent]  = useState(_cache.recent ?? [])
  const [pending, setPending] = useState(_cache.pending ?? [])
  const [loading, setLoading] = useState(!_cache.stats)

  useEffect(() => { load() }, [])

  async function load() {
    if (_cache.stats) { setStats(_cache.stats); setRecent(_cache.recent ?? []); setPending(_cache.pending ?? []); setLoading(false) }
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
      _cache.stats   = { active: activeCount || 0, pending: pendingCount || 0, trainers: trainerCount || 0, expiring: expiringMembers?.length || 0 }
      _cache.recent  = recentMembers  || []
      _cache.pending = pendingMembers || []
      setStats(_cache.stats); setRecent(_cache.recent); setPending(_cache.pending)
    } catch {
      if (!_cache.stats) setStats({ active: 0, pending: 0, trainers: 0, expiring: 0 })
    }
    setLoading(false)
  }

  return (
    <Layout>
      {/* Page Header */}
      <div style={{ marginBottom: '24px' }}>
        <h1 style={{ fontSize: '22px', fontWeight: '800', color: '#f0f2f8', margin: '0 0 4px', letterSpacing: '-0.3px' }}>Dashboard</h1>
        <p style={{ color: '#4a5568', fontSize: '13px', margin: 0 }}>Welcome back, Admin — here's what's happening today</p>
      </div>

      {/* Stats Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '12px', marginBottom: '24px' }}>
        <StatCard loading={loading} icon="👥" label="Active Members"   value={stats?.active}   color="#22c55e"  sub="Currently enrolled" />
        <StatCard loading={loading} icon="⏳" label="Pending Approval" value={stats?.pending}  color="#f59e0b"  sub="Awaiting review" />
        <StatCard loading={loading} icon="💪" label="Trainers"          value={stats?.trainers} color="#3b82f6"  sub="On the team" />
        <StatCard loading={loading} icon="⚠️" label="Expiring Soon"    value={stats?.expiring} color="#ef4444"  sub="Within 7 days" />
      </div>

      {/* Lower Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginBottom: '16px' }}>
        {/* Recent Members */}
        <div style={{ ...C.card, padding: '20px 22px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
            <div>
              <h3 style={{ fontSize: '14px', fontWeight: '700', color: '#c8d0e0', margin: 0 }}>Recent Members</h3>
              <p style={{ fontSize: '11px', color: '#2d3748', margin: '2px 0 0' }}>Most recently approved</p>
            </div>
            <span style={{ fontSize: '10px', color: '#2d3748', background: 'rgba(255,255,255,0.04)', border: '1px solid rgba(255,255,255,0.06)', borderRadius: '6px', padding: '3px 8px', fontWeight: '500' }}>Latest active</span>
          </div>
          {loading ? Array.from({ length: 4 }).map((_, i) => <SkeletonRow key={i} />) :
           recent.length === 0 ? <p style={{ color: '#2d3748', fontSize: '13px', textAlign: 'center', padding: '24px 0' }}>No active members yet</p> :
           recent.map(m => <MemberRow key={m.id} name={m.full_name} label={m.membership_type || 'Member'} time={fmt(m.created_at)} />)
          }
        </div>

        {/* Pending Approvals */}
        <div style={{ ...C.card, padding: '20px 22px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
            <div>
              <h3 style={{ fontSize: '14px', fontWeight: '700', color: '#c8d0e0', margin: 0 }}>Pending Approvals</h3>
              <p style={{ fontSize: '11px', color: '#2d3748', margin: '2px 0 0' }}>Registrations needing review</p>
            </div>
            {stats?.pending > 0 && (
              <span style={{ background: 'rgba(245,158,11,0.12)', color: '#f59e0b', border: '1px solid rgba(245,158,11,0.25)', borderRadius: '20px', padding: '2px 10px', fontSize: '10.5px', fontWeight: '700' }}>
                {stats.pending} waiting
              </span>
            )}
          </div>
          {loading ? Array.from({ length: 4 }).map((_, i) => <SkeletonRow key={i} />) :
           pending.length === 0 ? (
             <div style={{ textAlign: 'center', padding: '28px 0' }}>
               <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: 'rgba(34,197,94,0.1)', border: '1px solid rgba(34,197,94,0.2)', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 10px', fontSize: '18px' }}>✅</div>
               <p style={{ color: '#2d3748', fontSize: '12.5px', fontWeight: '600' }}>All caught up!</p>
             </div>
           ) : pending.map(m => <MemberRow key={m.id} name={m.full_name} label={m.membership_type || 'Pending'} time={fmt(m.created_at)} />)
          }
        </div>
      </div>

      {/* Quick Guide */}
      <div style={{ background: 'rgba(59,130,246,0.05)', border: '1px solid rgba(59,130,246,0.12)', borderRadius: '12px', padding: '18px 22px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '14px' }}>
          <div style={{ width: '6px', height: '6px', borderRadius: '50%', background: '#3b82f6', boxShadow: '0 0 6px #3b82f6' }} />
          <h3 style={{ fontSize: '13px', fontWeight: '700', color: '#60a5fa', margin: 0 }}>Admin Quick Guide</h3>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '12px' }}>
          {[
            { step: '1', title: 'Register Member',  desc: 'Use QR page or let them scan the QR code to self-register', color: '#22c55e' },
            { step: '2', title: 'Approve Member',   desc: 'Go to Approvals → Accept to activate their membership', color: '#3b82f6' },
            { step: '3', title: 'Create Account',   desc: 'Go to Members → Create Account so they can log into the app', color: '#7c3aed' },
            { step: '4', title: 'Assign Trainer',   desc: 'Create trainer account, then assign from Members page', color: '#f59e0b' },
          ].map(({ step, title, desc, color }) => (
            <div key={step} style={{ padding: '12px 14px', background: 'rgba(255,255,255,0.02)', borderRadius: '10px', border: '1px solid rgba(255,255,255,0.04)' }}>
              <div style={{ width: '22px', height: '22px', borderRadius: '50%', background: color + '20', border: `1px solid ${color}40`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '10px', fontWeight: '800', color, marginBottom: '9px' }}>{step}</div>
              <p style={{ fontSize: '11.5px', fontWeight: '700', color: '#8892a4', margin: '0 0 4px' }}>{title}</p>
              <p style={{ fontSize: '10.5px', color: '#2d3748', margin: 0, lineHeight: 1.5 }}>{desc}</p>
            </div>
          ))}
        </div>
      </div>
    </Layout>
  )
}