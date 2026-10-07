import { useEffect, useMemo, useState } from 'react';
import {
  collection,
  doc,
  onSnapshot,
  updateDoc,
  serverTimestamp,
} from 'firebase/firestore';
import { db, auth } from '../firebase';
import { useIsMobile } from '../hooks/useIsMobile';

// 6-tier role definitions
const ROLES = [
  {
    value: 'super_admin',
    label: 'Super Admin',
    color: '#7C3AED',
    bg: '#F3E8FF',
    description: 'Full platform control',
  },
  {
    value: 'admin',
    label: 'Admin',
    color: '#D64545',
    bg: '#FEE2E2',
    description: 'Regional management',
  },
  {
    value: 'moderator',
    label: 'Moderator',
    color: '#A67920',
    bg: '#FFF3D6',
    description: 'Staff — content & users',
  },
  {
    value: 'agency',
    label: 'Agency',
    color: '#0E7490',
    bg: '#CFFAFE',
    description: 'Franchise partner',
  },
  {
    value: 'business',
    label: 'Business',
    color: '#1E4B8F',
    bg: '#EFF6FF',
    description: 'Shop owner',
  },
  {
    value: 'customer',
    label: 'Customer',
    color: '#2E9E5B',
    bg: '#E5F5EA',
    description: 'End user',
  },
];

const ROLES_BY_VALUE = ROLES.reduce((acc, r) => {
  acc[r.value] = r;
  return acc;
}, {});

export default function RolesPage() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [myRole, setMyRole] = useState(null);
  const [working, setWorking] = useState({});
  const isMobile = useIsMobile();

  // Load current user's role
  useEffect(() => {
    const uid = auth.currentUser?.uid;
    if (!uid) return;
    const unsub = onSnapshot(doc(db, 'users', uid), (snap) => {
      if (snap.exists()) {
        setMyRole(snap.data().role || 'customer');
      }
    });
    return () => unsub();
  }, []);

  // Load all users
  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'users'), (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      const order = {
        super_admin: 0,
        admin: 1,
        moderator: 2,
        agency: 3,
        business: 4,
        customer: 5,
      };
      list.sort((a, b) => {
        const ao = order[a.role] ?? 99;
        const bo = order[b.role] ?? 99;
        if (ao !== bo) return ao - bo;
        return (a.email || '').localeCompare(b.email || '');
      });
      setUsers(list);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  const filtered = useMemo(() => {
    if (!search.trim()) return users;
    const q = search.trim().toLowerCase();
    return users.filter(
      (u) =>
        (u.email || '').toLowerCase().includes(q) ||
        (u.displayName || '').toLowerCase().includes(q) ||
        (u.role || '').toLowerCase().includes(q),
    );
  }, [users, search]);

  function canEditRole(targetUser) {
    if (!myRole) return false;
    if (myRole === 'super_admin') return true;
    if (myRole === 'admin') {
      return (
        targetUser.role !== 'super_admin' &&
        targetUser.role !== 'admin'
      );
    }
    return false;
  }

  function getAssignableRoles() {
    if (myRole === 'super_admin') return ROLES;
    if (myRole === 'admin') {
      return ROLES.filter(
        (r) => r.value !== 'super_admin' && r.value !== 'admin',
      );
    }
    return [];
  }

  async function handleChangeRole(user, newRole) {
    if (newRole === user.role) return;

    const confirmed = window.confirm(
      `Change ${user.email}'s role from "${user.role}" to "${newRole}"?`,
    );
    if (!confirmed) return;

    setWorking((w) => ({ ...w, [user.id]: true }));
    try {
      await updateDoc(doc(db, 'users', user.id), {
        role: newRole,
        updatedAt: serverTimestamp(),
      });
    } catch (e) {
      alert('Failed to change role: ' + e.message);
    } finally {
      setWorking((w) => ({ ...w, [user.id]: false }));
    }
  }

  return (
    <div
      style={{
        padding: isMobile ? 16 : 32,
        maxWidth: 1200,
      }}
    >
      <header style={{ marginBottom: 24 }}>
        <h1
          style={{
            fontSize: isMobile ? 24 : 28,
            fontWeight: 900,
            color: '#0B2B5B',
            letterSpacing: -0.5,
            marginBottom: 4,
          }}
        >
          Roles & Permissions
        </h1>
        <p style={{ fontSize: 14, color: '#6B7280' }}>
          {users.length} user{users.length !== 1 ? 's' : ''} · Your role:{' '}
          <strong style={{ color: ROLES_BY_VALUE[myRole]?.color || '#6B7280' }}>
            {ROLES_BY_VALUE[myRole]?.label || myRole}
          </strong>
        </p>
      </header>

      {/* Role Legend */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: isMobile
            ? '1fr 1fr'
            : 'repeat(auto-fit, minmax(180px, 1fr))',
          gap: 8,
          marginBottom: 20,
        }}
      >
        {ROLES.map((r) => (
          <div
            key={r.value}
            style={{
              background: r.bg,
              borderRadius: 10,
              padding: '10px 12px',
              borderLeft: `3px solid ${r.color}`,
            }}
          >
            <div
              style={{
                fontSize: 12,
                fontWeight: 800,
                color: r.color,
                marginBottom: 2,
              }}
            >
              {r.label}
            </div>
            <div style={{ fontSize: 10, color: '#6B7280' }}>
              {r.description}
            </div>
          </div>
        ))}
      </div>

      {/* Search */}
      <div
        style={{
          background: 'white',
          borderRadius: 14,
          padding: '10px 16px',
          boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
          display: 'flex',
          alignItems: 'center',
          gap: 10,
          marginBottom: 20,
        }}
      >
        <span style={{ fontSize: 16, color: '#9CA3AF' }}>🔍</span>
        <input
          type="text"
          placeholder="Search by email, name, or role…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{
            flex: 1,
            border: 'none',
            outline: 'none',
            fontSize: 14,
            background: 'transparent',
            padding: '6px 0',
            minWidth: 0,
          }}
        />
        {search && (
          <button
            onClick={() => setSearch('')}
            style={{
              border: 'none',
              background: 'transparent',
              cursor: 'pointer',
              fontSize: 18,
              color: '#9CA3AF',
            }}
          >
            ×
          </button>
        )}
      </div>

      {loading ? (
        <div style={{ color: '#6B7280' }}>Loading…</div>
      ) : filtered.length === 0 ? (
        <div
          style={{
            background: 'white',
            borderRadius: 16,
            padding: 48,
            textAlign: 'center',
            color: '#6B7280',
          }}
        >
          {search ? 'No users match your search.' : 'No users yet.'}
        </div>
      ) : (
        <div
          style={{
            background: 'white',
            borderRadius: 16,
            boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
            overflow: 'hidden',
          }}
        >
          {filtered.map((u, i) => (
            <UserRoleRow
              key={u.id}
              user={u}
              isLast={i === filtered.length - 1}
              isMobile={isMobile}
              canEdit={canEditRole(u)}
              assignableRoles={getAssignableRoles()}
              working={working[u.id]}
              onChangeRole={(newRole) => handleChangeRole(u, newRole)}
            />
          ))}
        </div>
      )}
    </div>
  );
}

function UserRoleRow({
  user,
  isLast,
  isMobile,
  canEdit,
  assignableRoles,
  working,
  onChangeRole,
}) {
  const roleInfo = ROLES_BY_VALUE[user.role] || ROLES_BY_VALUE.customer;

  if (isMobile) {
    return (
      <div
        style={{
          padding: 16,
          borderBottom: isLast ? 'none' : '1px solid #F1EEEA',
        }}
      >
        <div style={{ marginBottom: 10 }}>
          <div
            style={{
              fontSize: 14,
              fontWeight: 800,
              color: '#0B2B5B',
              wordBreak: 'break-word',
              marginBottom: 4,
            }}
          >
            {user.email || '—'}
          </div>
          {user.displayName && (
            <div style={{ fontSize: 12, color: '#6B7280' }}>
              {user.displayName}
            </div>
          )}
        </div>

        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          <span
            style={{
              display: 'inline-block',
              padding: '4px 10px',
              borderRadius: 6,
              background: roleInfo.bg,
              color: roleInfo.color,
              fontSize: 11,
              fontWeight: 800,
              letterSpacing: 0.5,
              whiteSpace: 'nowrap',
            }}
          >
            {roleInfo.label}
          </span>
          {canEdit && (
            <select
              value={user.role}
              onChange={(e) => onChangeRole(e.target.value)}
              disabled={working}
              style={{
                flex: 1,
                padding: '8px 10px',
                borderRadius: 8,
                border: '1px solid #E5E7EB',
                fontSize: 13,
                fontWeight: 700,
                background: 'white',
                cursor: working ? 'wait' : 'pointer',
                opacity: working ? 0.5 : 1,
              }}
            >
              {assignableRoles.map((r) => (
                <option key={r.value} value={r.value}>
                  {r.label}
                </option>
              ))}
            </select>
          )}
        </div>
      </div>
    );
  }

  return (
    <div
      style={{
        display: 'grid',
        gridTemplateColumns: '2fr 1fr 1fr',
        padding: '14px 20px',
        fontSize: 13,
        color: '#374151',
        borderBottom: isLast ? 'none' : '1px solid #F1EEEA',
        alignItems: 'center',
        gap: 12,
      }}
    >
      <div style={{ minWidth: 0 }}>
        <div
          style={{
            fontWeight: 800,
            color: '#0B2B5B',
            marginBottom: 2,
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            whiteSpace: 'nowrap',
          }}
        >
          {user.email || '—'}
        </div>
        {user.displayName && (
          <div style={{ fontSize: 11, color: '#9CA3AF' }}>
            {user.displayName}
          </div>
        )}
      </div>

      <div>
        <span
          style={{
            display: 'inline-block',
            padding: '4px 10px',
            borderRadius: 6,
            background: roleInfo.bg,
            color: roleInfo.color,
            fontSize: 11,
            fontWeight: 800,
            letterSpacing: 0.5,
            whiteSpace: 'nowrap',
          }}
        >
          {roleInfo.label}
        </span>
      </div>

      <div>
        {canEdit ? (
          <select
            value={user.role}
            onChange={(e) => onChangeRole(e.target.value)}
            disabled={working}
            style={{
              padding: '8px 12px',
              borderRadius: 8,
              border: '1px solid #E5E7EB',
              fontSize: 13,
              fontWeight: 700,
              background: 'white',
              cursor: working ? 'wait' : 'pointer',
              opacity: working ? 0.5 : 1,
              minWidth: 160,
            }}
          >
            {assignableRoles.map((r) => (
              <option key={r.value} value={r.value}>
                {r.label}
              </option>
            ))}
          </select>
        ) : (
          <span style={{ fontSize: 12, color: '#9CA3AF', fontStyle: 'italic' }}>
            {user.role === 'super_admin' || user.role === 'admin'
              ? 'Protected'
              : 'View only'}
          </span>
        )}
      </div>
    </div>
  );
}