import { useEffect, useState } from 'react';
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { onAuthStateChanged } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db } from './firebase';
import AdminLayout from './components/AdminLayout';
import AdminLogin from './pages/AdminLogin';
import AdminDashboard from './pages/AdminDashboard';
import PendingBusinesses from './pages/PendingBusinesses';

export default function App() {
  const [user, setUser] = useState(null);
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (u) => {
      if (u) {
        // Verify admin role
        const snap = await getDoc(doc(db, 'users', u.uid));
        if (snap.exists() && snap.data().role === 'admin') {
          setUser(u);
        } else {
          setUser(null);
        }
      } else {
        setUser(null);
      }
      setChecking(false);
    });
    return () => unsub();
  }, []);

  if (checking) {
    return (
      <div
        style={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: '#F6F3EE',
          color: '#6B7280',
          fontSize: 14,
        }}
      >
        Loading admin panel…
      </div>
    );
  }

  return (
    <BrowserRouter>
      <Routes>
        <Route
          path="/login"
          element={
            user ? <Navigate to="/" replace /> : <AdminLogin onLogin={setUser} />
          }
        />
        <Route
          path="/*"
          element={
            user ? (
              <AdminLayout user={user}>
                <Routes>
                  <Route path="/" element={<AdminDashboard />} />
                                    <Route
                    path="/businesses"
                    element={<PendingBusinesses />}
                  />
                  <Route
                    path="/offers"
                    element={<Placeholder title="Pending Offers" />}
                  />
                  <Route
                    path="/users"
                    element={<Placeholder title="Users" />}
                  />
                </Routes>
              </AdminLayout>
            ) : (
              <Navigate to="/login" replace />
            )
          }
        />
      </Routes>
    </BrowserRouter>
  );
}

function Placeholder({ title }) {
  return (
    <div style={{ padding: 32 }}>
      <h1
        style={{
          fontSize: 28,
          fontWeight: 900,
          color: '#0B2B5B',
          marginBottom: 8,
        }}
      >
        {title}
      </h1>
      <p style={{ color: '#6B7280' }}>Coming in the next step.</p>
    </div>
  );
}