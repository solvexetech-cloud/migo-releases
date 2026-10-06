import { NavLink, useNavigate } from 'react-router-dom';
import { signOut } from 'firebase/auth';
import { auth } from '../firebase';

const NAV_ITEMS = [
  { to: '/', label: 'Dashboard', icon: '📊' },
  { to: '/businesses', label: 'Pending Businesses', icon: '🏪' },
  { to: '/offers', label: 'Pending Offers', icon: '🏷️' },
  { to: '/users', label: 'Users', icon: '👥' },
  { to: '/categories', label: 'Categories', icon: '📁' },
];

export default function AdminLayout({ user, children }) {
  const navigate = useNavigate();

  async function handleSignOut() {
    await signOut(auth);
    navigate('/login');
    window.location.reload();
  }

  return (
    <div style={{ display: 'flex', minHeight: '100vh' }}>
      {/* Sidebar */}
      <aside
        style={{
          width: 260,
          background:
            'linear-gradient(180deg, #0B2B5B 0%, #061B3D 100%)',
          color: 'white',
          display: 'flex',
          flexDirection: 'column',
          padding: 20,
          position: 'sticky',
          top: 0,
          height: '100vh',
          overflowY: 'auto',
        }}
      >
        {/* Logo */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 10,
            marginBottom: 30,
            paddingBottom: 20,
            borderBottom: '1px solid rgba(255,255,255,0.1)',
          }}
        >
          <div
            style={{
              width: 38,
              height: 38,
              borderRadius: 10,
              background:
                'linear-gradient(135deg, #F0C566 0%, #D4A13A 100%)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: 18,
            }}
          >
            🎁
          </div>
          <div>
            <div
              style={{
                fontSize: 20,
                fontWeight: 900,
                letterSpacing: 3,
                lineHeight: 1,
              }}
            >
              MIGO
            </div>
            <div
              style={{
                fontSize: 10,
                fontWeight: 700,
                color: '#F0C566',
                letterSpacing: 1.5,
                marginTop: 2,
              }}
            >
              ADMIN
            </div>
          </div>
        </div>

        {/* Nav */}
        <nav style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
          {NAV_ITEMS.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              style={({ isActive }) => ({
                display: 'flex',
                alignItems: 'center',
                gap: 12,
                padding: '12px 14px',
                borderRadius: 10,
                fontSize: 14,
                fontWeight: 700,
                textDecoration: 'none',
                color: isActive ? '#0B2B5B' : 'rgba(255,255,255,0.85)',
                background: isActive
                  ? 'linear-gradient(135deg, #F0C566 0%, #D4A13A 100%)'
                  : 'transparent',
                transition: 'all 0.15s',
              })}
            >
              <span style={{ fontSize: 18 }}>{item.icon}</span>
              <span>{item.label}</span>
            </NavLink>
          ))}
        </nav>

        <div style={{ flex: 1 }} />

        {/* Admin info + sign out */}
        <div
          style={{
            borderTop: '1px solid rgba(255,255,255,0.1)',
            paddingTop: 16,
            marginTop: 16,
          }}
        >
          <div
            style={{
              fontSize: 11,
              color: 'rgba(255,255,255,0.6)',
              marginBottom: 6,
              letterSpacing: 0.5,
            }}
          >
            SIGNED IN AS
          </div>
          <div
            style={{
              fontSize: 12,
              fontWeight: 700,
              color: 'white',
              marginBottom: 12,
              wordBreak: 'break-all',
            }}
          >
            {user?.email}
          </div>
          <button
            onClick={handleSignOut}
            style={{
              width: '100%',
              padding: '10px 14px',
              borderRadius: 10,
              border: '1px solid rgba(255,255,255,0.25)',
              background: 'rgba(255,255,255,0.05)',
              color: 'white',
              fontSize: 13,
              fontWeight: 700,
              cursor: 'pointer',
            }}
          >
            Sign out
          </button>
        </div>
      </aside>

      {/* Main content */}
      <main
        style={{
          flex: 1,
          background: '#F6F3EE',
          minHeight: '100vh',
        }}
      >
        {children}
      </main>
    </div>
  );
}