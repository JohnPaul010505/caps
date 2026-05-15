import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '../../services/supabase'
import Layout from '../../components/layout/Layout'

const REGISTRATION_URL = `${window.location.origin}/register`

const GOALS = ['Weight Loss','Muscle Gain','General Fitness','Endurance','Flexibility','Rehabilitation']
const MEMBERSHIPS = [
  { label:'Basic – ₱999/mo',    value:'Basic'     },
  { label:'Quarterly – ₱2,499', value:'Quarterly' },
  { label:'6 Months – ₱4,499',  value:'6 Months'  },
  { label:'Annual – ₱7,999',    value:'Annual'    },
]

const EMPTY = {
  full_name:'', age:'', gender:'', email:'',
  contact_number:'', height:'', weight:'',
  goal:'Weight Loss', membership_type:'Basic',
  wants_trainer:false, emergency_contact:'',
  auto_approve:false,
}

function iStyle(focused) {
  return {
    width:'100%', boxSizing:'border-box',
    background: focused ? 'rgba(16,185,129,0.05)' : 'rgba(255,255,255,0.04)',
    border:`1px solid ${focused ? 'rgba(16,185,129,0.5)' : 'rgba(255,255,255,0.08)'}`,
    borderRadius:'8px', padding:'9px 12px',
    fontSize:'13px', color:'#e2e2f0', outline:'none', transition:'all 0.2s',
  }
}

function sStyle(focused) {
  // NOTE: Do NOT spread iStyle here because iStyle sets `background` shorthand
  // which conflicts with backgroundImage/backgroundPosition — split them out manually
  return {
    width:'100%', boxSizing:'border-box',
    backgroundColor: focused ? 'rgba(16,185,129,0.05)' : 'rgba(255,255,255,0.04)',
    backgroundImage:`url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%236b6b9b' stroke-width='2'%3E%3Cpolyline points='6 9 12 15 18 9'/%3E%3C/svg%3E")`,
    backgroundRepeat:'no-repeat',
    backgroundPosition:'right 12px center',
    border:`1px solid ${focused ? 'rgba(16,185,129,0.5)' : 'rgba(255,255,255,0.08)'}`,
    borderRadius:'8px', padding:'9px 12px', paddingRight:'32px',
    fontSize:'13px', color:'#e2e2f0', outline:'none', transition:'all 0.2s',
    cursor:'pointer', appearance:'none',
  }
}

function Lbl({ children }) {
  return <label style={{ display:'block', fontSize:'11px', fontWeight:'600', color:'#4a4a6a', letterSpacing:'0.5px', marginBottom:'6px' }}>{children}</label>
}

export default function QRCodePage() {
  const navigate      = useNavigate()
  const [qrKey,  setQrKey]  = useState(0)
  const [form,   setForm]   = useState(EMPTY)
  const [focus,  setFocus]  = useState('')
  const [saving, setSaving] = useState(false)
  const [err,    setErr]    = useState('')

  const qrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=${encodeURIComponent(REGISTRATION_URL)}&v=${qrKey}`

  function set(k, v) { setForm(p=>({...p,[k]:v})); setErr('') }
  function fp(n) { return { onFocus:()=>setFocus(n), onBlur:()=>setFocus('') } }

  async function handleDownload() {
    try {
      const res  = await fetch(qrUrl)
      const blob = await res.blob()
      const url  = URL.createObjectURL(blob)
      const a    = document.createElement('a')
      a.href = url; a.download = 'fittrack-qr.png'; a.click()
      URL.revokeObjectURL(url)
    } catch { /* silent */ }
  }

  async function handleSubmit(e) {
    e.preventDefault()
    console.log('SUBMIT STARTED')
    if (!form.full_name.trim()) { setErr('Full name is required.'); return }

    setSaving(true)
    setErr('')
    console.log('CALLING SUPABASE INSERT...')

    try {
      let expiration_date = null
      if (form.auto_approve) {
        const months = form.membership_type === 'Quarterly' ? 3
          : form.membership_type === '6 Months' ? 6
          : form.membership_type === 'Annual'   ? 12 : 1
        const exp = new Date()
        exp.setMonth(exp.getMonth() + months)
        expiration_date = exp.toISOString().split('T')[0]
      }

      const payload = {
        full_name:         form.full_name.trim(),
        age:               form.age            ? parseInt(form.age)       : null,
        gender:            form.gender         || null,
        email:             form.email          || null,
        contact_number:    form.contact_number || null,
        height:            form.height         ? parseFloat(form.height)  : null,
        weight:            form.weight         ? parseFloat(form.weight)  : null,
        goal:              form.goal           || null,
        membership_type:   form.membership_type,
        wants_trainer:     form.wants_trainer,
        emergency_contact: form.emergency_contact || null,
        membership_status: form.auto_approve ? 'active' : 'pending',
        expiration_date,
      }

      const { error: insertErr } = await supabase.from('members').insert(payload)
      console.log('INSERT COMPLETED. Error:', insertErr)

      if (insertErr) {
        setErr(insertErr.message || 'Failed to save member.')
        setSaving(false)   // ← FIX: clear saving on error
        return
      }

      // ✅ Success — reset saving BEFORE navigating
      setSaving(false)
      navigate(form.auto_approve ? '/members' : '/approvals')

    } catch (e) {
      setErr(e?.message || 'Unexpected error. Please try again.')
      setSaving(false)   // ← FIX: always clear saving on any error
    }
  }

  const cardStyle = { background:'#1a1a2e', border:'1px solid rgba(255,255,255,0.07)', borderRadius:'14px' }

  return (
    <Layout>
      <div style={{ marginBottom:'28px' }}>
        <h2 style={{ fontSize:'24px', fontWeight:'800', color:'#fff', margin:0 }}>QR Registration</h2>
        <p style={{ color:'#5a5a8a', fontSize:'13px', marginTop:'4px' }}>Generate a code for new member self-registration</p>
      </div>

      <div style={{ display:'grid', gridTemplateColumns:'1fr 1.65fr', gap:'20px', alignItems:'start' }}>

        {/* QR Panel */}
        <div style={{ ...cardStyle, padding:'32px 28px', display:'flex', flexDirection:'column', alignItems:'center', gap:'20px' }}>
          <div style={{ background:'#fff', borderRadius:'12px', padding:'16px', boxShadow:'0 0 0 1px rgba(255,255,255,0.1)' }}>
            <img src={qrUrl} alt="QR Code" width={200} height={200} style={{ display:'block', borderRadius:'4px' }} />
          </div>
          <p style={{ fontSize:'13px', color:'#6060a0', textAlign:'center', margin:0 }}>Scan to register as a new member</p>
          <p style={{ fontSize:'11px', color:'#3a3a5a', textAlign:'center', wordBreak:'break-all', margin:0 }}>{REGISTRATION_URL}</p>
          <div style={{ display:'flex', gap:'10px', width:'100%' }}>
            <button onClick={handleDownload} style={{ flex:1, display:'flex', alignItems:'center', justifyContent:'center', gap:'6px', padding:'10px', borderRadius:'10px', background:'rgba(255,255,255,0.05)', border:'1px solid rgba(255,255,255,0.08)', color:'#9090c0', fontSize:'13px', fontWeight:'600', cursor:'pointer' }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>
              Download
            </button>
            <button onClick={() => setQrKey(k=>k+1)} style={{ flex:1, display:'flex', alignItems:'center', justifyContent:'center', gap:'6px', padding:'10px', borderRadius:'10px', background:'linear-gradient(135deg,#059669,#10b981)', border:'none', color:'#fff', fontSize:'13px', fontWeight:'600', cursor:'pointer', boxShadow:'0 4px 14px rgba(16,185,129,0.35)' }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="23 4 23 10 17 10"/><path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/></svg>
              Regenerate
            </button>
          </div>
        </div>

        {/* Form Panel */}
        <div style={{ ...cardStyle, padding:'28px' }}>
          <p style={{ fontSize:'15px', fontWeight:'700', color:'#e2e2f0', margin:'0 0 4px' }}>Register member manually</p>
          <p style={{ fontSize:'12px', color:'#4a4a6a', margin:'0 0 22px' }}>Fill this form on behalf of a member who cannot scan the QR code</p>

          {err && (
            <div style={{ background:'rgba(239,68,68,0.1)', border:'1px solid rgba(239,68,68,0.25)', borderRadius:'10px', padding:'11px 14px', marginBottom:'16px', color:'#f87171', fontSize:'13px', display:'flex', alignItems:'center', gap:'8px' }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ flexShrink:0 }}><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
              {err}
            </div>
          )}

          <form onSubmit={handleSubmit}>
            {/* Row 1 */}
            <div style={{ display:'grid', gridTemplateColumns:'1.5fr 1fr', gap:'12px', marginBottom:'12px' }}>
              <div><Lbl>FULL NAME *</Lbl><input type="text" placeholder="e.g. Juan Dela Cruz" value={form.full_name} onChange={e=>set('full_name',e.target.value)} style={iStyle(focus==='full_name')} {...fp('full_name')} required /></div>
              <div><Lbl>AGE</Lbl><input type="number" placeholder="28" min="10" max="100" value={form.age} onChange={e=>set('age',e.target.value)} style={iStyle(focus==='age')} {...fp('age')} /></div>
            </div>
            {/* Row 2 */}
            <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:'12px', marginBottom:'12px' }}>
              <div><Lbl>GENDER</Lbl>
                <select value={form.gender} onChange={e=>set('gender',e.target.value)} style={sStyle(focus==='gender')} {...fp('gender')}>
                  <option value="">Select gender</option>
                  <option>Male</option><option>Female</option><option>Other</option>
                </select>
              </div>
              <div><Lbl>EMAIL</Lbl><input type="email" placeholder="juan@email.com" value={form.email} onChange={e=>set('email',e.target.value)} style={iStyle(focus==='email')} {...fp('email')} /></div>
            </div>
            {/* Row 3 */}
            <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:'12px', marginBottom:'12px' }}>
              <div><Lbl>CONTACT NUMBER</Lbl><input type="tel" placeholder="09171234567" value={form.contact_number} onChange={e=>set('contact_number',e.target.value)} style={iStyle(focus==='contact')} {...fp('contact')} /></div>
              <div><Lbl>EMERGENCY CONTACT</Lbl><input type="text" placeholder="Name & number" value={form.emergency_contact} onChange={e=>set('emergency_contact',e.target.value)} style={iStyle(focus==='emergency')} {...fp('emergency')} /></div>
            </div>
            {/* Row 4 */}
            <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:'12px', marginBottom:'12px' }}>
              <div><Lbl>HEIGHT (cm)</Lbl><input type="number" placeholder="170" value={form.height} onChange={e=>set('height',e.target.value)} style={iStyle(focus==='height')} {...fp('height')} /></div>
              <div><Lbl>WEIGHT (kg)</Lbl><input type="number" placeholder="65" value={form.weight} onChange={e=>set('weight',e.target.value)} style={iStyle(focus==='weight')} {...fp('weight')} /></div>
            </div>
            {/* Row 5 */}
            <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:'12px', marginBottom:'14px' }}>
              <div><Lbl>FITNESS GOAL</Lbl>
                <select value={form.goal} onChange={e=>set('goal',e.target.value)} style={sStyle(focus==='goal')} {...fp('goal')}>
                  {GOALS.map(g=><option key={g}>{g}</option>)}
                </select>
              </div>
              <div><Lbl>MEMBERSHIP TYPE</Lbl>
                <select value={form.membership_type} onChange={e=>set('membership_type',e.target.value)} style={sStyle(focus==='membership')} {...fp('membership')}>
                  {MEMBERSHIPS.map(m=><option key={m.value} value={m.value}>{m.label}</option>)}
                </select>
              </div>
            </div>

            {/* Checkboxes */}
            <div style={{ display:'flex', gap:'20px', marginBottom:'16px' }}>
              {[
                { k:'wants_trainer', label:'I want a personal trainer' },
                { k:'auto_approve',  label:'Approve immediately (skip pending)' },
              ].map(({k,label}) => (
                <label key={k} style={{ display:'flex', alignItems:'center', gap:'8px', cursor:'pointer' }}>
                  <div onClick={()=>set(k,!form[k])} style={{ width:'16px', height:'16px', borderRadius:'4px', flexShrink:0, border:`1.5px solid ${form[k] ? '#10b981' : 'rgba(255,255,255,0.15)'}`, background: form[k] ? 'rgba(16,185,129,0.2)' : 'rgba(255,255,255,0.03)', display:'flex', alignItems:'center', justifyContent:'center', transition:'all 0.15s', cursor:'pointer' }}>
                    {form[k] && <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="#10b981" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>}
                  </div>
                  <span style={{ fontSize:'12.5px', color:'#7070a0', userSelect:'none' }}>{label}</span>
                </label>
              ))}
            </div>

            {/* Status hint */}
            <div style={{ background: form.auto_approve ? 'rgba(16,185,129,0.08)' : 'rgba(245,158,11,0.08)', border:`1px solid ${form.auto_approve ? 'rgba(16,185,129,0.2)' : 'rgba(245,158,11,0.2)'}`, borderRadius:'8px', padding:'10px 14px', marginBottom:'18px', display:'flex', alignItems:'center', gap:'8px', fontSize:'12px', color: form.auto_approve ? '#34d399' : '#fbbf24' }}>
              <span>{form.auto_approve ? '✅' : '⏳'}</span>
              {form.auto_approve
                ? "Member will be set as Active and you'll be taken to Members."
                : "Member will be added as Pending — you'll be taken to Approvals to review."}
            </div>

            <button
              type="submit"
              disabled={saving}
              style={{ width:'100%', padding:'13px', background: saving ? 'rgba(16,185,129,0.4)' : 'linear-gradient(135deg,#059669,#10b981)', color:'#fff', border:'none', borderRadius:'10px', fontSize:'14px', fontWeight:'700', cursor: saving ? 'not-allowed' : 'pointer', display:'flex', alignItems:'center', justifyContent:'center', gap:'8px', boxShadow: saving ? 'none' : '0 6px 20px rgba(16,185,129,0.35)', transition:'all 0.2s' }}
            >
              {saving ? (
                <>
                  <svg style={{ animation:'spin2 1s linear infinite' }} width="16" height="16" viewBox="0 0 24 24" fill="none">
                    <style>{`@keyframes spin2{to{transform:rotate(360deg)}}`}</style>
                    <circle opacity=".25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
                    <path opacity=".75" fill="currentColor" d="M4 12a8 8 0 018-8v8z"/>
                  </svg>
                  Saving…
                </>
              ) : 'Submit Registration'}
            </button>
          </form>
        </div>
      </div>
    </Layout>
  )
}