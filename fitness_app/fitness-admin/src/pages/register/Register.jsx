import { useState } from 'react'
import { supabase } from '../../services/supabase'

const GOALS = ['Weight Loss', 'Muscle Gain', 'Endurance', 'Flexibility', 'General Fitness']
const MEMBERSHIP_TYPES = ['Monthly', 'Quarterly', '6 Months', 'Annual']

const STEPS = ['Personal Info', 'Body & Health', 'Membership', 'Emergency']

const initialForm = {
  full_name: '',
  age: '',
  gender: '',
  email: '',
  contact_number: '',
  height: '',
  weight: '',
  goal: '',
  membership_type: '',
  wants_trainer: null,
  emergency_contact: '',
}

export default function Register() {
  const [step, setStep] = useState(0)
  const [form, setForm] = useState(initialForm)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [submitted, setSubmitted] = useState(false)

  function update(field, value) {
    setForm(prev => ({ ...prev, [field]: value }))
  }

  function nextStep() {
    if (!validateStep()) return
    setError('')
    setStep(s => s + 1)
  }

  function prevStep() {
    setError('')
    setStep(s => s - 1)
  }

  function validateStep() {
    if (step === 0) {
      if (!form.full_name.trim()) return setError('Full name is required.') || false
      if (!form.age || isNaN(form.age) || form.age < 1) return setError('Valid age is required.') || false
      if (!form.gender) return setError('Please select a gender.') || false
      if (!form.email.trim() || !/\S+@\S+\.\S+/.test(form.email)) return setError('Valid email is required.') || false
      if (!form.contact_number.trim()) return setError('Contact number is required.') || false
    }
    if (step === 1) {
      if (!form.height || isNaN(form.height)) return setError('Valid height is required.') || false
      if (!form.weight || isNaN(form.weight)) return setError('Valid weight is required.') || false
      if (!form.goal) return setError('Please select a fitness goal.') || false
    }
    if (step === 2) {
      if (!form.membership_type) return setError('Please select a membership type.') || false
      if (form.wants_trainer === null) return setError('Please answer the trainer preference.') || false
    }
    if (step === 3) {
      if (!form.emergency_contact.trim()) return setError('Emergency contact is required.') || false
    }
    return true
  }

  async function handleSubmit() {
    if (!validateStep()) return
    setLoading(true)
    setError('')
    try {
      const { error: dbError } = await supabase.from('members').insert({
        full_name: form.full_name.trim(),
        age: parseInt(form.age),
        gender: form.gender,
        email: form.email.trim(),
        contact_number: form.contact_number.trim(),
        height: parseFloat(form.height),
        weight: parseFloat(form.weight),
        goal: form.goal,
        membership_type: form.membership_type,
        wants_trainer: form.wants_trainer,
        emergency_contact: form.emergency_contact.trim(),
        membership_status: 'pending',
      })
      if (dbError) throw dbError
      setSubmitted(true)
    } catch (err) {
      setError(err.message || 'Something went wrong. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  if (submitted) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-600 to-blue-900 flex items-center justify-center px-4">
        <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-10 text-center">
          <div className="text-6xl mb-4">🎉</div>
          <h2 className="text-2xl font-bold text-gray-800 mb-2">You're Registered!</h2>
          <p className="text-gray-500 text-sm mb-6">
            Your application has been submitted. Our admin will review and activate your membership shortly.
          </p>
          <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 text-left text-sm text-blue-800">
            <p className="font-semibold mb-1">What happens next?</p>
            <ul className="space-y-1 text-blue-700 list-disc list-inside">
              <li>Admin reviews your registration</li>
              <li>Your account gets activated</li>
              <li>You'll receive login credentials</li>
              <li>Start your fitness journey! 💪</li>
            </ul>
          </div>
          <p className="text-xs text-gray-400 mt-6">You may now close this page.</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-600 to-blue-900 flex items-center justify-center px-4 py-10">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden">

        {/* Header */}
        <div className="bg-gradient-to-r from-blue-600 to-blue-700 px-8 py-6 text-white">
          <div className="text-3xl mb-1">🏋️</div>
          <h1 className="text-xl font-bold">FitAdmin — Member Registration</h1>
          <p className="text-blue-200 text-xs mt-1">Fill out the form to join our gym</p>
        </div>

        {/* Step Progress */}
        <div className="px-8 pt-6">
          <div className="flex items-center gap-2 mb-1">
            {STEPS.map((label, i) => (
              <div key={i} className="flex items-center gap-2 flex-1">
                <div className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold transition-all
                  ${i < step ? 'bg-green-500 text-white' : i === step ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-400'}`}>
                  {i < step ? '✓' : i + 1}
                </div>
                {i < STEPS.length - 1 && (
                  <div className={`flex-1 h-1 rounded-full transition-all ${i < step ? 'bg-green-400' : 'bg-gray-200'}`} />
                )}
              </div>
            ))}
          </div>
          <div className="flex justify-between mt-1 mb-5">
            {STEPS.map((label, i) => (
              <span key={i} className={`text-xs font-medium ${i === step ? 'text-blue-600' : 'text-gray-400'}`}>
                {label}
              </span>
            ))}
          </div>
        </div>

        {/* Form Body */}
        <div className="px-8 pb-8">

          {/* Error */}
          {error && (
            <div className="bg-red-50 border border-red-300 text-red-700 rounded-lg px-4 py-3 text-sm mb-5">
              {error}
            </div>
          )}

          {/* Step 0 — Personal Info */}
          {step === 0 && (
            <div className="space-y-4">
              <h3 className="font-semibold text-gray-700 mb-3">Personal Information</h3>
              <div>
                <label className="block text-xs font-medium text-gray-600 mb-1">Full Name *</label>
                <input
                  type="text"
                  value={form.full_name}
                  onChange={e => update('full_name', e.target.value)}
                  placeholder="Juan Dela Cruz"
                  className="w-full border border-gray-300 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-gray-600 mb-1">Age *</label>
                  <input
                    type="number"
                    value={form.age}
                    onChange={e => update('age', e.target.value)}
                    placeholder="25"
                    min="1"
                    className="w-full border border-gray-300 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-600 mb-1">Gender *</label>
                  <select
                    value={form.gender}
                    onChange={e => update('gender', e.target.value)}
                    className="w-full border border-gray-300 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white"
                  >
                    <option value="">Select</option>
                    <option value="Male">Male</option>
                    <option value="Female">Female</option>
                    <option value="Other">Other</option>
                  </select>
                </div>
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-600 mb-1">Email *</label>
                <input
                  type="email"
                  value={form.email}
                  onChange={e => update('email', e.target.value)}
                  placeholder="juan@gmail.com"
                  className="w-full border border-gray-300 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-600 mb-1">Contact Number *</label>
                <input
                  type="tel"
                  value={form.contact_number}
                  onChange={e => update('contact_number', e.target.value)}
                  placeholder="09XXXXXXXXX"
                  className="w-full border border-gray-300 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>
          )}

          {/* Step 1 — Body & Health */}
          {step === 1 && (
            <div className="space-y-4">
              <h3 className="font-semibold text-gray-700 mb-3">Body & Health</h3>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-medium text-gray-600 mb-1">Height (cm) *</label>
                  <input
                    type="number"
                    value={form.height}
                    onChange={e => update('height', e.target.value)}
                    placeholder="170"
                    className="w-full border border-gray-300 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-600 mb-1">Weight (kg) *</label>
                  <input
                    type="number"
                    value={form.weight}
                    onChange={e => update('weight', e.target.value)}
                    placeholder="65"
                    className="w-full border border-gray-300 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-600 mb-2">Fitness Goal *</label>
                <div className="grid grid-cols-2 gap-2">
                  {GOALS.map(goal => (
                    <button
                      key={goal}
                      type="button"
                      onClick={() => update('goal', goal)}
                      className={`px-4 py-2.5 rounded-lg text-sm font-medium border transition text-left
                        ${form.goal === goal
                          ? 'bg-blue-600 text-white border-blue-600'
                          : 'bg-white text-gray-600 border-gray-300 hover:border-blue-400 hover:text-blue-600'}`}
                    >
                      {goal}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* Step 2 — Membership */}
          {step === 2 && (
            <div className="space-y-5">
              <h3 className="font-semibold text-gray-700 mb-3">Membership</h3>
              <div>
                <label className="block text-xs font-medium text-gray-600 mb-2">Membership Type *</label>
                <div className="grid grid-cols-2 gap-2">
                  {MEMBERSHIP_TYPES.map(type => (
                    <button
                      key={type}
                      type="button"
                      onClick={() => update('membership_type', type)}
                      className={`px-4 py-3 rounded-lg text-sm font-medium border transition
                        ${form.membership_type === type
                          ? 'bg-blue-600 text-white border-blue-600'
                          : 'bg-white text-gray-600 border-gray-300 hover:border-blue-400 hover:text-blue-600'}`}
                    >
                      {type}
                    </button>
                  ))}
                </div>
              </div>
              <div>
                <label className="block text-xs font-medium text-gray-600 mb-2">Do you want a personal trainer? *</label>
                <div className="flex gap-3">
                  <button
                    type="button"
                    onClick={() => update('wants_trainer', true)}
                    className={`flex-1 py-3 rounded-lg text-sm font-medium border transition
                      ${form.wants_trainer === true
                        ? 'bg-green-500 text-white border-green-500'
                        : 'bg-white text-gray-600 border-gray-300 hover:border-green-400'}`}
                  >
                    ✅ Yes
                  </button>
                  <button
                    type="button"
                    onClick={() => update('wants_trainer', false)}
                    className={`flex-1 py-3 rounded-lg text-sm font-medium border transition
                      ${form.wants_trainer === false
                        ? 'bg-gray-600 text-white border-gray-600'
                        : 'bg-white text-gray-600 border-gray-300 hover:border-gray-500'}`}
                  >
                    ❌ No
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* Step 3 — Emergency Contact */}
          {step === 3 && (
            <div className="space-y-4">
              <h3 className="font-semibold text-gray-700 mb-3">Emergency Contact</h3>
              <div>
                <label className="block text-xs font-medium text-gray-600 mb-1">
                  Emergency Contact Name & Number *
                </label>
                <input
                  type="text"
                  value={form.emergency_contact}
                  onChange={e => update('emergency_contact', e.target.value)}
                  placeholder="Maria Dela Cruz — 09XXXXXXXXX"
                  className="w-full border border-gray-300 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                <p className="text-xs text-gray-400 mt-1">Format: Name — Phone number</p>
              </div>

              {/* Summary */}
              <div className="bg-gray-50 border border-gray-200 rounded-xl p-4 mt-4 space-y-2 text-sm">
                <p className="font-semibold text-gray-700 mb-2">Registration Summary</p>
                <div className="grid grid-cols-2 gap-x-4 gap-y-1 text-gray-600">
                  <span className="text-gray-400">Name</span><span className="font-medium">{form.full_name}</span>
                  <span className="text-gray-400">Age / Gender</span><span>{form.age} / {form.gender}</span>
                  <span className="text-gray-400">Email</span><span className="truncate">{form.email}</span>
                  <span className="text-gray-400">Goal</span><span>{form.goal}</span>
                  <span className="text-gray-400">Membership</span><span>{form.membership_type}</span>
                  <span className="text-gray-400">Wants Trainer</span><span>{form.wants_trainer ? 'Yes' : 'No'}</span>
                </div>
              </div>
            </div>
          )}

          {/* Navigation Buttons */}
          <div className="flex gap-3 mt-6">
            {step > 0 && (
              <button
                type="button"
                onClick={prevStep}
                className="flex-1 bg-gray-100 text-gray-600 py-3 rounded-lg text-sm font-semibold hover:bg-gray-200 transition"
              >
                ← Back
              </button>
            )}
            {step < STEPS.length - 1 ? (
              <button
                type="button"
                onClick={nextStep}
                className="flex-1 bg-blue-600 text-white py-3 rounded-lg text-sm font-semibold hover:bg-blue-700 transition"
              >
                Next →
              </button>
            ) : (
              <button
                type="button"
                onClick={handleSubmit}
                disabled={loading}
                className="flex-1 bg-green-600 text-white py-3 rounded-lg text-sm font-semibold hover:bg-green-700 transition disabled:opacity-50"
              >
                {loading ? 'Submitting...' : '✅ Submit Registration'}
              </button>
            )}
          </div>

          <p className="text-center text-xs text-gray-400 mt-4">
            Step {step + 1} of {STEPS.length}
          </p>
        </div>
      </div>
    </div>
  )
}