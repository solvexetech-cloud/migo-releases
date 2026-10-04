import { useState } from 'react';
import AdminLogin from './pages/AdminLogin';

export default function App() {
  const [user, setUser] = useState(null);

  if (!user) {
    return <AdminLogin onLogin={(u) => setUser(u)} />;
  }

  return (
    <div style={{ padding: 40, fontFamily: 'sans-serif' }}>
      <h1>Welcome, admin!</h1>
      <p>Signed in as: {user.email}</p>
    </div>
  );
}