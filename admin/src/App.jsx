import { useEffect, useState } from 'react';
import {
  BrowserRouter,
  Navigate,
  Route,
  Routes,
} from 'react-router-dom';
import { onAuthStateChanged } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db } from './firebase';
import AdminLayout from './components/AdminLayout';
import AdminLogin from './pages/AdminLogin';
import AdminDashboard from './pages/AdminDashboard';
import PendingBusinesses from './pages/PendingBusinesses';
import BusinessesPage from './pages/BusinessesPage';
import PendingOffers from './pages/PendingOffers';
import UsersPage from './pages/UsersPage';
import CreatorsPage from './pages/CreatorsPage';
import FraudLogsPage from './pages/FraudLogsPage';
import CategoriesPage from './pages/CategoriesPage';
import RolesPage from './pages/RolesPage';
import {
  RoleProvider,
  useRole,
} from './contexts/RoleContext';
import AllOffersPage from './pages/AllOffersPage';
import GeographyPage from './pages/GeographyPage';
import RevenuePage from './pages/RevenuePage';
import ReviewsPage from './pages/ReviewsPage';
import PricingPage from './pages/PricingPage';
import StringsPage from './pages/StringsPage';
import BusinessesMapPage from './pages/BusinessesMapPage';
import AnalyticsPage from './pages/AnalyticsPage';
import AgenciesPage from './pages/AgenciesPage';
import AgencyDashboard from './pages/AgencyDashboard';
import StaffDashboard from './pages/StaffDashboard';
import AdsConfigPage from './pages/AdsConfigPage';
import RevenueSplitPage from './pages/RevenueSplitPage';
import ReservationsPage from './pages/ReservationsPage';
import ReservationRulesPage from './pages/ReservationRulesPage';
import ReservationConfigPage from './pages/ReservationConfigPage';
import NoShowLogPage from './pages/NoShowLogPage';
import MarketingDashboardPage from './pages/MarketingDashboardPage';

// ═══════════════════════════════════════════════════
// J4 — RoleRedirect: role അനുസരിച്ച് landing page
// ═══════════════════════════════════════════════════
function RoleRedirect() {
  const { role, loading } = useRole();

  if (loading) {
    return (
      <div
        style={{
          padding: 40,
          textAlign: 'center',
          color: '#666',
          fontSize: 14,
        }}
      >
        Loading...
      </div>
    );
  }

  // Agency → Agency Dashboard
  if (role === 'agency') {
    return <Navigate to="/agency-dashboard" replace />;
  }

  // Moderator (Staff) → Staff Dashboard
  if (role === 'moderator') {
    return <Navigate to="/staff-dashboard" replace />;
  }

  // super_admin / admin → Admin Dashboard
  return <AdminDashboard />;
}

export default function App() {
  const [user, setUser] = useState(null);
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (u) => {
      if (u) {
        const snap = await getDoc(doc(db, 'users', u.uid));
        const role = snap.exists() ? snap.data().role : null;
        const allowedRoles = ['super_admin', 'admin', 'moderator', 'agency'];
        if (snap.exists() && allowedRoles.includes(role)) {
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
    <RoleProvider>
      <BrowserRouter>
        <Routes>
          <Route
            path="/login"
            element={
              user ? (
                <Navigate to="/" replace />
              ) : (
                <AdminLogin onLogin={setUser} />
              )
            }
          />
          <Route
            path="/*"
            element={
              user ? (
                <AdminLayout user={user}>
                  <Routes>
                    {/* ─── J4: Role-based landing ─── */}
                    <Route path="/" element={<RoleRedirect />} />

                    {/* ─── Role-specific dashboards ─── */}
                    <Route path="/agency-dashboard" element={<AgencyDashboard />} />
                    <Route path="/staff-dashboard" element={<StaffDashboard />} />

                    {/* ─── Regular pages ─── */}
                    <Route path="/businesses" element={<BusinessesPage />} />
                    <Route path="/pending-businesses" element={<PendingBusinesses />} />
                    <Route path="/pending-offers" element={<PendingOffers />} />
                    <Route path="/all-offers" element={<AllOffersPage />} />
                    <Route path="/users" element={<UsersPage />} />
                    <Route path="/creators" element={<CreatorsPage />} />
                    <Route path="/categories" element={<CategoriesPage />} />
                    <Route path="/roles" element={<RolesPage />} />
                    <Route path="/geography" element={<GeographyPage />} />
                    <Route path="/revenue" element={<RevenuePage />} />
                    <Route path="/reviews" element={<ReviewsPage />} />
                    <Route path="/pricing" element={<PricingPage />} />
                    <Route path="/strings" element={<StringsPage />} />
                    <Route path="/map" element={<BusinessesMapPage />} />
                    <Route path="/analytics" element={<AnalyticsPage />} />
                    <Route path="/agencies" element={<AgenciesPage />} />
                    <Route path="/revenue-split" element={<RevenueSplitPage />} />
                    <Route path="/ads" element={<AdsConfigPage />} />
                    <Route path="/reservations" element={<ReservationsPage />} />
                    <Route path="/reservation-rules" element={<ReservationRulesPage />} />
                    <Route path="/reservation-config" element={<ReservationConfigPage />} />
                    <Route path="/no-show-log" element={<NoShowLogPage />} />
                    <Route path="/marketing" element={<MarketingDashboardPage />} />
                    <Route path="/fraud-logs" element={<FraudLogsPage />} />
                  </Routes>
                </AdminLayout>
              ) : (
                <Navigate to="/login" replace />
              )
            }
          />
        </Routes>
      </BrowserRouter>
    </RoleProvider>
  );
}