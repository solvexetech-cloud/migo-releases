// ═══════════════════════════════════════════════════════
// MIGO Admin — Revenue Split Engine (D3)
// ═══════════════════════════════════════════════════════

import { useState, useEffect } from 'react';
import {
  doc, getDoc, setDoc, collection, getDocs, query, orderBy,
  limit, where, serverTimestamp,
} from 'firebase/firestore';
import { db } from '../firebase';

// ─────────────────────────────────────────────────────
// Default Split Config
// ─────────────────────────────────────────────────────
const DEFAULT_CONFIG = {
  migoShare: 50,
  agencyShare: 40,
  referralShare: 10,
  enabled: true,
  minPayoutAmount: 100,
  payoutCycle: 'monthly',
  holdDays: 7,
};

export default function RevenueSplitPage() {
  const [tab, setTab] = useState('config');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [config, setConfig] = useState(DEFAULT_CONFIG);
  const [splits, setSplits] = useState([]);
  const [stats, setStats] = useState({
    totalRevenue: 0,
    migoShare: 0,
    agencyShare: 0,
    referralShare: 0,
  });

  useEffect(() => {
    loadConfig();
    loadSplits();
  }, []);

  // ─────────────────────────────────────────────────
  // Load Config
  // ─────────────────────────────────────────────────
  async function loadConfig() {
    try {
      const snap = await getDoc(doc(db, 'config', 'revenue_split'));
      if (snap.exists()) {
        setConfig((prev) => ({ ...prev, ...snap.data() }));
      }
    } catch (e) {
      console.error('Config load error:', e);
    } finally {
      setLoading(false);
    }
  }

  // ─────────────────────────────────────────────────
  // Load Recent Splits
  // ─────────────────────────────────────────────────
  async function loadSplits() {
    try {
      const q = query(
        collection(db, 'revenue_splits'),
        orderBy('createdAt', 'desc'),
        limit(50)
      );
      const snap = await getDocs(q);
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      setSplits(list);

      // Calculate stats
      let total = 0, migo = 0, agency = 0, referral = 0;
      list.forEach((s) => {
        total += s.amount || 0;
        migo += s.migoShare || 0;
        agency += s.agencyShare || 0;
        referral += s.referralShare || 0;
      });
      setStats({
        totalRevenue: total,
        migoShare: migo,
        agencyShare: agency,
        referralShare: referral,
      });
    } catch (e) {
      console.error('Splits load error:', e);
    }
  }

  // ─────────────────────────────────────────────────
  // Save Config
  // ─────────────────────────────────────────────────
  async function saveConfig() {
    // Validation
    const sum = config.migoShare + config.agencyShare + config.referralShare;
    if (sum !== 100) {
      alert(`❌ Percentages must total 100%. Current: ${sum}%`);
      return;
    }

    setSaving(true);
    try {
      await setDoc(
        doc(db, 'config', 'revenue_split'),
        { ...config, updatedAt: serverTimestamp() },
        { merge: true }
      );
      alert('✅ Configuration saved!');
    } catch (e) {
      alert('❌ Error: ' + e.message);
    } finally {
      setSaving(false);
    }
  }

  // ─────────────────────────────────────────────────
  // Update field helper
  // ─────────────────────────────────────────────────
  function update(field, value) {
    setConfig({ ...config, [field]: value });
  }

  // ─────────────────────────────────────────────────
  // Render
  // ─────────────────────────────────────────────────
  if (loading) {
    return <div style={{ padding: 40, textAlign: 'center' }}>Loading...</div>;
  }

  const total = config.migoShare + config.agencyShare + config.referralShare;
  const isValid = total === 100;

  return (
    <div style={{ padding: 24, maxWidth: 1200 }}>
      {/* Header */}
      <div style={{ marginBottom: 24 }}>
        <h1 style={{ fontSize: 26, fontWeight: 'bold', marginBottom: 4 }}>
          💰 Revenue Split Engine
        </h1>
        <p style={{ color: '#6B7280', fontSize: 14 }}>
          Configure how subscription revenue is distributed among MIGO, Agency, and Referral.
        </p>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 24 }}>
        <TabButton
          label="⚙️ Configuration"
          active={tab === 'config'}
          onClick={() => setTab('config')}
        />
        <TabButton
          label="📊 Recent Splits"
          active={tab === 'splits'}
          onClick={() => setTab('splits')}
        />
        <TabButton
          label="📈 Analytics"
          active={tab === 'analytics'}
          onClick={() => setTab('analytics')}
        />
      </div>

      {/* ─────────────── TAB: CONFIG ─────────────── */}
      {tab === 'config' && (
        <>
          {/* Master Switch */}
          <Card>
            <ToggleRow
              title="🎯 Split Engine Enabled"
              subtitle="Turn off to disable all revenue splits"
              value={config.enabled}
              onChange={() => update('enabled', !config.enabled)}
              highlight
            />
          </Card>

          {/* Split Percentages */}
          <Card>
            <h2 style={{ fontSize: 16, fontWeight: 'bold', marginBottom: 16 }}>
              📊 Split Distribution
            </h2>

            <NumberField
              label="MIGO Platform Share"
              value={config.migoShare}
              onChange={(v) => update('migoShare', v)}
              suffix="%"
              color="#7C3AED"
              disabled={!config.enabled}
            />

            <NumberField
              label="Agency Share"
              value={config.agencyShare}
              onChange={(v) => update('agencyShare', v)}
              suffix="%"
              color="#10B981"
              disabled={!config.enabled}
            />

            <NumberField
              label="Referral Share"
              value={config.referralShare}
              onChange={(v) => update('referralShare', v)}
              suffix="%"
              color="#F59E0B"
              disabled={!config.enabled}
            />

            {/* Total Indicator */}
            <div
              style={{
                marginTop: 16,
                padding: 14,
                borderRadius: 10,
                background: isValid ? '#D1FAE5' : '#FEE2E2',
                border: `1px solid ${isValid ? '#10B981' : '#EF4444'}`,
              }}
            >
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  fontSize: 14,
                  fontWeight: 'bold',
                  color: isValid ? '#065F46' : '#991B1B',
                }}
              >
                <span>Total</span>
                <span>
                  {isValid ? '✅' : '❌'} {total}%
                </span>
              </div>
            </div>
          </Card>

          {/* Payout Settings */}
          <Card>
            <h2 style={{ fontSize: 16, fontWeight: 'bold', marginBottom: 16 }}>
              💳 Payout Settings
            </h2>

            <NumberField
              label="Minimum Payout Amount (QAR)"
              value={config.minPayoutAmount}
              onChange={(v) => update('minPayoutAmount', v)}
              suffix="QAR"
              disabled={!config.enabled}
            />

            <SelectField
              label="Payout Cycle"
              value={config.payoutCycle}
              onChange={(v) => update('payoutCycle', v)}
              options={[
                { value: 'weekly', label: 'Weekly' },
                { value: 'biweekly', label: 'Bi-weekly' },
                { value: 'monthly', label: 'Monthly' },
              ]}
              disabled={!config.enabled}
            />

            <NumberField
              label="Verification Hold (days)"
              value={config.holdDays}
              onChange={(v) => update('holdDays', v)}
              suffix="days"
              disabled={!config.enabled}
            />
          </Card>

          {/* Save Button */}
          <button
            onClick={saveConfig}
            disabled={saving || !isValid}
            style={{
              padding: '14px 32px',
              background: saving || !isValid ? '#9CA3AF' : '#7C3AED',
              color: 'white',
              border: 'none',
              borderRadius: 8,
              fontSize: 15,
              fontWeight: 'bold',
              cursor: saving || !isValid ? 'not-allowed' : 'pointer',
            }}
          >
            {saving ? 'Saving...' : '💾 Save Configuration'}
          </button>
        </>
      )}

      {/* ─────────────── TAB: SPLITS ─────────────── */}
      {tab === 'splits' && (
        <Card>
          <h2 style={{ fontSize: 16, fontWeight: 'bold', marginBottom: 16 }}>
            📊 Recent Revenue Splits (last 50)
          </h2>

          {splits.length === 0 ? (
            <EmptyState text="No revenue splits yet. They'll appear here once subscriptions start." />
          ) : (
            <div style={{ overflowX: 'auto' }}>
              <table style={tableStyle}>
                <thead>
                  <tr style={theadRow}>
                    <th style={thStyle}>Date</th>
                    <th style={thStyle}>Business</th>
                    <th style={thStyle}>Amount</th>
                    <th style={thStyle}>MIGO</th>
                    <th style={thStyle}>Agency</th>
                    <th style={thStyle}>Referral</th>
                    <th style={thStyle}>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {splits.map((s) => (
                    <tr key={s.id} style={tbodyRow}>
                      <td style={tdStyle}>
                        {s.createdAt?.toDate
                          ? s.createdAt.toDate().toLocaleDateString()
                          : '—'}
                      </td>
                      <td style={tdStyle}>
                        {s.businessName || s.businessId || '—'}
                      </td>
                      <td style={tdStyle}>
                        <strong>QAR {(s.amount || 0).toFixed(2)}</strong>
                      </td>
                      <td style={tdStyle}>QAR {(s.migoShare || 0).toFixed(2)}</td>
                      <td style={tdStyle}>QAR {(s.agencyShare || 0).toFixed(2)}</td>
                      <td style={tdStyle}>
                        QAR {(s.referralShare || 0).toFixed(2)}
                      </td>
                      <td style={tdStyle}>
                        <StatusBadge status={s.status || 'pending'} />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      )}

      {/* ─────────────── TAB: ANALYTICS ─────────────── */}
      {tab === 'analytics' && (
        <>
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
              gap: 16,
              marginBottom: 24,
            }}
          >
            <StatCard
              title="Total Revenue"
              value={`QAR ${stats.totalRevenue.toFixed(2)}`}
              icon="💰"
              color="#7C3AED"
            />
            <StatCard
              title="MIGO Share"
              value={`QAR ${stats.migoShare.toFixed(2)}`}
              icon="🏢"
              color="#3B82F6"
            />
            <StatCard
              title="Agency Share"
              value={`QAR ${stats.agencyShare.toFixed(2)}`}
              icon="🤝"
              color="#10B981"
            />
            <StatCard
              title="Referral Share"
              value={`QAR ${stats.referralShare.toFixed(2)}`}
              icon="🎁"
              color="#F59E0B"
            />
          </div>

          <Card>
            <h2 style={{ fontSize: 16, fontWeight: 'bold', marginBottom: 12 }}>
              📊 Split Distribution
            </h2>
            <p style={{ color: '#6B7280', fontSize: 13 }}>
              Current configuration: MIGO {config.migoShare}% • Agency{' '}
              {config.agencyShare}% • Referral {config.referralShare}%
            </p>
            <p style={{ color: '#6B7280', fontSize: 13, marginTop: 8 }}>
              ℹ️ Chart visualization will appear once data is available.
            </p>
          </Card>
        </>
      )}
    </div>
  );
}

// ═══════════════════════════════════════════════════════
// Sub-components
// ═══════════════════════════════════════════════════════

function TabButton({ label, active, onClick }) {
  return (
    <button
      onClick={onClick}
      style={{
        padding: '10px 20px',
        borderRadius: 10,
        border: active ? 'none' : '1px solid #E5E7EB',
        background: active ? '#7C3AED' : 'white',
        color: active ? 'white' : '#374151',
        fontSize: 14,
        fontWeight: 600,
        cursor: 'pointer',
        transition: 'all 0.15s',
      }}
    >
      {label}
    </button>
  );
}

function Card({ children }) {
  return (
    <div
      style={{
        background: 'white',
        borderRadius: 12,
        padding: 20,
        marginBottom: 16,
        boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
      }}
    >
      {children}
    </div>
  );
}

function NumberField({ label, value, onChange, suffix, color, disabled }) {
  return (
    <div
      style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '14px 0',
        borderBottom: '1px solid #F3F4F6',
        opacity: disabled ? 0.5 : 1,
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        {color && (
          <div
            style={{
              width: 12,
              height: 12,
              borderRadius: 3,
              background: color,
            }}
          />
        )}
        <span style={{ fontSize: 15, fontWeight: 600 }}>{label}</span>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <input
          type="number"
          value={value}
          onChange={(e) => onChange(Number(e.target.value) || 0)}
          disabled={disabled}
          style={{
            width: 100,
            padding: '8px 12px',
            borderRadius: 8,
            border: '1px solid #D1D5DB',
            fontSize: 15,
            fontWeight: 'bold',
            textAlign: 'right',
            background: disabled ? '#F9FAFB' : 'white',
          }}
        />
        <span style={{ fontSize: 14, color: '#6B7280', minWidth: 40 }}>
          {suffix}
        </span>
      </div>
    </div>
  );
}

function SelectField({ label, value, onChange, options, disabled }) {
  return (
    <div
      style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '14px 0',
        borderBottom: '1px solid #F3F4F6',
        opacity: disabled ? 0.5 : 1,
      }}
    >
      <span style={{ fontSize: 15, fontWeight: 600 }}>{label}</span>
      <select
        value={value}
        onChange={(e) => onChange(e.target.value)}
        disabled={disabled}
        style={{
          padding: '8px 12px',
          borderRadius: 8,
          border: '1px solid #D1D5DB',
          fontSize: 14,
          background: disabled ? '#F9FAFB' : 'white',
          cursor: disabled ? 'not-allowed' : 'pointer',
        }}
      >
        {options.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </select>
    </div>
  );
}

function ToggleRow({ title, subtitle, value, onChange, disabled, highlight }) {
  return (
    <div
      style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '14px 0',
        opacity: disabled ? 0.5 : 1,
      }}
    >
      <div>
        <div style={{ fontWeight: highlight ? 'bold' : '600', fontSize: 15 }}>
          {title}
        </div>
        {subtitle && (
          <div style={{ fontSize: 13, color: '#6B7280', marginTop: 2 }}>
            {subtitle}
          </div>
        )}
      </div>
      <button
        onClick={onChange}
        disabled={disabled}
        style={{
          width: 52,
          height: 28,
          borderRadius: 14,
          border: 'none',
          background: value ? '#10B981' : '#D1D5DB',
          position: 'relative',
          cursor: disabled ? 'not-allowed' : 'pointer',
        }}
      >
        <div
          style={{
            width: 22,
            height: 22,
            borderRadius: '50%',
            background: 'white',
            position: 'absolute',
            top: 3,
            left: value ? 27 : 3,
            transition: 'left 0.2s',
            boxShadow: '0 2px 4px rgba(0,0,0,0.2)',
          }}
        />
      </button>
    </div>
  );
}

function StatCard({ title, value, icon, color }) {
  return (
    <div
      style={{
        background: 'white',
        borderRadius: 12,
        padding: 20,
        boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
        borderLeft: `4px solid ${color}`,
      }}
    >
      <div style={{ fontSize: 28, marginBottom: 8 }}>{icon}</div>
      <div style={{ fontSize: 13, color: '#6B7280', marginBottom: 4 }}>
        {title}
      </div>
      <div style={{ fontSize: 22, fontWeight: 'bold', color }}>{value}</div>
    </div>
  );
}

function StatusBadge({ status }) {
  const colors = {
    pending: { bg: '#FEF3C7', fg: '#92400E' },
    confirmed: { bg: '#DBEAFE', fg: '#1E40AF' },
    paid: { bg: '#D1FAE5', fg: '#065F46' },
    failed: { bg: '#FEE2E2', fg: '#991B1B' },
  };
  const c = colors[status] || colors.pending;
  return (
    <span
      style={{
        padding: '4px 10px',
        borderRadius: 6,
        fontSize: 12,
        fontWeight: 'bold',
        background: c.bg,
        color: c.fg,
        textTransform: 'capitalize',
      }}
    >
      {status}
    </span>
  );
}

function EmptyState({ text }) {
  return (
    <div
      style={{
        padding: 40,
        textAlign: 'center',
        color: '#9CA3AF',
        fontSize: 14,
      }}
    >
      {text}
    </div>
  );
}

// ═══════════════════════════════════════════════════════
// Styles
// ═══════════════════════════════════════════════════════

const tableStyle = {
  width: '100%',
  borderCollapse: 'collapse',
  fontSize: 14,
};

const theadRow = {
  borderBottom: '2px solid #E5E7EB',
};

const thStyle = {
  padding: '10px 12px',
  textAlign: 'left',
  fontWeight: 'bold',
  color: '#6B7280',
  fontSize: 12,
  textTransform: 'uppercase',
};

const tbodyRow = {
  borderBottom: '1px solid #F3F4F6',
};

const tdStyle = {
  padding: '12px',
  color: '#374151',
};