import { useEffect, useState } from 'react'
import { supabase } from '../../services/supabase'
import Layout from '../../components/layout/Layout'
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend
} from 'recharts'

const GREEN        = '#22c55e'
const AMBER        = '#f59e0b'
const PURPLE_LIGHT = '#a855f7'

function withTimeout(promise, ms = 30000) {
  return Promise.race([
    promise,
    new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), ms))
  ])
}

function card(extra = {}) {
  return { background: '#1a1a2e', border: '1px solid rgba(255,255,255,0.07)', borderRadius: '14px', ...extra }
}

function Avatar({ name, size = 36 }) {
  const initials = name?.split(' ').slice(0,2).map(w=>w[0]).join('').toUpperCase() || '??'
  const colors   = ['#7c3aed','#2563eb','#059669','#d97706','#dc2626','#0891b2']
  const color    = colors[(name?.charCodeAt(0)??0) % colors.length]
  return (
    <div style={{ width:size, height:size, borderRadius:'50%', background:color+'33', border:`1.5px solid ${color}55`, display:'flex', alignItems:'center', justifyContent:'center', fontSize:size*0.33, fontWeight:'700', color, flexShrink:0 }}>
      {initials}
    </div>
  )
}

function StatusBadge({ status }) {
  const map = {
    active:   { bg:'#22c55e1a', color:'#22c55e', border:'#22c55e40' },
    inactive: { bg:'#6b728020', color:'#9ca3af', border:'#6b728040' },
    expiring: { bg:'#f59e0b1a', color:'#f59e0b', border:'#f59e0b40' },
  }
  const s = map[status] || map.inactive
  return <span style={{ padding:'3px 10px', borderRadius:'20px', fontSize:'11.5px', fontWeight:'600', background:s.bg, color:s.color, border:`1px solid ${s.border}`, textTransform:'capitalize' }}>{status}</span>
}

function Tooltip2({ active, payload, label }) {
  if (!active || !payload?.length) return null
  return (
    <div style={{ background:'#1a1a2e', border:'1px solid rgba(255,255,255,0.1)', borderRadius:'8px', padding:'8px 12px' }}>
      <p style={{ color:'#a0a0c0', fontSize:'12px', marginBottom:'2px' }}>{label}</p>
      <p style={{ color:'#fff', fontWeight:'700', fontSize:'15px' }}>{payload[0].value}</p>
    </div>
  )
}

export default function Dashboard() {
  const [stats,         setStats]         = useState(null)
  const [statusData,    setStatusData]    = useState([])
  const [recentMembers, setRecentMembers] = useState([])
  const [error,         setError]         = useState(false)
  const [waking,        setWaking]        = useState(false)

  const months     = ['Dec','Jan','Feb','Mar','Apr','May']
  const growthData = months.map((m,i)=>({ month:m, count: Math.floor(180 + i*12 + (i*7)%15) }))

  useEffect(() => { fetchAll() }, [])

  async function fetchAll() {
    setError(false)
    setStats(null)
    setWaking(false)
    const wakingTimer = setTimeout(() => setWaking(true), 5000)

    try {
      // ✅ Simple selects — no broken FK joins
      const [membersRes, trainersRes] = await Promise.all([
        withTimeout(supabase.from('members').select('id, full_name, membership_status, expiration_date, created_at')),
        withTimeout(supabase.from('trainers').select('id', { count:'exact', head:true })),
      ])

      clearTimeout(wakingTimer)
      setWaking(false)

      if (membersRes.error)  throw membersRes.error
      if (trainersRes.error) throw trainersRes.error

      const all          = membersRes.data  || []
      const trainerCount = trainersRes.count ?? 0

      const today = new Date().toISOString().split('T')[0]
      const in7   = new Date(Date.now() + 7*86400000).toISOString().split('T')[0]

      const pendingList = all.filter(m => m.membership_status === 'pending')
      const nonPending  = all.filter(m => m.membership_status !== 'pending')
      const active      = nonPending.filter(m => m.membership_status === 'active')
      const inactive    = nonPending.filter(m => m.membership_status === 'inactive')
      const expiring    = active.filter(m => m.expiration_date && m.expiration_date >= today && m.expiration_date <= in7)
      const expiringIds = new Set(expiring.map(m => m.id))

      setStats({ total: nonPending.length, active: active.length, inactive: inactive.length, expiring: expiring.length, trainers: trainerCount, pending: pendingList.length })

      setStatusData([
        { name:'Active',   value: active.length,   color: GREEN    },
        { name:'Inactive', value: inactive.length,  color:'#6b7280' },
        { name:'Expiring', value: expiring.length,  color: AMBER    },
      ])

      const recent = [...nonPending]
        .sort((a,b) => new Date(b.created_at) - new Date(a.created_at))
        .slice(0,5)
        .map(m => ({ id:m.id, name:m.full_name, expires:m.expiration_date, status: expiringIds.has(m.id) ? 'expiring' : m.membership_status }))
      setRecentMembers(recent)

    } catch {
      clearTimeout(wakingTimer)
      setWaking(false)
      setError(true)
      setStats({ total:0, active:0, inactive:0, expiring:0, trainers:0, pending:0 })
    }
  }

  const activePercent = stats ? Math.round((stats.active / (stats.total || 1)) * 100) : 0
  const now = new Date()

  return (
    <Layout>
      <div style={{ marginBottom:'28px' }}>
        <h2 style={{ fontSize:'24px', fontWeight:'800', color:'#fff', margin:0 }}>Dashboard</h2>
        <p style={{ color:'#5a5a8a', fontSize:'13px', marginTop:'4px' }}>
          {now.toLocaleString('default',{month:'long'})} {now.getFullYear()} overview
        </p>
      </div>

      {waking && !error && (
        <div style={{ background:'rgba(124,58,237,0.15)', border:'1px solid rgba(124,58,237,0.3)', borderRadius:'10px', padding:'12px 16px', marginBottom:'20px', display:'flex', alignItems:'center', gap:'10px', color:'#a78bfa', fontSize:'13px' }}>
          <svg style={{ animation:'spin 1s linear infinite', flexShrink:0 }} width="16" height="16" viewBox="0 0 24 24" fill="none">
            <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
            <circle opacity=".25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
            <path opacity=".75" fill="currentColor" d="M4 12a8 8 0 018-8v8z"/>
          </svg>
          Waking up database — this may take up to 30 seconds on the free tier…
        </div>
      )}
      {error && (
        <div style={{ background:'rgba(239,68,68,0.1)', border:'1px solid rgba(239,68,68,0.25)', borderRadius:'10px', padding:'12px 16px', marginBottom:'20px', display:'flex', alignItems:'center', justifyContent:'space-between', color:'#f87171', fontSize:'13px' }}>
          ⚠️ Could not connect to database.
          <button onClick={fetchAll} style={{ background:'rgba(239,68,68,0.2)', border:'none', color:'#f87171', padding:'5px 12px', borderRadius:'6px', cursor:'pointer', fontSize:'12px', fontWeight:'600' }}>↻ Retry</button>
        </div>
      )}

      {/* Stat Cards */}
      <div style={{ display:'grid', gridTemplateColumns:'repeat(4,1fr)', gap:'16px', marginBottom:'20px' }}>
        {[
          { label:'Total members',  value:stats?.total,    sub:'▲ 12 this month',            accent:'#3b82f6' },
          { label:'Active',         value:stats?.active,   sub:`${activePercent}% of total`,  accent: GREEN    },
          { label:'Inactive',       value:stats?.inactive, sub:`${100-activePercent}% of total`, accent:'#6b7280'},
          { label:'Expiring soon',  value:stats?.expiring, sub:'Within 7 days',               accent: AMBER    },
        ].map((c,i) => (
          <div key={i} style={card({ padding:'22px 24px' })}>
            <p style={{ fontSize:'12px', color:'#5a5a8a', marginBottom:'10px', fontWeight:'500' }}>{c.label}</p>
            {stats === null
              ? <div style={{ height:'36px', background:'rgba(255,255,255,0.05)', borderRadius:'6px' }} />
              : <p style={{ fontSize:'32px', fontWeight:'800', color:c.accent, lineHeight:1, marginBottom:'6px' }}>{c.value}</p>
            }
            <p style={{ fontSize:'12px', color:'#4a4a6a' }}>{c.sub}</p>
          </div>
        ))}
      </div>

      {stats?.pending > 0 && (
        <div style={{ background:'rgba(245,158,11,0.1)', border:'1px solid rgba(245,158,11,0.25)', borderRadius:'12px', padding:'14px 18px', marginBottom:'20px', display:'flex', alignItems:'center', gap:'12px' }}>
          <span style={{ fontSize:'20px' }}>⏳</span>
          <div>
            <p style={{ fontSize:'13px', fontWeight:'600', color:'#fbbf24' }}>{stats.pending} pending registration{stats.pending > 1 ? 's' : ''} awaiting approval</p>
            <p style={{ fontSize:'12px', color:'#78716c', marginTop:'2px' }}>Go to Approvals to review them</p>
          </div>
        </div>
      )}

      {/* Charts */}
      <div style={{ display:'grid', gridTemplateColumns:'1.4fr 1fr', gap:'16px', marginBottom:'20px' }}>
        <div style={card({ padding:'24px' })}>
          <h3 style={{ fontSize:'15px', fontWeight:'700', color:'#e2e2f0', marginBottom:'20px' }}>Member growth</h3>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={growthData} margin={{ top:0, right:0, left:-20, bottom:0 }}>
              <XAxis dataKey="month" tick={{ fontSize:11, fill:'#5a5a8a' }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize:11, fill:'#5a5a8a' }} axisLine={false} tickLine={false} />
              <Tooltip content={<Tooltip2 />} cursor={{ fill:'rgba(255,255,255,0.03)' }} />
              <Bar dataKey="count" radius={[6,6,0,0]}>
                {growthData.map((_,i) => <Cell key={i} fill={i===growthData.length-1 ? PURPLE_LIGHT : 'rgba(124,58,237,0.45)'} />)}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>

        <div style={card({ padding:'24px' })}>
          <h3 style={{ fontSize:'15px', fontWeight:'700', color:'#e2e2f0', marginBottom:'4px' }}>Membership status</h3>
          {stats === null ? (
            <div style={{ height:'200px', background:'rgba(255,255,255,0.03)', borderRadius:'8px', marginTop:'16px' }} />
          ) : statusData.every(d=>d.value===0) ? (
            <div style={{ display:'flex', alignItems:'center', justifyContent:'center', height:'200px', color:'#4a4a6a', fontSize:'13px' }}>No data yet</div>
          ) : (
            <div style={{ position:'relative' }}>
              <ResponsiveContainer width="100%" height={200}>
                <PieChart>
                  <Pie data={statusData} cx="42%" cy="50%" innerRadius={55} outerRadius={78} dataKey="value" strokeWidth={0} paddingAngle={3}>
                    {statusData.map((d,i) => <Cell key={i} fill={d.color} />)}
                  </Pie>
                  <Legend layout="vertical" align="right" verticalAlign="middle"
                    formatter={(value,entry) => <span style={{ color:'#b0b0d0', fontSize:'12px' }}>{value} <strong style={{ color:'#fff' }}>{entry.payload.value}</strong></span>}
                    iconType="circle" iconSize={8} />
                </PieChart>
              </ResponsiveContainer>
              <div style={{ position:'absolute', top:'50%', left:'42%', transform:'translate(-50%,-50%)', textAlign:'center', pointerEvents:'none' }}>
                <p style={{ fontSize:'22px', fontWeight:'800', color:'#fff', lineHeight:1 }}>{activePercent}%</p>
                <p style={{ fontSize:'10px', color:'#5a5a8a', marginTop:'2px' }}>active</p>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Recent Members */}
      <div style={card({ padding:'24px' })}>
        <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom:'18px' }}>
          <h3 style={{ fontSize:'15px', fontWeight:'700', color:'#e2e2f0' }}>Recent members</h3>
          <a href="/members" style={{ color:'#a855f7', fontSize:'13px', fontWeight:'500', textDecoration:'none' }}>View all →</a>
        </div>
        <table style={{ width:'100%', borderCollapse:'collapse' }}>
          <thead>
            <tr style={{ borderBottom:'1px solid rgba(255,255,255,0.06)' }}>
              {['Name','Expires','Status','Actions'].map(h => (
                <th key={h} style={{ padding:'0 12px 12px 0', textAlign:'left', fontSize:'11px', fontWeight:'600', color:'#4a4a6a', letterSpacing:'0.5px' }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {stats === null ? (
              Array.from({length:4}).map((_,i) => (
                <tr key={i} style={{ borderBottom:'1px solid rgba(255,255,255,0.04)' }}>
                  {[180,90,80,60].map((w,j) => (
                    <td key={j} style={{ padding:'14px 12px 14px 0' }}>
                      <div style={{ height:'12px', background:'rgba(255,255,255,0.05)', borderRadius:'4px', width:w }} />
                    </td>
                  ))}
                </tr>
              ))
            ) : recentMembers.length === 0 ? (
              <tr><td colSpan={4} style={{ textAlign:'center', padding:'40px 0', color:'#4a4a6a', fontSize:'13px' }}>No members yet</td></tr>
            ) : recentMembers.map((m,i) => (
              <tr key={m.id} style={{ borderBottom: i < recentMembers.length-1 ? '1px solid rgba(255,255,255,0.04)' : 'none' }}>
                <td style={{ padding:'13px 12px 13px 0' }}>
                  <div style={{ display:'flex', alignItems:'center', gap:'10px' }}>
                    <Avatar name={m.name} />
                    <span style={{ fontSize:'13px', fontWeight:'600', color:'#e2e2f0' }}>{m.name}</span>
                  </div>
                </td>
                <td style={{ padding:'13px 12px 13px 0', fontSize:'13px', color: m.status==='expiring' ? AMBER : '#7070a0' }}>
                  {m.expires ? new Date(m.expires).toLocaleDateString('en-US',{month:'short',day:'numeric'}) : '—'}
                </td>
                <td style={{ padding:'13px 12px 13px 0' }}><StatusBadge status={m.status} /></td>
                <td style={{ padding:'13px 0' }}>
                  <div style={{ display:'flex', gap:'12px' }}>
                    {[
                      { title:'Edit', color:'#a855f7', path:'M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7 M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z' },
                      { title:'Delete', color:'#ef4444', path:'M3 6h18 M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6 M10 11v6 M14 11v6 M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2' },
                    ].map(btn => (
                      <button key={btn.title} title={btn.title} style={{ background:'none', border:'none', cursor:'pointer', color:'#5a5a8a', padding:0 }}
                        onMouseEnter={e => e.currentTarget.style.color = btn.color}
                        onMouseLeave={e => e.currentTarget.style.color = '#5a5a8a'}>
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          {btn.path.split(' ').map((d,di) => <path key={di} d={d}/>)}
                        </svg>
                      </button>
                    ))}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Layout>
  )
}