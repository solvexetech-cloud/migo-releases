import { useEffect, useState } from "react";
import { db } from "../firebase";
import {
  collection,
  getDocs,
  query,
  orderBy,
  limit,
} from "firebase/firestore";

const COLORS = {
  primary: "#1E40AF",
  success: "#10B981",
  warning: "#F59E0B",
  error: "#EF4444",
  purple: "#7C3AED",
  gray: "#6B7280",
  lightGray: "#F3F4F6",
};

const CHANNELS = [
  { id: "google_ads", name: "Google Ads", color: "#4285F4" },
  { id: "facebook", name: "Facebook", color: "#1877F2" },
  { id: "instagram", name: "Instagram", color: "#E4405F" },
  { id: "referral", name: "Referrals", color: "#10B981" },
  { id: "organic", name: "Organic", color: "#6B7280" },
];

export default function MarketingDashboardPage() {
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    totalSpend: 0,
    totalRevenue: 0,
    roi: 0,
    newCustomers: 0,
    totalClaims: 0,
    totalRedeems: 0,
    totalViews: 0,
  });
  const [channelData, setChannelData] = useState([]);
  const [funnelData, setFunnelData] = useState([]);
  const [topOffers, setTopOffers] = useState([]);
  const [topReferrers, setTopReferrers] = useState([]);

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    setLoading(true);
    try {
      // 1. Load all claims
      const claimsSnap = await getDocs(collection(db, "claims"));
      const claims = claimsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
      const totalClaims = claims.length;
      const totalRedeems = claims.filter(
        (c) => c.status === "redeemed"
      ).length;

      // 2. Load customer behavior (views, saves)
      let totalViews = 0;
      try {
        const behaviorSnap = await getDocs(
          query(collection(db, "customer_behavior"), limit(1000))
        );
        totalViews = behaviorSnap.size;
      } catch (e) {
        console.warn("customer_behavior error:", e.message);
      }

      // 3. Load users (new customers)
      const usersSnap = await getDocs(collection(db, "users"));
      const users = usersSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
      const newCustomers = users.filter(
        (u) => u.role === "customer"
      ).length;

      // 4. Load revenue splits
      let totalRevenue = 0;
      try {
        const splitsSnap = await getDocs(
          collection(db, "revenue_splits")
        );
        splitsSnap.forEach((d) => {
          const data = d.data();
          totalRevenue += Number(data.amount || 0);
        });
      } catch (e) {
        console.warn("revenue_splits error:", e.message);
      }

      // 5. Calculate total spend (estimated)
      const totalSpend = Math.round(totalRevenue * 0.3); // 30% as spend

      // 6. Calculate ROI
      const roi = totalSpend > 0
        ? ((totalRevenue - totalSpend) / totalSpend) * 100
        : 0;

      setStats({
        totalSpend,
        totalRevenue,
        roi,
        newCustomers,
        totalClaims,
        totalRedeems,
        totalViews,
      });

      // 7. Channel data (mock based on new customers)
      const channels = CHANNELS.map((ch, i) => {
        const share = [0.4, 0.25, 0.15, 0.15, 0.05][i] || 0;
        return {
          ...ch,
          customers: Math.round(newCustomers * share),
          revenue: Math.round(totalRevenue * share),
        };
      });
      setChannelData(channels);

      // 8. Conversion funnel
      setFunnelData([
        { label: "Views", value: totalViews, color: COLORS.gray },
        { label: "Claims", value: totalClaims, color: COLORS.primary },
        { label: "Redeems", value: totalRedeems, color: COLORS.success },
      ]);

      // 9. Top offers (by claim count)
      const offerCounts = {};
      claims.forEach((c) => {
        const key = c.offerTitle || "Unknown";
        offerCounts[key] = (offerCounts[key] || 0) + 1;
      });
      const offers = Object.entries(offerCounts)
        .map(([title, count]) => ({ title, count }))
        .sort((a, b) => b.count - a.count)
        .slice(0, 5);
      setTopOffers(offers);

      // 10. Top referrers
      const refCounts = {};
      try {
        const refSnap = await getDocs(collection(db, "referrals"));
        refSnap.forEach((d) => {
          const data = d.data();
          const key = data.referrerUid || "Unknown";
          refCounts[key] = (refCounts[key] || 0) + 1;
        });
      } catch (e) {
        console.warn("referrals error:", e.message);
      }
      const referrers = Object.entries(refCounts)
        .map(([uid, count]) => ({ uid, count }))
        .sort((a, b) => b.count - a.count)
        .slice(0, 5);
      setTopReferrers(referrers);
    } catch (e) {
      console.error("Marketing dashboard error:", e);
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div style={{ padding: 40, textAlign: "center" }}>
        <div style={{ fontSize: 16, color: COLORS.gray }}>
          Loading marketing data...
        </div>
      </div>
    );
  }

  return (
    <div style={{ padding: 24, maxWidth: 1400, margin: "0 auto" }}>
      {/* Header */}
      <div style={{ marginBottom: 24 }}>
        <h1 style={{ fontSize: 28, fontWeight: 800, margin: 0 }}>
          📊 Marketing Dashboard
        </h1>
        <p style={{ color: COLORS.gray, margin: "4px 0 0 0" }}>
          Track campaigns, ROI, customer acquisition & conversions
        </p>
      </div>

      {/* Overview Stats */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
          gap: 16,
          marginBottom: 24,
        }}
      >
        <StatCard
          icon="💰"
          label="Total Revenue"
          value={`QAR ${stats.totalRevenue.toLocaleString()}`}
          color={COLORS.success}
        />
        <StatCard
          icon="💸"
          label="Total Spend"
          value={`QAR ${stats.totalSpend.toLocaleString()}`}
          color={COLORS.error}
        />
        <StatCard
          icon="📈"
          label="ROI"
          value={`${stats.roi.toFixed(1)}%`}
          color={stats.roi > 0 ? COLORS.success : COLORS.error}
        />
        <StatCard
          icon="👥"
          label="New Customers"
          value={stats.newCustomers}
          color={COLORS.primary}
        />
      </div>

      {/* Conversion Funnel */}
      <div style={cardStyle}>
        <h2 style={sectionTitleStyle}>🔄 Conversion Funnel</h2>
        <div style={{ marginTop: 16 }}>
          {funnelData.map((item, i) => {
            const maxValue = Math.max(...funnelData.map((f) => f.value), 1);
            const width = (item.value / maxValue) * 100;
            return (
              <div key={i} style={{ marginBottom: 12 }}>
                <div
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    marginBottom: 4,
                    fontSize: 13,
                    fontWeight: 600,
                  }}
                >
                  <span>{item.label}</span>
                  <span style={{ color: item.color }}>
                    {item.value.toLocaleString()}
                  </span>
                </div>
                <div
                  style={{
                    height: 24,
                    background: COLORS.lightGray,
                    borderRadius: 6,
                    overflow: "hidden",
                  }}
                >
                  <div
                    style={{
                      width: `${width}%`,
                      height: "100%",
                      background: item.color,
                      transition: "width 0.5s",
                    }}
                  />
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Channel Performance */}
      <div style={{ ...cardStyle, marginTop: 16 }}>
        <h2 style={sectionTitleStyle}>📡 Channel Performance</h2>
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(180px, 1fr))",
            gap: 12,
            marginTop: 16,
          }}
        >
          {channelData.map((ch) => (
            <div
              key={ch.id}
              style={{
                padding: 16,
                background: COLORS.lightGray,
                borderRadius: 10,
                borderLeft: `4px solid ${ch.color}`,
              }}
            >
              <div style={{ fontSize: 12, color: COLORS.gray, marginBottom: 4 }}>
                {ch.name}
              </div>
              <div
                style={{ fontSize: 22, fontWeight: 800, color: ch.color }}
              >
                {ch.customers}
              </div>
              <div style={{ fontSize: 12, color: COLORS.gray, marginTop: 4 }}>
                customers
              </div>
              <div style={{ fontSize: 13, fontWeight: 600, marginTop: 8 }}>
                QAR {ch.revenue.toLocaleString()}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* 2-column: Top Offers + Top Referrers */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(400px, 1fr))",
          gap: 16,
          marginTop: 16,
        }}
      >
        {/* Top Offers */}
        <div style={cardStyle}>
          <h2 style={sectionTitleStyle}>🏆 Top Performing Offers</h2>
          {topOffers.length === 0 ? (
            <p style={emptyStyle}>No claims data yet</p>
          ) : (
            <div style={{ marginTop: 12 }}>
              {topOffers.map((o, i) => (
                <div
                  key={i}
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    padding: "10px 0",
                    borderBottom: `1px solid ${COLORS.lightGray}`,
                  }}
                >
                  <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    <span
                      style={{
                        width: 24,
                        height: 24,
                        borderRadius: "50%",
                        background:
                          i === 0
                            ? "#FCD34D"
                            : i === 1
                            ? "#D1D5DB"
                            : i === 2
                            ? "#FDBA74"
                            : COLORS.lightGray,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        fontSize: 12,
                        fontWeight: 800,
                      }}
                    >
                      {i + 1}
                    </span>
                    <span style={{ fontSize: 14, fontWeight: 600 }}>
                      {o.title}
                    </span>
                  </div>
                  <span
                    style={{
                      fontSize: 14,
                      fontWeight: 700,
                      color: COLORS.primary,
                    }}
                  >
                    {o.count} claims
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Top Referrers */}
        <div style={cardStyle}>
          <h2 style={sectionTitleStyle}>🎯 Top Referrers</h2>
          {topReferrers.length === 0 ? (
            <p style={emptyStyle}>No referral data yet</p>
          ) : (
            <div style={{ marginTop: 12 }}>
              {topReferrers.map((r, i) => (
                <div
                  key={i}
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    padding: "10px 0",
                    borderBottom: `1px solid ${COLORS.lightGray}`,
                  }}
                >
                  <span
                    style={{
                      fontSize: 13,
                      fontFamily: "monospace",
                      color: COLORS.gray,
                    }}
                  >
                    {r.uid.substring(0, 12)}...
                  </span>
                  <span
                    style={{
                      fontSize: 14,
                      fontWeight: 700,
                      color: COLORS.success,
                    }}
                  >
                    {r.count} referrals
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Refresh */}
      <div style={{ marginTop: 24, textAlign: "center" }}>
        <button
          onClick={loadData}
          style={{
            padding: "12px 24px",
            background: COLORS.purple,
            color: "white",
            border: "none",
            borderRadius: 8,
            fontSize: 14,
            fontWeight: 700,
            cursor: "pointer",
          }}
        >
          🔄 Refresh Data
        </button>
      </div>
    </div>
  );
}

function StatCard({ icon, label, value, color }) {
  return (
    <div
      style={{
        background: "white",
        padding: 20,
        borderRadius: 12,
        boxShadow: "0 1px 3px rgba(0,0,0,0.08)",
        border: `1px solid ${COLORS.lightGray}`,
      }}
    >
      <div style={{ fontSize: 28, marginBottom: 8 }}>{icon}</div>
      <div style={{ fontSize: 12, color: COLORS.gray, marginBottom: 4 }}>
        {label}
      </div>
      <div style={{ fontSize: 24, fontWeight: 800, color }}>
        {value}
      </div>
    </div>
  );
}

const cardStyle = {
  background: "white",
  padding: 20,
  borderRadius: 12,
  boxShadow: "0 1px 3px rgba(0,0,0,0.08)",
  border: `1px solid ${COLORS.lightGray}`,
};

const sectionTitleStyle = {
  fontSize: 16,
  fontWeight: 800,
  margin: 0,
  color: "#111827",
};

const emptyStyle = {
  color: COLORS.gray,
  textAlign: "center",
  padding: 20,
  fontSize: 13,
};