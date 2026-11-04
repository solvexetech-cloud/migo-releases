import { useRole, ROLES } from '../contexts/RoleContext';

const ALL_ITEMS = [
  { to: '/', label: 'Dashboard', icon: '📊' },
  { to: '/businesses', label: 'Businesses', icon: '🏢' },
  { to: '/map', label: 'Business Map', icon: '🗺️' },
  { to: '/analytics', label: 'Analytics', icon: '📊' },
  { to: '/all-offers', label: 'All Offers', icon: '🏷️' },
  { to: '/flyers', label: 'Flyers', icon: '📄' },
  { to: '/users', label: 'Users', icon: '👥' },
  { to: '/creators', label: 'Creators', icon: '🎬' },
  { to: '/fraud-logs', label: 'Fraud Logs', icon: '🚨' },
  { to: '/categories', label: 'Categories', icon: '📁' },
  { to: '/coin-settings', label: 'Coin Settings', icon: '🪙' },
  { to: '/coin-payments', label: 'Coin Payments', icon: '💰' },
  // 🆕 Community Demands Group
  {
    label: 'Community Demands',
    icon: '⚖️',
    children: [
      { to: '/demand-bids', label: 'Demand Bids', icon: '📋' },
      { to: '/campaigns', label: 'Campaigns', icon: '📢' },
      { to: '/orders', label: 'Orders', icon: '📦' },
      { to: '/complaints', label: 'Complaints', icon: '⚠️' },
      { to: '/demand-matching', label: 'Demand Matching', icon: '🔄' },
    ],
  },
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

const ROLE_PATHS = {
    [ROLES.SUPER_ADMIN]: ALL_ITEMS.flatMap((item) => 
    item.children ? item.children.map((c) => c.to) : [item.to]
  ),
    [ROLES.ADMIN]: [
    '/', '/businesses', '/map', '/analytics', '/users', '/creators',
    '/reviews', '/reservations', '/no-show-log', '/revenue', '/flyers', '/all-offers',
    '/demand-matching', // 🆕 ഇത് ഇവിടെ ചേർക്കുക
    '/demand-bids', '/campaigns', '/orders', '/complaints',
  ],
  [ROLES.AGENCY]: [
    '/', '/agency-dashboard', '/businesses', '/map', '/reviews',
    '/reservations', '/no-show-log', '/flyers',
    '/demand-bids', '/campaigns', '/orders', '/complaints',
  ],
  [ROLES.MODERATOR]: [
    '/', '/staff-dashboard', '/businesses', '/reviews', '/users',
    '/fraud-logs', '/flyers',
    '/demand-bids', '/campaigns', '/orders', '/complaints',
  ],
};

export function useRoleNav() {
  const { role } = useRole();
  if (!role || !ROLE_PATHS[role]) {
    return { navItems: [], canAccess: () => false };
  }
  const allowedPaths = ROLE_PATHS[role];
  const navItems = ALL_ITEMS.map((item) => {
    if (item.children) {
      const allowedChildren = item.children.filter((child) => allowedPaths.includes(child.to));
      if (allowedChildren.length === 0) return null;
      return { ...item, children: allowedChildren };
    }
    return allowedPaths.includes(item.to) ? item : null;
  }).filter(Boolean);
  function canAccess(path) {
    return allowedPaths.includes(path);
  }
  return { navItems, canAccess };
}