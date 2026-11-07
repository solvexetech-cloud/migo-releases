import { useState } from 'react';
import { NavLink, useNavigate, useLocation } from 'react-router-dom';
import { signOut } from 'firebase/auth';
import { auth } from '../firebase';
import { useIsMobile } from '../hooks/useIsMobile';
import { useRoleNav } from '../hooks/useRoleNav';
import { useRole } from '../contexts/RoleContext';

export default function AdminLayout({ user, children }) {
  const navigate = useNavigate();
  const location = useLocation();
  const isMobile = useIsMobile();
  const [drawerOpen, setDrawerOpen] = useState(false);
  const { navItems } = useRoleNav();
  const { role } = useRole();

  const [openGroups, setOpenGroups] = useState(['Community Demands']);

  const toggleGroup = (label) => {
    setOpenGroups((prev) =>
      prev.includes(label) ? prev.filter((l) => l !== label) : [...prev, label]
    );
  };

  async function handleSignOut() {
    await signOut(auth);
    navigate('/login');
    window.location.reload();
  }

  function closeDrawer() {
    setDrawerOpen(false);
  }

  const sidebarContent = (
    <>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 30, paddingBottom: 20, borderBottom: '1px solid rgba(255,255,255,0.1)' }}>
        <div style={{ width: 38, height: 38, borderRadius: 10, background: 'linear-gradient(135deg, #F0C566 0%, #D4A13A 100%)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18 }}>
          🎁
        </div>
        <div>
          <div style={{ fontSize: 20, fontWeight: 900, letterSpacing: 3, lineHeight: 1 }}>MIGO</div>
          <div style={{ fontSize: 10, fontWeight: 700, color: '#F0C566', letterSpacing: 1.5, marginTop: 2 }}>ADMIN</div>
        </div>
      </div>

      <nav style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        {navItems.map((item) => {
          if (item.children) {
            const isAnyChildActive = item.children.some((child) => location.pathname === child.to);
            return (
              <div key={item.label}>
                <div
                  style={{
                    display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', borderRadius: 10, fontSize: 14, fontWeight: 700,
                    color: isAnyChildActive ? '#0B2B5B' : 'rgba(255,255,255,0.85)',
                    background: isAnyChildActive ? 'linear-gradient(135deg, #F0C566 0%, #D4A13A 100%)' : 'transparent',
                    cursor: 'pointer',
                  }}
                  onClick={() => toggleGroup(item.label)}
                >
                  <span style={{ fontSize: 18 }}>{item.icon}</span>
                  <span style={{ flex: 1 }}>{item.label}</span>
                  <span style={{ fontSize: 12 }}>{openGroups.includes(item.label) ? '▲' : '▼'}</span>
                </div>
                {openGroups.includes(item.label) && (
                  <div style={{ marginLeft: 20, marginTop: 4 }}>
                    {item.children.map((child) => (
                      <NavLink
                        key={child.to}
                        to={child.to}
                        onClick={isMobile ? closeDrawer : undefined}
                        style={({ isActive }) => ({
                          display: 'flex', alignItems: 'center', gap: 10, padding: '10px 12px', borderRadius: 8, fontSize: 13, fontWeight: 600, textDecoration: 'none',
                          color: isActive ? 'white' : 'rgba(255,255,255,0.7)',
                          background: isActive ? 'rgba(240,197,102,0.2)' : 'transparent',
                          marginBottom: 2,
                        })}
                      >
                        <span style={{ fontSize: 14 }}>{child.icon}</span>
                        <span>{child.label}</span>
                      </NavLink>
                    ))}
                  </div>
                )}
              </div>
            );
          }

          return (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              onClick={isMobile ? closeDrawer : undefined}
              style={({ isActive }) => ({
                display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', borderRadius: 10, fontSize: 14, fontWeight: 700, textDecoration: 'none',
                color: isActive ? '#0B2B5B' : 'rgba(255,255,255,0.85)',
                background: isActive ? 'linear-gradient(135deg, #F0C566 0%, #D4A13A 100%)' : 'transparent',
                transition: 'all 0.15s',
              })}
            >
              <span style={{ fontSize: 18 }}>{item.icon}</span>
              <span>{item.label}</span>
            </NavLink>
          );
        })}
      </nav>

      <div style={{ flex: 1 }} />

      <div style={{ borderTop: '1px solid rgba(255,255,255,0.1)', paddingTop: 16, marginTop: 16 }}>
        <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.6)', marginBottom: 6, letterSpacing: 0.5 }}>
          SIGNED IN AS - {role?.toUpperCase()}
        </div>
        <div style={{ fontSize: 12, fontWeight: 700, color: 'white', marginBottom: 12, wordBreak: 'break-all' }}>
          {user?.email}
        </div>
        <button
          onClick={handleSignOut}
          style={{ width: '100%', padding: '10px 14px', borderRadius: 10, border: '1px solid rgba(255,255,255,0.25)', background: 'rgba(255,255,255,0.05)', color: 'white', fontSize: 13, fontWeight: 700, cursor: 'pointer' }}
        >
          Sign out
        </button>
      </div>
    </>
  );

  return (
    <div style={{ display: 'flex', minHeight: '100vh' }}>
      {!isMobile && (
        <aside style={{ width: 260, background: 'linear-gradient(180deg, #0B2B5B 0%, #061B3D 100%)', color: 'white', display: 'flex', flexDirection: 'column', padding: 20, position: 'sticky', top: 0, height: '100vh', overflowY: 'auto', flexShrink: 0 }}>
          {sidebarContent}
        </aside>
      )}

      {isMobile && drawerOpen && (
        <>
          <div onClick={closeDrawer} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', zIndex: 999 }} />
          <aside style={{ position: 'fixed', top: 0, left: 0, bottom: 0, width: 280, maxWidth: '85vw', background: 'linear-gradient(180deg, #0B2B5B 0%, #061B3D 100%)', color: 'white', display: 'flex', flexDirection: 'column', padding: 20, overflowY: 'auto', zIndex: 1000, boxShadow: '4px 0 24px rgba(0,0,0,0.25)' }}>
            {sidebarContent}
          </aside>
        </>
      )}

      <main style={{ flex: 1, background: '#F6F3EE', minHeight: '100vh', minWidth: 0 }}>
        {isMobile && (
          <div style={{ position: 'sticky', top: 0, zIndex: 100, background: 'linear-gradient(135deg, #0B2B5B 0%, #061B3D 100%)', padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 12, boxShadow: '0 2px 8px rgba(0,0,0,0.15)' }}>
            <button onClick={() => setDrawerOpen(true)} style={{ background: 'transparent', border: 'none', color: 'white', fontSize: 26, cursor: 'pointer', padding: 4, lineHeight: 1 }} aria-label="Open menu">
              ☰
            </button>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <div style={{ width: 30, height: 30, borderRadius: 8, background: 'linear-gradient(135deg, #F0C566 0%, #D4A13A 100%)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 14 }}>
                🎁
              </div>
              <div>
                <div style={{ fontSize: 14, fontWeight: 900, letterSpacing: 2, lineHeight: 1, color: 'white' }}>MIGO</div>
                <div style={{ fontSize: 8, fontWeight: 700, color: '#F0C566', letterSpacing: 1, marginTop: 1 }}>ADMIN</div>
              </div>
            </div>
          </div>
        )}
        {children}
      </main>
    </div>
  );
}