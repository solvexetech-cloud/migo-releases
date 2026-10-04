import { useState } from 'react';
import { signInWithEmailAndPassword, signOut } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db } from '../firebase';

export default function AdminLogin({ onLogin }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

    async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const cred = await signInWithEmailAndPassword(
        auth,
        email.trim(),
        password,
      );

      const uid = cred.user.uid;
      const userSnap = await getDoc(doc(db, 'users', uid));

      if (!userSnap.exists()) {
        await signOut(auth);
        throw new Error('User profile not found.');
      }

      const role = userSnap.data().role;
      if (role !== 'admin') {
        await signOut(auth);
        throw new Error('Access denied. Not an admin.');
      }

      onLogin(cred.user);
    } catch (err) {
      setError(err.message || 'Login failed.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div
      style={{
        minHeight: '100vh',
        background:
          'linear-gradient(135deg, #0B2B5B 0%, #1E4B8F 100%)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 20,
        fontFamily:
          '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
      }}
    >
      <div
        style={{
          width: '100%',
          maxWidth: 400,
          background: 'white',
          borderRadius: 20,
          padding: 32,
          boxShadow: '0 25px 50px -12px rgba(0,0,0,0.5)',
        }}
      >
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 10,
            marginBottom: 8,
          }}
        >
          <div
            style={{
              width: 40,
              height: 40,
              borderRadius: 10,
              background:
                'linear-gradient(135deg, #F0C566 0%, #D4A13A 100%)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: 20,
            }}
          >
            🎁
          </div>
          <div>
            <div
              style={{
                fontSize: 24,
                fontWeight: 900,
                color: '#0B2B5B',
                letterSpacing: 3,
              }}
            >
              MIGO
            </div>
            <div
              style={{
                fontSize: 11,
                fontWeight: 700,
                color: '#6B7280',
                letterSpacing: 1,
              }}
            >
              ADMIN PANEL
            </div>
          </div>
        </div>

        <h1
          style={{
            fontSize: 20,
            fontWeight: 800,
            color: '#111418',
            marginTop: 20,
            marginBottom: 6,
          }}
        >
          Sign in
        </h1>
        <p
          style={{
            fontSize: 13,
            color: '#6B7280',
            marginBottom: 24,
          }}
        >
          Admin access only. Sign in with your MIGO admin account.
        </p>

        <form onSubmit={handleSubmit}>
          <label
            style={{
              display: 'block',
              fontSize: 12,
              fontWeight: 700,
              color: '#374151',
              marginBottom: 6,
            }}
          >
            Email
          </label>
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="admin@migoapp.com"
            required
            disabled={loading}
            style={{
              width: '100%',
              padding: '12px 14px',
              borderRadius: 12,
              border: '1.5px solid #E5E7EB',
              fontSize: 14,
              marginBottom: 16,
              outline: 'none',
              boxSizing: 'border-box',
            }}
          />

          <label
            style={{
              display: 'block',
              fontSize: 12,
              fontWeight: 700,
              color: '#374151',
              marginBottom: 6,
            }}
          >
            Password
          </label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            required
            disabled={loading}
            style={{
              width: '100%',
              padding: '12px 14px',
              borderRadius: 12,
              border: '1.5px solid #E5E7EB',
              fontSize: 14,
              marginBottom: 16,
              outline: 'none',
              boxSizing: 'border-box',
            }}
          />

          {error && (
            <div
              style={{
                background: '#FEE2E2',
                color: '#D64545',
                padding: 10,
                borderRadius: 8,
                fontSize: 13,
                marginBottom: 16,
              }}
            >
              {error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            style={{
              width: '100%',
              padding: '14px',
              borderRadius: 12,
              border: 'none',
              background: loading
                ? '#94A3B8'
                : 'linear-gradient(135deg, #1E4B8F 0%, #0B2B5B 100%)',
              color: 'white',
              fontSize: 15,
              fontWeight: 800,
              cursor: loading ? 'not-allowed' : 'pointer',
              letterSpacing: 0.3,
            }}
          >
            {loading ? 'Signing in...' : 'Sign in'}
          </button>
        </form>

        <p
          style={{
            fontSize: 11,
            color: '#9CA3AF',
            textAlign: 'center',
            marginTop: 20,
          }}
        >
          Only users with role: "admin" in Firestore can access this panel.
        </p>
      </div>
    </div>
  );
}