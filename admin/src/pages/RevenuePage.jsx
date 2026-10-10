import { useEffect, useMemo, useState } from 'react';
import {
  addDoc,
  collection,
  doc,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  updateDoc,
  where,
} from 'firebase/firestore';
import { db } from '../firebase';
import { useIsMobile } from '../hooks/useIsMobile';

const TABS = [
  { key: 'overview', label: 'Overview' },
  { key: 'subscriptions', label: 'Subscriptions' },
  { key: 'payments', label: 'Payments' },
];

const PAYMENT_METHODS = [
  { value: 'cash', label: 'Cash' },
  { value: 'bank_transfer', label: 'Bank Transfer' },
  { value: 'qpay', label: 'QPay' },
  { value: 'stripe', label: 'Stripe' },
];

const PAYMENT_TYPES = [
  { value: 'subscription', label: 'Subscription' },
  { value: 'per_offer', label: 'Per-Offer Fee' },
  { value: 'commission', label: 'Success Commission' },
];

export default function RevenuePage() {
  const [tab, setTab] = useState('overview');
  const isMobile = useIsMobile();

  return (
    <div style={{ padding: isMobile ? 16 : 32, maxWidth: 1300 }}>
      <header style={{ marginBottom: 20 }}>
        <h1
          style={{
            fontSize: 28,
            fontWeight: 900,
            color: '#0B2B5B',
            letterSpacing: -0.5,
            marginBottom: 4,
          }}
        >
          Revenue
        </h1>
        <p style={{ fontSize: 14, color: '#6B7280' }}>
          Track earnings, subscriptions, and payments.
        </p>
      </header>

      {/* Tabs */}
      <div
        style={{
          display: 'flex',
          gap: 6,
          marginBottom: 20,
          borderBottom: '1px solid #E5E7EB',
          paddingBottom: 0,
        }}
      >
        {TABS.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            style={{
              padding: '10px 18px',
              border: 'none',
              background: 'transparent',
              color: tab === t.key ? '#0B2B5B' : '#6B7280',
              fontSize: 14,
              fontWeight: 800,
              cursor: 'pointer',
              borderBottom:
                tab === t.key
                  ? '3px solid #D4A13A'
                  : '3px solid transparent',
              marginBottom: -1,
            }}
          >
            {t.label}
          </button>
        ))}
      </div>

      {tab === 'overview' && <OverviewTab isMobile={isMobile} />}
      {tab === 'subscriptions' && <SubscriptionsTab isMobile={isMobile} />}
      {tab === 'payments' && <PaymentsTab isMobile={isMobile} />}
    </div>
  );
}

// ---------- Tab 1: Overview ----------
function OverviewTab({ isMobile }) {
  const [payments, setPayments] = useState([]);
  const [businesses, setBusinesses] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsub = onSnapshot(
      query(collection(db, 'payments'), orderBy('paidAt', 'desc')),
      (snap) => {
        setPayments(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
        setLoading(false);
      },
      () => setLoading(false),
    );
    return () => unsub();
  }, []);

  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'businesses'), (snap) => {
      setBusinesses(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
    });
    return () => unsub();
  }, []);

  const stats = useMemo(() => {
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const lastMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1);

    const completed = payments.filter((p) => p.status === 'completed');
    const totals = { all: {}, thisMonth: {}, lastMonth: {} };

    function addTo(bucket, p) {
      const cur = p.currency || 'QAR';
      bucket[cur] = (bucket[cur] || 0) + Number(p.amount || 0);
    }

    completed.forEach((p) => {
      const paidAt = p.paidAt?.toDate?.() || null;
      addTo(totals.all, p);
      if (paidAt && paidAt >= monthStart) addTo(totals.thisMonth, p);
      if (paidAt && paidAt >= lastMonthStart && paidAt < monthStart)
        addTo(totals.lastMonth, p);
    });

    return totals;
  }, [payments]);

  const topBusinesses = useMemo(() => {
    const map = {};
    payments
      .filter((p) => p.status === 'completed')
      .forEach((p) => {
        const key = p.businessId;
        if (!key) return;
        if (!map[key]) {
          map[key] = {
            id: key,
            name: p.businessName || 'Unknown',
            amount: 0,
            currency: p.currency || 'QAR',
            count: 0,
          };
        }
        map[key].amount += Number(p.amount || 0);
        map[key].count += 1;
      });
    return Object.values(map)
      .sort((a, b) => b.amount - a.amount)
      .slice(0, 5);
  }, [payments]);

  if (loading) {
    return <div style={{ color: '#6B7280' }}>Loading…</div>;
  }

  return (
    <div>
      {/* Stat cards */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: isMobile
            ? '1fr 1fr'
            : 'repeat(auto-fit, minmax(220px, 1fr))',
          gap: 14,
          marginBottom: 24,
        }}
      >
        <StatCard
          label="ALL TIME"
          values={stats.all}
          color="#0B2B5B"
          bg="#EFF6FF"
        />
        <StatCard
          label="THIS MONTH"
          values={stats.thisMonth}
          color="#2E9E5B"
          bg="#E5F5EA"
        />
        <StatCard
          label="LAST MONTH"
          values={stats.lastMonth}
          color="#A67920"
          bg="#FFF3D6"
        />
        <StatCard
          label="PAYMENTS COUNT"
          count={payments.length}
          color="#1E4B8F"
          bg="#F6F3EE"
        />
      </div>

      {/* Top businesses */}
      <Section title="Top Businesses by Revenue">
        {topBusinesses.length === 0 ? (
          <Empty text="No revenue yet." />
        ) : (
          <div>
            {topBusinesses.map((b, i) => (
              <div
                key={b.id}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 12,
                  padding: '12px 0',
                  borderBottom:
                    i < topBusinesses.length - 1
                      ? '1px solid #F1EEEA'
                      : 'none',
                }}
              >
                <div
                  style={{
                    width: 28,
                    height: 28,
                    borderRadius: 8,
                    background: '#EFF6FF',
                    color: '#1E4B8F',
                    fontSize: 13,
                    fontWeight: 900,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  {i + 1}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div
                    style={{
                      fontSize: 14,
                      fontWeight: 800,
                      color: '#0B2B5B',
                    }}
                  >
                    {b.name}
                  </div>
                  <div style={{ fontSize: 11, color: '#9CA3AF' }}>
                    {b.count} payment{b.count !== 1 ? 's' : ''}
                  </div>
                </div>
                <div
                  style={{
                    fontSize: 15,
                    fontWeight: 900,
                    color: '#2E9E5B',
                  }}
                >
                  {b.amount.toLocaleString()} {b.currency}
                </div>
              </div>
            ))}
          </div>
        )}
      </Section>

      {/* Recent payments */}
      <Section title="Recent Payments">
        {payments.length === 0 ? (
          <Empty text="No payments recorded yet. Go to Payments tab to add one." />
        ) : (
          <div>
            {payments.slice(0, 10).map((p, i) => (
              <div
                key={p.id}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  gap: 12,
                  padding: '12px 0',
                  borderBottom:
                    i < Math.min(payments.length, 10) - 1
                      ? '1px solid #F1EEEA'
                      : 'none',
                  flexWrap: 'wrap',
                }}
              >
                <div style={{ flex: 1, minWidth: 200 }}>
                  <div
                    style={{
                      fontSize: 14,
                      fontWeight: 800,
                      color: '#0B2B5B',
                    }}
                  >
                    {p.businessName || '—'}
                  </div>
                  <div style={{ fontSize: 11, color: '#9CA3AF' }}>
                    {p.type} · {p.method} ·{' '}
                    {p.paidAt?.toDate?.().toLocaleDateString() || '—'}
                  </div>
                </div>
                <div
                  style={{
                    fontSize: 15,
                    fontWeight: 900,
                    color: p.status === 'completed' ? '#2E9E5B' : '#A67920',
                  }}
                >
                  {Number(p.amount || 0).toLocaleString()} {p.currency}
                </div>
              </div>
            ))}
          </div>
        )}
      </Section>
    </div>
  );
}

// ---------- Tab 2: Subscriptions ----------
function SubscriptionsTab({ isMobile }) {
  const [subs, setSubs] = useState([]);
  const [plans, setPlans] = useState([]);
  const [businesses, setBusinesses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAssign, setShowAssign] = useState(false);

  useEffect(() => {
    const unsub = onSnapshot(
      query(collection(db, 'subscriptions'), orderBy('createdAt', 'desc')),
      (snap) => {
        setSubs(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
        setLoading(false);
      },
      () => setLoading(false),
    );
    return () => unsub();
  }, []);

  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'plans'), (snap) => {
      setPlans(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
    });
    return () => unsub();
  }, []);

  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'businesses'), (snap) => {
      setBusinesses(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
    });
    return () => unsub();
  }, []);

  async function handleCancel(sub) {
    if (!confirm(`Cancel subscription for "${sub.businessName || sub.businessId}"?`)) return;
    try {
      await updateDoc(doc(db, 'subscriptions', sub.id), {
        status: 'cancelled',
        updatedAt: serverTimestamp(),
      });
    } catch (e) {
      alert('Failed: ' + e.message);
    }
  }

  return (
    <div>
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: 16,
          flexWrap: 'wrap',
          gap: 12,
        }}
      >
        <div style={{ fontSize: 14, color: '#6B7280' }}>
          {subs.length} subscription{subs.length !== 1 ? 's' : ''}
        </div>
        <button
          onClick={() => setShowAssign(true)}
          style={goldBtn}
        >
          + Assign Plan
        </button>
      </div>

      {loading ? (
        <div style={{ color: '#6B7280' }}>Loading…</div>
      ) : subs.length === 0 ? (
        <Empty text="No subscriptions yet. Click 'Assign Plan' to add one." />
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {subs.map((s) => (
            <SubCard
              key={s.id}
              sub={s}
              plans={plans}
              isMobile={isMobile}
              onCancel={() => handleCancel(s)}
            />
          ))}
        </div>
      )}

      {showAssign && (
        <AssignPlanModal
          plans={plans}
          businesses={businesses}
          onClose={() => setShowAssign(false)}
        />
      )}
    </div>
  );
}

function SubCard({ sub, plans, isMobile, onCancel }) {
  const plan = plans.find((p) => p.id === sub.planId);
  const expires = sub.expiresAt?.toDate?.();
  const daysLeft = expires
    ? Math.ceil((expires - new Date()) / (1000 * 60 * 60 * 24))
    : null;
  const statusColor = {
    active: { bg: '#E5F5EA', fg: '#2E9E5B' },
    expired: { bg: '#FEE2E2', fg: '#D64545' },
    cancelled: { bg: '#F1EEEA', fg: '#6B7280' },
    trial: { bg: '#FFF3D6', fg: '#A67920' },
  }[sub.status] || { bg: '#F1EEEA', fg: '#6B7280' };

  return (
    <div
      style={{
        background: 'white',
        borderRadius: 14,
        padding: 18,
        boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
        display: 'flex',
        justifyContent: 'space-between',
        flexWrap: 'wrap',
        gap: 12,
      }}
    >
      <div style={{ flex: 1, minWidth: 200 }}>
        <div
          style={{
            fontSize: 16,
            fontWeight: 900,
            color: '#0B2B5B',
            marginBottom: 6,
          }}
        >
          {sub.businessName || sub.businessId}
        </div>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          {plan && (
            <Tag bg="#EFF6FF" fg="#1E4B8F">
              {plan.name}
            </Tag>
          )}
          <Tag bg={statusColor.bg} fg={statusColor.fg}>
            {(sub.status || '').toUpperCase()}
          </Tag>
          {daysLeft !== null && (
            <Tag
              bg={daysLeft < 7 ? '#FEE2E2' : '#F6F3EE'}
              fg={daysLeft < 7 ? '#D64545' : '#6B7280'}
            >
              {daysLeft > 0 ? `${daysLeft} days left` : 'Expired'}
            </Tag>
          )}
        </div>
        {expires && (
          <div style={{ fontSize: 11, color: '#9CA3AF', marginTop: 8 }}>
            Expires: {expires.toLocaleDateString()}
          </div>
        )}
      </div>

      {sub.status === 'active' && (
        <button
          onClick={onCancel}
          style={{
            padding: '8px 14px',
            borderRadius: 8,
            border: '1px solid #D64545',
            background: 'white',
            color: '#D64545',
            fontSize: 12,
            fontWeight: 800,
            cursor: 'pointer',
            alignSelf: 'flex-start',
          }}
        >
          Cancel
        </button>
      )}
    </div>
  );
}

function AssignPlanModal({ plans, businesses, onClose }) {
  const [form, setForm] = useState({
    businessId: '',
    planId: 'starter',
    months: 1,
  });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  async function handleSave() {
    if (!form.businessId || !form.planId) {
      setError('Select business and plan');
      return;
    }
    setSaving(true);
    setError('');
    try {
      const biz = businesses.find((b) => b.id === form.businessId);
      const plan = plans.find((p) => p.id === form.planId);
      const now = new Date();
      const expiresAt = new Date(now);
      expiresAt.setMonth(expiresAt.getMonth() + Number(form.months || 1));

      await addDoc(collection(db, 'subscriptions'), {
        businessId: form.businessId,
        businessName: biz?.name || '',
        ownerUid: biz?.ownerUid || '',
        planId: form.planId,
        planName: plan?.name || '',
        status: 'active',
        startedAt: serverTimestamp(),
        expiresAt,
        autoRenew: true,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      });
      onClose();
    } catch (e) {
      setError(e.message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <Modal title="Assign Plan" onClose={onClose} saving={saving}>
      <Field label="Business *">
        <select
          style={inputStyle}
          value={form.businessId}
          onChange={(e) => setForm({ ...form, businessId: e.target.value })}
        >
          <option value="">— Select —</option>
          {businesses.map((b) => (
            <option key={b.id} value={b.id}>
              {b.name}
            </option>
          ))}
        </select>
      </Field>

      <Field label="Plan *">
        <select
          style={inputStyle}
          value={form.planId}
          onChange={(e) => setForm({ ...form, planId: e.target.value })}
        >
          {plans.map((p) => (
            <option key={p.id} value={p.id}>
              {p.name} — {p.priceMonthly} {p.currency}/mo
            </option>
          ))}
        </select>
      </Field>

      <Field label="Duration (months)">
        <input
          type="number"
          min={1}
          style={inputStyle}
          value={form.months}
          onChange={(e) => setForm({ ...form, months: e.target.value })}
        />
      </Field>

      {error && <ErrorBox text={error} />}

      <ModalButtons
        onCancel={onClose}
        onSave={handleSave}
        saving={saving}
        saveText="Assign"
      />
    </Modal>
  );
}

// ---------- Tab 3: Payments ----------
function PaymentsTab({ isMobile }) {
  const [payments, setPayments] = useState([]);
  const [businesses, setBusinesses] = useState([]);
  const [plans, setPlans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    const unsub = onSnapshot(
      query(collection(db, 'payments'), orderBy('paidAt', 'desc')),
      (snap) => {
        setPayments(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
        setLoading(false);
      },
      () => setLoading(false),
    );
    return () => unsub();
  }, []);

  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'businesses'), (snap) => {
      setBusinesses(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
    });
    return () => unsub();
  }, []);

  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'plans'), (snap) => {
      setPlans(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
    });
    return () => unsub();
  }, []);

  const filtered = useMemo(() => {
    if (filter === 'all') return payments;
    return payments.filter((p) => p.type === filter);
  }, [payments, filter]);

  return (
    <div>
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: 16,
          flexWrap: 'wrap',
          gap: 12,
        }}
      >
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          {['all', 'subscription', 'per_offer', 'commission'].map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              style={{
                padding: '8px 14px',
                borderRadius: 8,
                border: 'none',
                background: filter === f ? '#0B2B5B' : 'white',
                color: filter === f ? 'white' : '#374151',
                fontSize: 12,
                fontWeight: 800,
                cursor: 'pointer',
                boxShadow: '0 2px 6px rgba(0,0,0,0.05)',
                textTransform: 'capitalize',
              }}
            >
              {f.replace('_', ' ')}
            </button>
          ))}
        </div>
        <button onClick={() => setShowModal(true)} style={goldBtn}>
          + Record Payment
        </button>
      </div>

      {loading ? (
        <div style={{ color: '#6B7280' }}>Loading…</div>
      ) : filtered.length === 0 ? (
        <Empty text="No payments found." />
      ) : (
        <div
          style={{
            background: 'white',
            borderRadius: 14,
            overflow: 'hidden',
            boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
          }}
        >
          {filtered.map((p, i) => (
            <div
              key={p.id}
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                gap: 12,
                padding: isMobile ? 14 : '14px 20px',
                borderBottom:
                  i < filtered.length - 1 ? '1px solid #F1EEEA' : 'none',
                flexWrap: 'wrap',
              }}
            >
              <div style={{ flex: 1, minWidth: 180 }}>
                <div
                  style={{
                    fontSize: 14,
                    fontWeight: 800,
                    color: '#0B2B5B',
                  }}
                >
                  {p.businessName || '—'}
                </div>
                <div style={{ fontSize: 11, color: '#9CA3AF', marginTop: 2 }}>
                  {p.type} · {p.method} ·{' '}
                  {p.paidAt?.toDate?.().toLocaleDateString() || '—'}
                </div>
              </div>
              <Tag
                bg={
                  p.status === 'completed'
                    ? '#E5F5EA'
                    : p.status === 'pending'
                      ? '#FFF3D6'
                      : '#FEE2E2'
                }
                fg={
                  p.status === 'completed'
                    ? '#2E9E5B'
                    : p.status === 'pending'
                      ? '#A67920'
                      : '#D64545'
                }
              >
                {(p.status || '').toUpperCase()}
              </Tag>
              <div
                style={{
                  fontSize: 15,
                  fontWeight: 900,
                  color: '#0B2B5B',
                  minWidth: 100,
                  textAlign: 'right',
                }}
              >
                {Number(p.amount || 0).toLocaleString()} {p.currency}
              </div>
            </div>
          ))}
        </div>
      )}

      {showModal && (
        <RecordPaymentModal
          businesses={businesses}
          plans={plans}
          onClose={() => setShowModal(false)}
        />
      )}
    </div>
  );
}

function RecordPaymentModal({ businesses, plans, onClose }) {
  const [form, setForm] = useState({
    businessId: '',
    type: 'subscription',
    planId: '',
    amount: '',
    currency: 'QAR',
    method: 'cash',
    status: 'completed',
    notes: '',
  });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (form.type === 'subscription' && form.planId) {
      const plan = plans.find((p) => p.id === form.planId);
      if (plan) {
        setForm((f) => ({
          ...f,
          amount: String(plan.priceMonthly || ''),
          currency: plan.currency || 'QAR',
        }));
      }
    }
  }, [form.planId, form.type, plans]);

  async function handleSave() {
    if (!form.businessId || !form.amount) {
      setError('Business and amount are required');
      return;
    }
    setSaving(true);
    setError('');
    try {
      const biz = businesses.find((b) => b.id === form.businessId);
      await addDoc(collection(db, 'payments'), {
        businessId: form.businessId,
        businessName: biz?.name || '',
        ownerUid: biz?.ownerUid || '',
        type: form.type,
        planId: form.planId || null,
        amount: Number(form.amount),
        currency: form.currency,
        method: form.method,
        status: form.status,
        paidAt: serverTimestamp(),
        notes: form.notes,
        createdAt: serverTimestamp(),
      });
      onClose();
    } catch (e) {
      setError(e.message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <Modal title="Record Payment" onClose={onClose} saving={saving}>
      <Field label="Business *">
        <select
          style={inputStyle}
          value={form.businessId}
          onChange={(e) => setForm({ ...form, businessId: e.target.value })}
        >
          <option value="">— Select —</option>
          {businesses.map((b) => (
            <option key={b.id} value={b.id}>
              {b.name}
            </option>
          ))}
        </select>
      </Field>

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: '1fr 1fr',
          gap: 12,
        }}
      >
        <Field label="Type">
          <select
            style={inputStyle}
            value={form.type}
            onChange={(e) => setForm({ ...form, type: e.target.value })}
          >
            {PAYMENT_TYPES.map((t) => (
              <option key={t.value} value={t.value}>
                {t.label}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Method">
          <select
            style={inputStyle}
            value={form.method}
            onChange={(e) => setForm({ ...form, method: e.target.value })}
          >
            {PAYMENT_METHODS.map((m) => (
              <option key={m.value} value={m.value}>
                {m.label}
              </option>
            ))}
          </select>
        </Field>
      </div>

      {form.type === 'subscription' && (
        <Field label="Plan (optional)">
          <select
            style={inputStyle}
            value={form.planId}
            onChange={(e) => setForm({ ...form, planId: e.target.value })}
          >
            <option value="">— None —</option>
            {plans.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name} — {p.priceMonthly} {p.currency}/mo
              </option>
            ))}
          </select>
        </Field>
      )}

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: '2fr 1fr',
          gap: 12,
        }}
      >
        <Field label="Amount *">
          <input
            type="number"
            style={inputStyle}
            value={form.amount}
            onChange={(e) => setForm({ ...form, amount: e.target.value })}
            placeholder="0.00"
          />
        </Field>
        <Field label="Currency">
          <select
            style={inputStyle}
            value={form.currency}
            onChange={(e) => setForm({ ...form, currency: e.target.value })}
          >
            <option value="QAR">QAR</option>
            <option value="INR">INR</option>
          </select>
        </Field>
      </div>

      <Field label="Status">
        <select
          style={inputStyle}
          value={form.status}
          onChange={(e) => setForm({ ...form, status: e.target.value })}
        >
          <option value="completed">Completed</option>
          <option value="pending">Pending</option>
          <option value="failed">Failed</option>
          <option value="refunded">Refunded</option>
        </select>
      </Field>

      <Field label="Notes (optional)">
        <textarea
          style={{ ...inputStyle, minHeight: 60 }}
          value={form.notes}
          onChange={(e) => setForm({ ...form, notes: e.target.value })}
        />
      </Field>

      {error && <ErrorBox text={error} />}

      <ModalButtons
        onCancel={onClose}
        onSave={handleSave}
        saving={saving}
        saveText="Record"
      />
    </Modal>
  );
}

// ---------- Shared components ----------
function StatCard({ label, values, count, color, bg }) {
  return (
    <div
      style={{
        background: 'white',
        borderRadius: 14,
        padding: 18,
        boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
      }}
    >
      <div
        style={{
          display: 'inline-block',
          padding: '3px 9px',
          borderRadius: 6,
          background: bg,
          color,
          fontSize: 10,
          fontWeight: 900,
          letterSpacing: 0.5,
          marginBottom: 10,
        }}
      >
        {label}
      </div>
      {count !== undefined ? (
        <div style={{ fontSize: 24, fontWeight: 900, color: '#0B2B5B' }}>
          {count}
        </div>
      ) : Object.keys(values || {}).length === 0 ? (
        <div style={{ fontSize: 20, fontWeight: 900, color: '#9CA3AF' }}>
          0
        </div>
      ) : (
        Object.entries(values).map(([cur, amt]) => (
          <div
            key={cur}
            style={{
              fontSize: 20,
              fontWeight: 900,
              color: '#0B2B5B',
              marginBottom: 2,
            }}
          >
            {amt.toLocaleString()}{' '}
            <span style={{ fontSize: 12, color: '#6B7280' }}>{cur}</span>
          </div>
        ))
      )}
    </div>
  );
}

function Section({ title, children }) {
  return (
    <div
      style={{
        background: 'white',
        borderRadius: 14,
        padding: 20,
        boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
        marginBottom: 16,
      }}
    >
      <div
        style={{
          fontSize: 14,
          fontWeight: 900,
          color: '#0B2B5B',
          marginBottom: 14,
          letterSpacing: 0.3,
        }}
      >
        {title}
      </div>
      {children}
    </div>
  );
}

function Empty({ text }) {
  return (
    <div
      style={{
        padding: 24,
        textAlign: 'center',
        color: '#9CA3AF',
        fontSize: 13,
      }}
    >
      {text}
    </div>
  );
}

function Tag({ children, bg, fg }) {
  return (
    <span
      style={{
        display: 'inline-block',
        padding: '3px 10px',
        borderRadius: 6,
        background: bg,
        color: fg,
        fontSize: 10,
        fontWeight: 800,
        letterSpacing: 0.5,
      }}
    >
      {children}
    </span>
  );
}

function Modal({ title, children, onClose, saving }) {
  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        background: 'rgba(0,0,0,0.5)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 1000,
        padding: 20,
      }}
      onClick={() => !saving && onClose()}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          background: 'white',
          borderRadius: 16,
          padding: 28,
          maxWidth: 520,
          width: '100%',
          maxHeight: '90vh',
          overflowY: 'auto',
        }}
      >
        <h2
          style={{
            fontSize: 20,
            fontWeight: 900,
            color: '#0B2B5B',
            marginBottom: 20,
          }}
        >
          {title}
        </h2>
        {children}
      </div>
    </div>
  );
}

function ModalButtons({ onCancel, onSave, saving, saveText }) {
  return (
    <div
      style={{
        display: 'flex',
        gap: 10,
        justifyContent: 'flex-end',
        marginTop: 8,
      }}
    >
      <button
        onClick={onCancel}
        disabled={saving}
        style={{
          padding: '10px 20px',
          borderRadius: 8,
          border: '1px solid #E5E7EB',
          background: 'white',
          fontSize: 14,
          fontWeight: 700,
          cursor: 'pointer',
          color: '#6B7280',
        }}
      >
        Cancel
      </button>
      <button
        onClick={onSave}
        disabled={saving}
        style={{
          padding: '10px 24px',
          borderRadius: 8,
          border: 'none',
          background:
            'linear-gradient(135deg, #F0C566 0%, #D4A13A 100%)',
          color: '#0B2B5B',
          fontSize: 14,
          fontWeight: 800,
          cursor: saving ? 'not-allowed' : 'pointer',
          opacity: saving ? 0.6 : 1,
        }}
      >
        {saving ? 'Saving…' : saveText}
      </button>
    </div>
  );
}

function Field({ label, children }) {
  return (
    <div style={{ marginBottom: 14 }}>
      <label
        style={{
          display: 'block',
          fontSize: 12,
          fontWeight: 800,
          color: '#374151',
          marginBottom: 6,
          letterSpacing: 0.3,
        }}
      >
        {label}
      </label>
      {children}
    </div>
  );
}

function ErrorBox({ text }) {
  return (
    <div
      style={{
        background: '#FEE2E2',
        color: '#D64545',
        padding: 10,
        borderRadius: 8,
        fontSize: 13,
        marginBottom: 12,
      }}
    >
      {text}
    </div>
  );
}

const inputStyle = {
  width: '100%',
  padding: '10px 14px',
  borderRadius: 10,
  border: '1px solid #E5E7EB',
  fontSize: 14,
  outline: 'none',
  fontFamily: 'inherit',
  background: 'white',
  boxSizing: 'border-box',
};

const goldBtn = {
  padding: '12px 22px',
  borderRadius: 10,
  border: 'none',
  background: 'linear-gradient(135deg, #F0C566 0%, #D4A13A 100%)',
  color: '#0B2B5B',
  fontSize: 14,
  fontWeight: 800,
  cursor: 'pointer',
  boxShadow: '0 4px 12px rgba(212,161,58,0.3)',
};