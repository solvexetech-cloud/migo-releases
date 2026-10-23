import { useRole, ROLES } from '../contexts/RoleContext';

// ═══════════════════════════════════════════════════
// NAV ITEMS BY ROLE
// ═══════════════════════════════════════════════════
const ALL_ITEMS = [
  { to: '/', label: 'Dashboard', icon: '📊' },
  { to: '/businesses', label: 'Businesses', icon: '🏢' },
  { to: '/map', label: 'Business Map', icon: '🗺️' },
  { to: '/analytics', label: 'Analytics', icon: '📊' },
  { to: '/pending-businesses', label: 'Pending', icon: '⏳' },
  { to: '/offers', label: 'Pending Offers', icon: '🎁' },
  { to: '/all-offers', label: 'All Offers', icon: '🏷️' },
  { to: '/flyers', label: 'Flyers', icon: '📄' }, // ✅ ഇവിടെ ചേർത്തു
  { to: '/users', label: 'Users', icon: '👥' },
  { to: '/creators', label: 'Creators', icon: '🎬' },
  { to: '/fraud-logs', label: 'Fraud Logs', icon: '🚨' },
  { to: '/categories', label: 'Categories', icon: '📁' },
  { to: '/roles', label: 'Roles', icon: '🔑' },
  { to: '/agencies', label: 'Agencies', icon: '🤝' },
  { to: '/pricing', label: 'Pricing', icon: '💵' },
  { to: '/share-rewards', label: 'Share Rewards', icon: '🎁' },
  { to: '/strings', label: 'App Strings', icon: '🌐' },
  { to: '/revenue', label: 'Revenue', icon: '💰' },
  { to: '/reviews', label: 'Reviews', icon: '⭐' },
  { to: '/geography', label: 'Geography', icon: '🌍' },
  { to: '/ads', label: 'Ads Config', icon: '📢' },
  { to: '/revenue-split', label: 'Revenue Split', icon: '💰' },
  { to: '/reservations', label: 'Reservations', icon: '🎫' },
  { to: '/reservation-rules', label: 'Reserve Rules', icon: '📜' },
  { to: '/reservation-config', label: 'Reserve Config', icon: '⚙️' },
  { to: '/no-show-log', label: 'No-Show Log', icon: '🚫' },
  { to: '/marketing', label: 'Marketing', icon: '📈' },
];

// ═══════════════════════════════════════════════════
// ROLE → ALLOWED PATHS
// ═══════════════════════════════════════════════════
const ROLE_PATHS = {
  // Super Admin — everything
  [ROLES.SUPER_ADMIN]: ALL_ITEMS.map((i) => i.to),

  // Admin — country/state level
  [ROLES.ADMIN]: [
    '/',
    '/businesses',
    '/map',
    '/analytics',
    '/pending-businesses',
    '/offers',
    '/users',
    '/creators',
    '/reviews',
    '/reservations',
    '/no-show-log',
    '/revenue',
    '/flyers', // ✅ ചേർത്തു
  ],

  // Agency — own area only
  [ROLES.AGENCY]: [
    '/',
    '/agency-dashboard',
    '/businesses',
    '/map',
    '/pending-businesses',
    '/offers',
    '/reviews',
    '/reservations',
    '/no-show-log',
    '/flyers', // ✅ ചേർത്തു
  ],

  // Moderator (Staff) — approvals + reviews
  [ROLES.MODERATOR]: [
    '/',
    '/staff-dashboard',
    '/pending-businesses',
    '/offers',
    '/reviews',
    '/users',
    '/fraud-logs',
    '/flyers', // ✅ ചേർത്തു
  ],
};

// ═══════════════════════════════════════════════════
// HOOK
// ═══════════════════════════════════════════════════
export function useRoleNav() {
  const { role } = useRole();

  if (!role || !ROLE_PATHS[role]) {
    return { navItems: [], canAccess: () => false };
  }

  const allowedPaths = ROLE_PATHS[role];
  const navItems = ALL_ITEMS.filter((item) =>
    allowedPaths.includes(item.to)
  );

  function canAccess(path) {
    return allowedPaths.includes(path);
  }

  return { navItems, canAccess };
}