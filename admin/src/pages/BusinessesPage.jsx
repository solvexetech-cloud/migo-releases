import { useEffect, useMemo, useState } from 'react';
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  updateDoc,
  getDoc, // 🆕 ഇമെയിൽ കണ്ടെത്താൻ ചേർത്തത്
} from 'firebase/firestore';
import { db } from '../firebase';
import { useIsMobile } from '../hooks/useIsMobile';

const EMPTY_FORM = {
  name: '',
  category: '',
  addressLine: '',
  city: '',
  country: 'Qatar',
  currency: 'QAR',
  description: '',
  phone: '',
  whatsapp: '',
  website: '',
  mapUrl: '',
  logoUrl: '',
  coverUrl: '',
  openTime: '09:00',
  closeTime: '22:00',
  countryCode: 'QA',
  zoneId: '',
  areaId: '',
  status: 'approved',
  verified: false,
  ownerEmail: '', // 🆕 ഇമെയിൽ കാണിക്കാൻ ചേർത്തത്
};

const STATUS_FILTERS = [
  { key: 'all', label: 'All' },
  { key: 'pending', label: 'Pending' },
  { key: 'approved', label: 'Approved' },
  { key: 'suspended', label: 'Suspended' },
  { key: 'rejected', label: 'Rejected' },
];

export default function BusinessesPage() {
  const [businesses, setBusinesses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [form, setForm] = useState(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [filter, setFilter] = useState('all');
  const [search, setSearch] = useState('');
  const [categories, setCategories] = useState([]);
  const [countries, setCountries] = useState([]);
  const [zones, setZones] = useState([]);
  const [areas, setAreas] = useState([]);
  const isMobile = useIsMobile();

  // Businesses listener
  useEffect(() => {
    const q = query(
      collection(db, 'businesses'),
      orderBy('createdAt', 'desc'),
    );
    const unsub = onSnapshot(
      q,
      (snap) => {
        setBusinesses(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
        setLoading(false);
      },
      (err) => {
        console.error(err);
        setLoading(false);
      },
    );
    return () => unsub();
  }, []);

  // Categories for dropdown
  useEffect(() => {
    const unsub = onSnapshot(
      query(collection(db, 'categories'), orderBy('order', 'asc')),
      (snap) =>
        setCategories(snap.docs.map((d) => ({ id: d.id, ...d.data() }))),
    );
    return () => unsub();
  }, []);

  // Countries
  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'countries'), (snap) =>
      setCountries(snap.docs.map((d) => ({ id: d.id, ...d.data() }))),
    );
    return () => unsub();
  }, []);

  // Zones
  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'zones'), (snap) =>
      setZones(snap.docs.map((d) => ({ id: d.id, ...d.data() }))),
    );
    return () => unsub();
  }, []);

  // Areas
  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'areas'), (snap) =>
      setAreas(snap.docs.map((d) => ({ id: d.id, ...d.data() }))),
    );
    return () => unsub();
  }, []);

  const filtered = useMemo(() => {
    let list = businesses;
    if (filter !== 'all') list = list.filter((b) => b.status === filter);
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(
        (b) =>
          b.name?.toLowerCase().includes(q) ||
          b.city?.toLowerCase().includes(q) ||
          b.phone?.includes(q),
      );
    }
    return list;
  }, [businesses, filter, search]);

  function openAdd() {
    setEditingId(null);
    setForm(EMPTY_FORM);
    setError('');
    setShowModal(true);
  }

  // 🆕 Edit ചെയ്യുമ്പോൾ ഇമെയിൽ കണ്ടെത്താനുള്ള ഫങ്ക്ഷൻ
  async function openEdit(b) {
    let ownerEmail = 'N/A';
    if (b.ownerUid) {
      try {
        const userSnap = await getDoc(doc(db, 'users', b.ownerUid));
        if (userSnap.exists()) {
          ownerEmail = userSnap.data().email || 'No email found';
        }
      } catch (err) {
        console.error("Error fetching email:", err);
      }
    }

    setEditingId(b.id);
    setForm({
      name: b.name || '',
      category: b.category || '',
      addressLine: b.addressLine || '',
      city: b.city || '',
      country: b.country || 'Qatar',
      currency: b.currency || 'QAR',
      description: b.description || '',
      phone: b.phone || '',
      whatsapp: b.whatsapp || '',
      website: b.website || '',
      mapUrl: b.mapUrl || '',
      logoUrl: b.logoUrl || '',
      coverUrl: b.coverUrl || '',
      openTime: b.openTime || '09:00',
      closeTime: b.closeTime || '22:00',
      countryCode: b.countryCode || 'QA',
      zoneId: b.zoneId || '',
      areaId: b.areaId || '',
      status: b.status || 'approved',
      verified: b.verified ?? false,
      ownerEmail: ownerEmail, // 🆕 ഇമെയിൽ ഫോമിലേക്ക് ചേർക്കുന്നു
    });
    setError('');
    setShowModal(true);
  }

  async function handleSave() {
    if (!form.name.trim() || !form.category || !form.addressLine.trim()) {
      setError('Name, Category, and Address are required');
      return;
    }
    setSaving(true);
    setError('');
    try {
      const payload = {
        name: form.name.trim(),
        category: form.category,
        addressLine: form.addressLine.trim(),
        city: form.city.trim(),
        country: form.country.trim(),
        currency: form.currency,
        description: form.description.trim(),
        phone: form.phone.trim(),
        whatsapp: form.whatsapp.trim(),
        website: form.website.trim(),
        mapUrl: form.mapUrl.trim(),
        logoUrl: form.logoUrl.trim(),
        coverUrl: form.coverUrl.trim(),
        openTime: form.openTime,
        closeTime: form.closeTime,
        countryCode: form.countryCode,
        zoneId: form.zoneId,
        areaId: form.areaId,
        status: form.status,
        verified: form.verified,
        updatedAt: serverTimestamp(),
      };
      if (editingId) {
        await updateDoc(doc(db, 'businesses', editingId), payload);
      } else {
        await addDoc(collection(db, 'businesses'), {
          ...payload,
          claimedCount: 0,
          createdAt: serverTimestamp(),
        });
      }
      setShowModal(false);
    } catch (e) {
      console.error(e);
      setError(e.message || 'Failed to save');
    } finally {
      setSaving(false);
    }
  }

  async function handleApprove(b) {
    if (!confirm(`Approve "${b.name}"?`)) return;
    try {
      await updateDoc(doc(db, 'businesses', b.id), {
        status: 'approved',
        verified: true,
        updatedAt: serverTimestamp(),
      });
    } catch (e) {
      alert('Failed: ' + e.message);
    }
  }

  async function handleSuspend(b) {
    if (!confirm(`Suspend "${b.name}"?`)) return;
    try {
      await updateDoc(doc(db, 'businesses', b.id), {
        status: 'suspended',
        updatedAt: serverTimestamp(),
      });
    } catch (e) {
      alert('Failed: ' + e.message);
    }
  }

  async function handleDelete(b) {
    if (
      !confirm(
        `DELETE "${b.name}" permanently?\n\nThis cannot be undone.`,
      )
    )
      return;
    try {
      await deleteDoc(doc(db, 'businesses', b.id));
    } catch (e) {
      alert('Failed: ' + e.message);
    }
  }

  const filteredZones = zones.filter(
    (z) => z.countryCode === form.countryCode,
  );
  const filteredAreas = areas.filter((a) => a.zoneSlug === form.zoneId);

  return (
    <div style={{ padding: isMobile ? 16 : 32, maxWidth: 1200 }}>
      <header
        style={{
          marginBottom: 20,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: 16,
        }}
      >
        <div>
          <h1
            style={{
              fontSize: 28,
              fontWeight: 900,
              color: '#0B2B5B',
              letterSpacing: -0.5,
              marginBottom: 4,
            }}
          >
            Businesses
          </h1>
          <p style={{ fontSize: 14, color: '#6B7280' }}>
            {businesses.length} total · {filtered.length} shown
          </p>
        </div>
        <button
          onClick={openAdd}
          style={{
            padding: '12px 22px',
            borderRadius: 10,
            border: 'none',
            background:
              'linear-gradient(135deg, #F0C566 0%, #D4A13A 100%)',
            color: '#0B2B5B',
            fontSize: 14,
            fontWeight: 800,
            cursor: 'pointer',
            boxShadow: '0 4px 12px rgba(212,161,58,0.3)',
          }}
        >
          + Add Business
        </button>
      </header>

      {/* Filters + Search */}
      <div
        style={{
          display: 'flex',
          gap: 10,
          marginBottom: 20,
          flexWrap: 'wrap',
          alignItems: 'center',
        }}
      >
        {STATUS_FILTERS.map((f) => (
          <button
            key={f.key}
            onClick={() => setFilter(f.key)}
            style={{
              padding: '8px 16px',
              borderRadius: 8,
              border: 'none',
              background: filter === f.key ? '#0B2B5B' : 'white',
              color: filter === f.key ? 'white' : '#374151',
              fontSize: 13,
              fontWeight: 700,
              cursor: 'pointer',
              boxShadow: '0 2px 6px rgba(0,0,0,0.05)',
            }}
          >
            {f.label}
          </button>
        ))}
        <input
          type="text"
          placeholder="Search name, city, phone..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={{
            flex: 1,
            minWidth: 200,
            padding: '10px 14px',
            borderRadius: 10,
            border: '1px solid #E5E7EB',
            fontSize: 13,
            outline: 'none',
            background: 'white',
          }}
        />
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
          No businesses found. {businesses.length === 0 && 'Click "Add Business" to create one.'}
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {filtered.map((b) => (
            <BusinessRow
              key={b.id}
              business={b}
              isMobile={isMobile}
              onEdit={() => openEdit(b)}
              onApprove={() => handleApprove(b)}
              onSuspend={() => handleSuspend(b)}
              onDelete={() => handleDelete(b)}
            />
          ))}
        </div>
      )}

      {showModal && (
        <Modal
          form={form}
          setForm={setForm}
          editingId={editingId}
          saving={saving}
          error={error}
          categories={categories}
          countries={countries}
          filteredZones={filteredZones}
          filteredAreas={filteredAreas}
          onClose={() => !saving && setShowModal(false)}
          onSave={handleSave}
        />
      )}
    </div>
  );
}

// ---------- Row Component ----------
function BusinessRow({
  business: b,
  isMobile,
  onEdit,
  onApprove,
  onSuspend,
  onDelete,
}) {
  const statusColor = {
    approved: { bg: '#E5F5EA', fg: '#2E9E5B' },
    pending: { bg: '#FFF3D6', fg: '#A67920' },
    suspended: { bg: '#FEE2E2', fg: '#D64545' },
    rejected: { bg: '#FEE2E2', fg: '#D64545' },
  }[b.status] || { bg: '#F1EEEA', fg: '#6B7280' };

  return (
    <div
      style={{
        background: 'white',
        borderRadius: 16,
        padding: isMobile ? 16 : 20,
        boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
      }}
    >
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-start',
          gap: 12,
          flexWrap: 'wrap',
          marginBottom: 12,
        }}
      >
        <div style={{ flex: 1, minWidth: 200 }}>
          <div
            style={{
              fontSize: 17,
              fontWeight: 900,
              color: '#0B2B5B',
              marginBottom: 6,
            }}
          >
            {b.name}
          </div>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {b.category && (
              <Tag bg="#EFF6FF" fg="#1E4B8F">
                {b.category}
              </Tag>
            )}
            <Tag bg={statusColor.bg} fg={statusColor.fg}>
              {(b.status || 'unknown').toUpperCase()}
            </Tag>
            {b.verified && (
              <Tag bg="#E5F5EA" fg="#2E9E5B">
                ✓ VERIFIED
              </Tag>
            )}
          </div>
        </div>

        <div
          style={{
            display: 'flex',
            gap: 6,
            flexWrap: 'wrap',
          }}
        >
          {b.status === 'pending' && (
            <ActionBtn color="#2E9E5B" onClick={onApprove}>
              ✓ Approve
            </ActionBtn>
          )}
          {b.status === 'approved' && (
            <ActionBtn color="#A67920" onClick={onSuspend}>
              Suspend
            </ActionBtn>
          )}
          <ActionBtn color="#1E4B8F" onClick={onEdit}>
            Edit
          </ActionBtn>
          <ActionBtn color="#D64545" onClick={onDelete}>
            Delete
          </ActionBtn>
        </div>
      </div>

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: isMobile
            ? '1fr 1fr'
            : 'repeat(auto-fit, minmax(180px, 1fr))',
          gap: 10,
          fontSize: 13,
          color: '#374151',
        }}
      >
        <Info label="Address" value={b.addressLine} />
        <Info label="City" value={`${b.city || ''}, ${b.country || ''}`} />
        <Info label="Phone" value={b.phone || '—'} />
        <Info label="Currency" value={b.currency || '—'} />
        <Info label="Area" value={b.areaId || '—'} />
        <Info label="Owner" value={b.ownerUid} mono />
      </div>
    </div>
  );
}

function Info({ label, value, mono }) {
  return (
    <div>
      <div
        style={{
          fontSize: 10,
          fontWeight: 800,
          color: '#9CA3AF',
          letterSpacing: 0.5,
          marginBottom: 3,
        }}
      >
        {label.toUpperCase()}
      </div>
      <div
        style={{
          fontSize: 13,
          fontWeight: 600,
          color: '#111418',
          fontFamily: mono ? 'monospace' : 'inherit',
          wordBreak: 'break-all',
        }}
      >
        {value || '—'}
      </div>
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

function ActionBtn({ children, color, onClick }) {
  return (
    <button
      onClick={onClick}
      style={{
        padding: '7px 12px',
        borderRadius: 7,
        border: 'none',
        background: color + '15',
        color,
        fontSize: 11,
        fontWeight: 800,
        cursor: 'pointer',
      }}
    >
      {children}
    </button>
  );
}

// ---------- Modal ----------
function Modal({
  form,
  setForm,
  editingId,
  saving,
  error,
  categories,
  countries,
  filteredZones,
  filteredAreas,
  onClose,
  onSave,
}) {
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
      onClick={onClose}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          background: 'white',
          borderRadius: 16,
          padding: 28,
          maxWidth: 640,
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
          {editingId ? 'Edit Business' : 'Add Business'}
        </h2>

        {/* 🆕 ഇമെയിൽ കാണിക്കാനുള്ള ഫീൽഡ് (Edit ചെയ്യുമ്പോൾ മാത്രം) */}
        {editingId && (
          <Field label="Owner Login Email (Read-only)">
            <input
              style={{ ...inputStyle, backgroundColor: '#f3f4f6', cursor: 'not-allowed', color: '#6B7280' }}
              value={form.ownerEmail || 'N/A'}
              disabled
            />
          </Field>
        )}

        <Row>
          <Field label="Name *">
            <input
              style={inputStyle}
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              placeholder="Business name"
              autoFocus
            />
          </Field>
          <Field label="Category *">
            <select
              style={inputStyle}
              value={form.category}
              onChange={(e) =>
                setForm({ ...form, category: e.target.value })
              }
            >
              <option value="">— Select —</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </Field>
        </Row>

        <Field label="Address *">
          <input
            style={inputStyle}
            value={form.addressLine}
            onChange={(e) =>
              setForm({ ...form, addressLine: e.target.value })
            }
          />
        </Field>

        <Row>
          <Field label="City">
            <input
              style={inputStyle}
              value={form.city}
              onChange={(e) => setForm({ ...form, city: e.target.value })}
            />
          </Field>
          <Field label="Country">
            <input
              style={inputStyle}
              value={form.country}
              onChange={(e) => setForm({ ...form, country: e.target.value })}
            />
          </Field>
        </Row>

        <Row>
          <Field label="Country Code">
            <select
              style={inputStyle}
              value={form.countryCode}
              onChange={(e) =>
                setForm({
                  ...form,
                  countryCode: e.target.value,
                  zoneId: '',
                  areaId: '',
                })
              }
            >
              <option value="">— Select —</option>
              {countries.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.flag} {c.name}
                </option>
              ))}
            </select>
          </Field>
          <Field label="Currency">
            <select
              style={inputStyle}
              value={form.currency}
              onChange={(e) =>
                setForm({ ...form, currency: e.target.value })
              }
            >
              <option value="QAR">QAR</option>
              <option value="INR">INR</option>
            </select>
          </Field>
        </Row>

        <Row>
          <Field label="Zone">
            <select
              style={inputStyle}
              value={form.zoneId}
              onChange={(e) =>
                setForm({ ...form, zoneId: e.target.value, areaId: '' })
              }
            >
              <option value="">— Select —</option>
              {filteredZones.map((z) => (
                <option key={z.id} value={z.id}>
                  {z.name}
                </option>
              ))}
            </select>
          </Field>
          <Field label="Area">
            <select
              style={inputStyle}
              value={form.areaId}
              onChange={(e) =>
                setForm({ ...form, areaId: e.target.value })
              }
            >
              <option value="">— Select —</option>
              {filteredAreas.map((a) => (
                <option key={a.id} value={a.id}>
                  {a.name}
                </option>
              ))}
            </select>
          </Field>
        </Row>

        <Row>
          <Field label="Phone">
            <input
              style={inputStyle}
              value={form.phone}
              onChange={(e) => setForm({ ...form, phone: e.target.value })}
            />
          </Field>
          <Field label="WhatsApp">
            <input
              style={inputStyle}
              value={form.whatsapp}
              onChange={(e) =>
                setForm({ ...form, whatsapp: e.target.value })
              }
            />
          </Field>
        </Row>

        <Row>
          <Field label="Open Time">
            <input
              style={inputStyle}
              value={form.openTime}
              onChange={(e) =>
                setForm({ ...form, openTime: e.target.value })
              }
              placeholder="09:00"
            />
          </Field>
          <Field label="Close Time">
            <input
              style={inputStyle}
              value={form.closeTime}
              onChange={(e) =>
                setForm({ ...form, closeTime: e.target.value })
              }
              placeholder="22:00"
            />
          </Field>
        </Row>

        <Field label="Description">
          <textarea
            style={{ ...inputStyle, minHeight: 70, resize: 'vertical' }}
            value={form.description}
            onChange={(e) =>
              setForm({ ...form, description: e.target.value })
            }
          />
        </Field>

        <Row>
          <Field label="Logo URL">
            <input
              style={inputStyle}
              value={form.logoUrl}
              onChange={(e) =>
                setForm({ ...form, logoUrl: e.target.value })
              }
              placeholder="https://res.cloudinary.com/..."
            />
          </Field>
          <Field label="Cover URL">
            <input
              style={inputStyle}
              value={form.coverUrl}
              onChange={(e) =>
                setForm({ ...form, coverUrl: e.target.value })
              }
            />
          </Field>
        </Row>

        <Row>
          <Field label="Website">
            <input
              style={inputStyle}
              value={form.website}
              onChange={(e) =>
                setForm({ ...form, website: e.target.value })
              }
            />
          </Field>
          <Field label="Map URL">
            <input
              style={inputStyle}
              value={form.mapUrl}
              onChange={(e) => setForm({ ...form, mapUrl: e.target.value })}
            />
          </Field>
        </Row>

        <Row>
          <Field label="Status">
            <select
              style={inputStyle}
              value={form.status}
              onChange={(e) =>
                setForm({ ...form, status: e.target.value })
              }
            >
              <option value="pending">Pending</option>
              <option value="approved">Approved</option>
              <option value="suspended">Suspended</option>
              <option value="rejected">Rejected</option>
            </select>
          </Field>
          <Field label="Verified">
            <label
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 8,
                padding: '10px 0',
              }}
            >
              <input
                type="checkbox"
                checked={form.verified}
                onChange={(e) =>
                  setForm({ ...form, verified: e.target.checked })
                }
                style={{ width: 18, height: 18 }}
              />
              <span style={{ fontSize: 13 }}>Mark as verified</span>
            </label>
          </Field>
        </Row>

        {error && (
          <div
            style={{
              background: '#FEE2E2',
              color: '#D64545',
              padding: 10,
              borderRadius: 8,
              fontSize: 13,
              marginBottom: 16,
            }}
          >
            {error}
          </div>
        )}

        <div
          style={{ display: 'flex', gap: 10, justifyContent: 'flex-end' }}
        >
          <button
            onClick={onClose}
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
            {saving ? 'Saving…' : editingId ? 'Update' : 'Create'}
          </button>
        </div>
      </div>
    </div>
  );
}

// ---------- Small helpers ----------
function Row({ children }) {
  return (
    <div
      style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
        gap: 12,
      }}
    >
      {children}
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