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
} from 'firebase/firestore';
import { db } from '../firebase';
import { useIsMobile } from '../hooks/useIsMobile';

const EMPTY_FORM = {
  name: '',
  email: '',
  phone: '',
  countryCode: 'QA',
  zoneSlug: '',
  areaIds: [],
  revenueShare: 0.4,
  status: 'active',
};

const STATUS_COLORS = {
  active: { bg: '#E5F5EA', fg: '#2E9E5B' },
  pending: { bg: '#FFF3D6', fg: '#A67920' },
  suspended: { bg: '#FEE2E2', fg: '#D64545' },
};

export default function AgenciesPage() {
  const [agencies, setAgencies] = useState([]);
  const [countries, setCountries] = useState([]);
  const [zones, setZones] = useState([]);
  const [areas, setAreas] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [form, setForm] = useState(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [filter, setFilter] = useState('all');
  const [search, setSearch] = useState('');
  const isMobile = useIsMobile();

  // Agencies
  useEffect(() => {
    const unsub = onSnapshot(
      query(collection(db, 'agencies'), orderBy('createdAt', 'desc')),
      (snap) => {
        setAgencies(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
        setLoading(false);
      },
      (err) => {
        console.error(err);
        setLoading(false);
      },
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
    let list = agencies;
    if (filter !== 'all') list = list.filter((a) => a.status === filter);
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(
        (a) =>
          (a.name || '').toLowerCase().includes(q) ||
          (a.email || '').toLowerCase().includes(q),
      );
    }
    return list;
  }, [agencies, filter, search]);

  function openAdd() {
    setEditingId(null);
    setForm(EMPTY_FORM);
    setError('');
    setShowModal(true);
  }

  function openEdit(a) {
    setEditingId(a.id);
    setForm({
      name: a.name || '',
      email: a.email || '',
      phone: a.phone || '',
      countryCode: a.countryCode || 'QA',
      zoneSlug: a.zoneSlug || '',
      areaIds: a.areaIds || [],
      revenueShare: a.revenueShare ?? 0.4,
      status: a.status || 'active',
    });
    setError('');
    setShowModal(true);
  }

  async function handleSave() {
    if (!form.name.trim() || !form.email.trim()) {
      setError('Name and Email are required');
      return;
    }
    setSaving(true);
    setError('');
    try {
      const payload = {
        name: form.name.trim(),
        email: form.email.trim().toLowerCase(),
        phone: form.phone.trim(),
        countryCode: form.countryCode,
        zoneSlug: form.zoneSlug,
        areaIds: form.areaIds,
        revenueShare: Number(form.revenueShare) || 0.4,
        status: form.status,
        updatedAt: serverTimestamp(),
      };
      if (editingId) {
        await updateDoc(doc(db, 'agencies', editingId), payload);
      } else {
        await addDoc(collection(db, 'agencies'), {
          ...payload,
          ownerUid: null,
          contractStart: serverTimestamp(),
          contractEnd: null,
          createdAt: serverTimestamp(),
        });
      }
      setShowModal(false);
    } catch (e) {
      setError(e.message);
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete(a) {
    if (!confirm(`Delete "${a.name}"? This cannot be undone.`)) return;
    try {
      await deleteDoc(doc(db, 'agencies', a.id));
    } catch (e) {
      alert('Failed: ' + e.message);
    }
  }

  async function handleToggleStatus(a) {
    const next = a.status === 'active' ? 'suspended' : 'active';
    if (!confirm(`Change "${a.name}" status to ${next}?`)) return;
    try {
      await updateDoc(doc(db, 'agencies', a.id), {
        status: next,
        updatedAt: serverTimestamp(),
      });
    } catch (e) {
      alert('Failed: ' + e.message);
    }
  }

  const filteredZones = zones.filter(
    (z) => z.countryCode === form.countryCode,
  );
  const filteredAreas = areas.filter((a) => a.zoneSlug === form.zoneSlug);

  function toggleArea(areaId) {
    setForm((f) => ({
      ...f,
      areaIds: f.areaIds.includes(areaId)
        ? f.areaIds.filter((x) => x !== areaId)
        : [...f.areaIds, areaId],
    }));
  }

  return (
    <div style={{ padding: isMobile ? 16 : 32, maxWidth: 1300 }}>
      <header
        style={{
          marginBottom: 20,
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
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
            Agencies
          </h1>
          <p style={{ fontSize: 14, color: '#6B7280' }}>
            {agencies.length} total · {filtered.length} shown
          </p>
        </div>
        <button onClick={openAdd} style={goldBtn}>
          + Add Agency
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
        {['all', 'active', 'pending', 'suspended'].map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            style={{
              padding: '8px 16px',
              borderRadius: 8,
              border: 'none',
              background: filter === f ? '#0B2B5B' : 'white',
              color: filter === f ? 'white' : '#374151',
              fontSize: 13,
              fontWeight: 700,
              cursor: 'pointer',
              textTransform: 'capitalize',
              boxShadow: '0 2px 6px rgba(0,0,0,0.05)',
            }}
          >
            {f}
          </button>
        ))}
        <input
          type="text"
          placeholder="Search name, email..."
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
          No agencies found.
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {filtered.map((a) => (
            <AgencyCard
              key={a.id}
              agency={a}
              isMobile={isMobile}
              onEdit={() => openEdit(a)}
              onDelete={() => handleDelete(a)}
              onToggle={() => handleToggleStatus(a)}
            />
          ))}
        </div>
      )}

      {showModal && (
        <AgencyModal
          form={form}
          setForm={setForm}
          editingId={editingId}
          saving={saving}
          error={error}
          countries={countries}
          filteredZones={filteredZones}
          filteredAreas={filteredAreas}
          onToggleArea={toggleArea}
          onClose={() => !saving && setShowModal(false)}
          onSave={handleSave}
        />
      )}
    </div>
  );
}

function AgencyCard({ agency: a, isMobile, onEdit, onDelete, onToggle }) {
  const sc = STATUS_COLORS[a.status] || STATUS_COLORS.pending;
  return (
    <div
      style={{
        background: 'white',
        borderRadius: 14,
        padding: 20,
        boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
      }}
    >
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: 12,
          marginBottom: 12,
        }}
      >
        <div style={{ flex: 1, minWidth: 220 }}>
          <div
            style={{
              fontSize: 17,
              fontWeight: 900,
              color: '#0B2B5B',
              marginBottom: 6,
            }}
          >
            {a.name}
          </div>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            <Tag bg={sc.bg} fg={sc.fg}>
              {(a.status || '').toUpperCase()}
            </Tag>
            <Tag bg="#EFF6FF" fg="#1E4B8F">
              {a.countryCode} · {a.zoneSlug}
            </Tag>
            <Tag bg="#F6F3EE" fg="#6B7280">
              {a.revenueShare != null ? `${(a.revenueShare * 100).toFixed(0)}% share` : '—'}
            </Tag>
            <Tag bg="#F6F3EE" fg="#6B7280">
              {a.areaIds?.length || 0} area{(a.areaIds?.length || 0) !== 1 ? 's' : ''}
            </Tag>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          <ActionBtn color="#A67920" onClick={onToggle}>
            {a.status === 'active' ? 'Suspend' : 'Activate'}
          </ActionBtn>
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
          gap: 12,
          fontSize: 13,
        }}
      >
        <Info label="Email" value={a.email} />
        <Info label="Phone" value={a.phone || '—'} />
        <Info
          label="Areas"
          value={(a.areaIds || []).join(', ') || '—'}
        />
      </div>
    </div>
  );
}

function Info({ label, value }) {
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
          wordBreak: 'break-word',
        }}
      >
        {value}
      </div>
    </div>
  );
}

function AgencyModal({
  form,
  setForm,
  editingId,
  saving,
  error,
  countries,
  filteredZones,
  filteredAreas,
  onToggleArea,
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
          maxWidth: 560,
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
          {editingId ? 'Edit Agency' : 'Add Agency'}
        </h2>

        <Field label="Name *">
          <input
            style={inputStyle}
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
            placeholder="e.g., Doha Metro Franchise"
            autoFocus
          />
        </Field>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          <Field label="Email *">
            <input
              type="email"
              style={inputStyle}
              value={form.email}
              onChange={(e) =>
                setForm({ ...form, email: e.target.value })
              }
            />
          </Field>
          <Field label="Phone">
            <input
              style={inputStyle}
              value={form.phone}
              onChange={(e) => setForm({ ...form, phone: e.target.value })}
            />
          </Field>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          <Field label="Country">
            <select
              style={inputStyle}
              value={form.countryCode}
              onChange={(e) =>
                setForm({
                  ...form,
                  countryCode: e.target.value,
                  zoneSlug: '',
                  areaIds: [],
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
          <Field label="Zone">
            <select
              style={inputStyle}
              value={form.zoneSlug}
              onChange={(e) =>
                setForm({
                  ...form,
                  zoneSlug: e.target.value,
                  areaIds: [],
                })
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
        </div>

        <Field label={`Areas (${form.areaIds.length} selected)`}>
          {filteredAreas.length === 0 ? (
            <div
              style={{
                fontSize: 12,
                color: '#9CA3AF',
                padding: 12,
                background: '#F6F3EE',
                borderRadius: 8,
              }}
            >
              Select a zone first to see available areas.
            </div>
          ) : (
            <div
              style={{
                display: 'flex',
                flexWrap: 'wrap',
                gap: 6,
                padding: 10,
                background: '#F6F3EE',
                borderRadius: 10,
              }}
            >
              {filteredAreas.map((area) => {
                const selected = form.areaIds.includes(area.id);
                return (
                  <button
                    key={area.id}
                    type="button"
                    onClick={() => onToggleArea(area.id)}
                    style={{
                      padding: '6px 12px',
                      borderRadius: 8,
                      border: selected
                        ? '1px solid #D4A13A'
                        : '1px solid #E5E7EB',
                      background: selected ? '#FFF3D6' : 'white',
                      color: selected ? '#A67920' : '#374151',
                      fontSize: 12,
                      fontWeight: 700,
                      cursor: 'pointer',
                    }}
                  >
                    {selected ? '✓ ' : '+ '}
                    {area.name}
                  </button>
                );
              })}
            </div>
          )}
        </Field>

        <Field label={`Revenue Share: ${(form.revenueShare * 100).toFixed(0)}%`}>
          <input
            type="range"
            min="0"
            max="1"
            step="0.05"
            style={{ width: '100%' }}
            value={form.revenueShare}
            onChange={(e) =>
              setForm({ ...form, revenueShare: Number(e.target.value) })
            }
          />
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              fontSize: 10,
              color: '#9CA3AF',
              marginTop: 4,
            }}
          >
            <span>0%</span>
            <span>50%</span>
            <span>100%</span>
          </div>
        </Field>

        <Field label="Status">
          <select
            style={inputStyle}
            value={form.status}
            onChange={(e) => setForm({ ...form, status: e.target.value })}
          >
            <option value="active">Active</option>
            <option value="pending">Pending</option>
            <option value="suspended">Suspended</option>
          </select>
        </Field>

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
          <button onClick={onSave} disabled={saving} style={goldBtn}>
            {saving ? 'Saving…' : editingId ? 'Update' : 'Create'}
          </button>
        </div>
      </div>
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