import {
  createContext,
  useContext,
  useEffect,
  useState,
} from 'react';
import {
  onAuthStateChanged,
  signOut,
} from 'firebase/auth';
import {
  doc,
  onSnapshot,
} from 'firebase/firestore';
import { auth, db } from '../firebase';

const RoleContext = createContext(null);

// ═══════════════════════════════════════════════════
// ROLE DEFINITIONS
// ═══════════════════════════════════════════════════
export const ROLES = {
  SUPER_ADMIN: 'super_admin',
  ADMIN: 'admin',
  AGENCY: 'agency',
  MODERATOR: 'moderator',
  BUSINESS: 'business',
  CUSTOMER: 'customer',
};

// Role hierarchy — higher number = more access
export const ROLE_LEVEL = {
  super_admin: 100,
  admin: 80,
  agency: 60,
  moderator: 40,
  business: 20,
  customer: 0,
};

export function RoleProvider({ children }) {
  const [user, setUser] = useState(null);
  const [role, setRole] = useState(null);
  const [userData, setUserData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let unsubDoc = null;

    const unsub = onAuthStateChanged(auth, (fbUser) => {
      // Cleanup previous listener
      if (unsubDoc) {
        unsubDoc();
        unsubDoc = null;
      }

      if (!fbUser) {
        setUser(null);
        setRole(null);
        setUserData(null);
        setLoading(false);
        return;
      }

      setUser(fbUser);

      // Listen to user doc for role
      const userDoc = doc(db, 'users', fbUser.uid);
      unsubDoc = onSnapshot(
        userDoc,
        (snap) => {
          if (snap.exists()) {
            const data = snap.data();
            setUserData(data);
            setRole(data.role || ROLES.CUSTOMER);
          } else {
            setRole(ROLES.CUSTOMER);
          }
          setLoading(false);
        },
        (err) => {
          // Silent — usually during signOut transition
          // Only log non-permission errors
          if (err?.code !== 'permission-denied') {
            console.warn('Role fetch error:', err);
          }
          setLoading(false);
        }
      );
    });

    return () => {
      if (unsubDoc) unsubDoc();
      unsub();
    };
  }, []);

  async function logout() {
    await signOut(auth);
  }

  // Helper: check if role level >= min
  function hasMinRole(minRole) {
    if (!role) return false;
    return (ROLE_LEVEL[role] || 0) >= (ROLE_LEVEL[minRole] || 0);
  }

  // Helper: check if role is one of list
  function isRole(...roles) {
    return roles.includes(role);
  }

  const value = {
    user,
    role,
    userData,
    loading,
    logout,
    hasMinRole,
    isRole,
    isSuperAdmin: role === ROLES.SUPER_ADMIN,
    isAdmin: role === ROLES.ADMIN,
    isAgency: role === ROLES.AGENCY,
    isModerator: role === ROLES.MODERATOR,
  };

  return (
    <RoleContext.Provider value={value}>
      {children}
    </RoleContext.Provider>
  );
}

export function useRole() {
  const ctx = useContext(RoleContext);
  if (!ctx) {
    throw new Error('useRole must be used within RoleProvider');
  }
  return ctx;
}