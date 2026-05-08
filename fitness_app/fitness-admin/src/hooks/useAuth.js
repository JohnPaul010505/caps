// Reads from the ONE shared AuthContext.
// No useState. No getSession. No duplicate Supabase calls.
// Auth is fetched once in <AuthProvider> in App.jsx and shared here.
import { useAuthContext } from '../context/AuthContext'

export function useAuth() {
  return useAuthContext()
}