import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'

// NOTE: AuthProvider is already inside App.jsx — do NOT wrap it here again.
// NOTE: StrictMode removed — it causes Supabase auth listeners to fire twice
//       in development which can hang insert/select calls.

createRoot(document.getElementById('root')).render(
  <App />
)