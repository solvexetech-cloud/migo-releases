import { useEffect, useState } from 'react';
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
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
import CategoriesPage from './pages/CategoriesPage';
import RolesPage from './pages/RolesPage';
import GeographyPage from './pages/GeographyPage';
import RevenuePage from './pages/RevenuePage';
import ReviewsPage from './pages/ReviewsPage';
import PricingPage from './pages/PricingPage';
import StringsPage from './pages/StringsPage';
import BusinessesMapPage from './pages/BusinessesMapPage';
import AnalyticsPage from './pages/AnalyticsPage';
import AgenciesPage from './pages/AgenciesPage';
import AdsConfigPage from './pages/AdsConfigPage';
import RevenueSplitPage from './pages/RevenueSplitPage';
import ReservationsPage from './pages/ReservationsPage';
import ReservationRulesPage from './pages/ReservationRulesPage';
import ReservationConfigPage from './pages/ReservationConfigPage';
import NoShowLogPage from './pages/NoShowLogPage';
import MarketingDashboardPage from "./pages/MarketingDashboardPage";

export default function App() {
  const [user, setUser] = useState(null);
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (u) => {
            if (u) {
        // Verify admin/moderator/super_admin role
        const snap = await getDoc(doc(db, 'users', u.uid));
        const role = snap.exists() ? snap.data().role : null;
        const allowedRoles = ['super_admin', 'admin', 'moderator'];
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
                   <Route path="/businesses" element={<BusinessesPage />} />
                   <Route path="/pending-businesses" element={<PendingBusinesses />} />
                   <Route
                    path="/offers"
                    element={<PendingOffers />}
                  />
                            <Route path="/users" element={<UsersPage />} />
                  <Route
                    path="/categories"
                    element={<CategoriesPage />}
                  />
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

