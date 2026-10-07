import { useEffect, useMemo, useState } from 'react';
import {
  collection,
  deleteDoc,
  doc,
  onSnapshot,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { db } from '../firebase';
import { useIsMobile } from '../hooks/useIsMobile';

// ---------- TABS ----------
const TABS = [
  { id: 'countries', label: 'Countries', icon: '🌍' },
  { id: 'zones', label: 'Zones', icon: '📍' },
  { id: 'areas', label: 'Areas', icon: '📌' },
  { id: 'agencies', label: 'Agencies', icon: '🏢' },
];

export default function GeographyPage() {
  const [tab, setTab] = useState('countries');
  const isMobile = useIsMobile();

  return (
    <div
      style={{
        padding: isMobile ? 16 : 32,
        maxWidth: 1200,
      }}
    >
      <header style={{ marginBottom: 20 }}>
        <h1
          style={{
            fontSize: isMobile ? 24 : 28,
            fontWeight: 900,
            color: '#0B2B5B',
            letterSpacing: -0.5,
            marginBottom: 4,
          }}
        >
          Geography
        </h1>
        <p style={{ fontSize: 14, color: '#6B7280' }}>
          Manage countries, zones, areas, and agencies.
        </p>
      </header>

      {/* Tabs */}
      <div
        style={{
          display: 'flex',
          gap: 8,
          marginBottom: 20,
          overflowX: 'auto',
          paddingBottom: 4,
        }}
      >
        {TABS.map((t) => {
          const active = tab === t.id;
          return (
            <button
              key={t.id}
              onClick={() => setTab(t.id)}
              style={{
                padding: '10px 18px',
                borderRadius: 10,
                border: 'none',
                background: active
                  ? 'linear-gradient(135deg, #F0C566 0%, #D4A13A 100%)'
                  : 'white',
                color: active ? '#0B2B5B' : '#6B7280',
                fontSize: 13,
                fontWeight: 800,
                cursor: 'pointer',
                whiteSpace: 'nowrap',
                boxShadow: '0 2px 6px rgba(0,0,0,0.04)',
              }}
            >
              {t.icon} {t.label}
            </button>
          );
        })}
      </div>

      {tab === 'countries' && <CountriesTab isMobile={isMobile} />}
      {tab === 'zones' && <ZonesTab isMobile={isMobile} />}
      {tab === 'areas' && <AreasTab isMobile={isMobile} />}
      {tab === 'agencies' && <AgenciesTab isMobile={isMobile} />}
    </div>
  );
}

// ============================================================
// COUNTRIES TAB
// ============================================================
function CountriesTab({ isMobile }) {
  const [countries, setCountries] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(null);
  const [working, setWorking] = useState({});

  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'countries'), (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      list.sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
      setCountries(list);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  async function handleSave(form) {
    setWorking({ save: true });
    try {
      const code = (form.code || '').toUpperCase().trim();
      if (!code) throw new Error('Country code required');

      await setDoc(
        doc(db, 'countries', code),
        {
          code,
          name: form.name.trim(),
          flag: form.flag.trim() || '🌍',
          currency: form.currency.trim().toUpperCase() || 'QAR',
          locale: form.locale.trim() || 'en',
          order: Number(form.order) || 0,
          active: form.active !== false,
          updatedAt: serverTimestamp(),
          ...(modal === 'add' && { createdAt: serverTimestamp() }),
        },
        { merge: true },
      );
      setModal(null);
    } catch (e) {
      alert('Failed: ' + e.message);
    } finally {
      setWorking({});
    }
  }

  async function handleToggle(c) {
    try {
      await updateDoc(doc(db, 'countries', c.id), {
        active: !c.active,
        updatedAt: serverTimestamp(),
      });
    } catch (e) {
      alert('Failed: ' + e.message);
    }
  }

  async function handleDelete(c) {
    if (!window.confirm(`Delete country "${c.name}"? This cannot be undone.`))
      return;
    try {
      await deleteDoc(doc(db, 'countries', c.id));
    } catch (e) {
      alert('Failed: ' + e.message);
    }
  }

  if (loading) return <div style={{ color: '#6B7280' }}>Loading…</div>;

  return (
    <>
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 12 }}>
        <button onClick={() => setModal({ mode: 'add' })} style={addBtnStyle}>
          + Add Country
        </button>
      </div>

      {countries.length === 0 ? (
        <EmptyBox text="No countries yet." />
      ) : (
        <div style={cardContainerStyle}>
          {countries.map((c, i) => (
            <div
              key={c.id}
              style={{
                ...rowStyle(isMobile, '60px 2fr 1fr 1fr 1fr 180px'),
                borderBottom:
                  i < countries.length - 1 ? '1px solid #F1EEEA' : 'none',
              }}
            >
              <div style={{ fontSize: 28 }}>{c.flag || '🌍'}</div>
              <div>
                <div style={primaryTextStyle}>{c.name}</div>
                <div style={secondaryTextStyle}>
                  {c.code} · {c.currency} · {c.locale}
                </div>
              </div>
              <div style={secondaryTextStyle}>Order {c.order ?? 0}</div>
              <div>
                <StatusBadge active={c.active} />
              </div>
              <div />
              <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                <button
                  onClick={() => setModal({ mode: 'edit', data: c })}
                  style={actionBtn('#1E4B8F')}
                >
                  Edit
                </button>
                <button
                  onClick={() => handleToggle(c)}
                  style={actionBtn(c.active ? '#A67920' : '#2E9E5B')}
                >
                  {c.active ? 'Hide' : 'Show'}
                </button>
                <button
                  onClick={() => handleDelete(c)}
                  style={actionBtn('#D64545')}
                >
                  Delete
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {modal && (
        <CountryModal
          mode={modal.mode}
          initial={modal.data}
          working={!!working.save}
          onClose={() => setModal(null)}
          onSave={handleSave}
        />
      )}
    </>
  );
}

function CountryModal({ mode, initial, working, onClose, onSave }) {
  const [form, setForm] = useState({
    code: initial?.code || '',
    name: initial?.name || '',
    flag: initial?.flag || '🇶🇦',
    currency: initial?.currency || 'QAR',
    locale: initial?.locale || 'en',
    order: initial?.order ?? 0,
    active: initial?.active ?? true,
  });

  return (
    <ModalShell
      title={mode === 'add' ? 'Add Country' : 'Edit Country'}
      onClose={onClose}
    >
      <Field label="Country Code *">
        <input
          value={form.code}
          onChange={(e) => setForm({ ...form, code: e.target.value })}
          placeholder="QA"
          disabled={mode === 'edit'}
          style={inputStyle}
        />
      </Field>
      <Field label="Name *">
        <input
          value={form.name}
          onChange={(e) => setForm({ ...form, name: e.target.value })}
          placeholder="Qatar"
          style={inputStyle}
        />
      </Field>
      <Field label="Flag Emoji">
        <input
          value={form.flag}
          onChange={(e) => setForm({ ...form, flag: e.target.value })}
          placeholder="🇶🇦"
          style={inputStyle}
        />
      </Field>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        <Field label="Currency">
          <input
            value={form.currency}
            onChange={(e) => setForm({ ...form, currency: e.target.value })}
            placeholder="QAR"
            style={inputStyle}
          />
        </Field>
        <Field label="Locale">
          <input
            value={form.locale}
            onChange={(e) => setForm({ ...form, locale: e.target.value })}
            placeholder="en"
            style={inputStyle}
          />
        </Field>
      </div>
      <Field label="Display Order">
        <input
          type="number"
          value={form.order}
          onChange={(e) => setForm({ ...form, order: e.target.value })}
          style={inputStyle}
        />
      </Field>
      <ActiveToggle
        checked={form.active}
        onChange={(v) => setForm({ ...form, active: v })}
      />
      <ModalActions
        onCancel={onClose}
        onSave={() => onSave(form)}
        working={working}
        isEdit={mode === 'edit'}
      />
    </ModalShell>
  );
}

// ============================================================
// ZONES TAB
// ============================================================
function ZonesTab({ isMobile }) {
  const [zones, setZones] = useState([]);
  const [countries, setCountries] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filterCountry, setFilterCountry] = useState('all');
  const [modal, setModal] = useState(null);
  const [working, setWorking] = useState({});

  useEffect(() => {
    const unsub1 = onSnapshot(collection(db, 'zones'), (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      list.sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
      setZones(list);
      setLoading(false);
    });
    const unsub2 = onSnapshot(collection(db, 'countries'), (snap) => {
      setCountries(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
    });
    return () => {
      unsub1();
      unsub2();
    };
  }, []);

  const filtered = useMemo(() => {
    if (filterCountry === 'all') return zones;
    return zones.filter((z) => z.countryCode === filterCountry);
  }, [zones, filterCountry]);

  async function handleSave(form) {
    setWorking({ save: true });
    try {
      const slug = (form.slug || form.name)
        .toLowerCase()
        .trim()
        .replace(/\s+/g, '-');
      if (!slug) throw new Error('Slug/name required');

      await setDoc(
        doc(db, 'zones', slug),
        {
          countryCode: form.countryCode,
          name: form.name.trim(),
          slug,
          order: Number(form.order) || 0,
          active: form.active !== false,
          updatedAt: serverTimestamp(),
          ...(modal.mode === 'add' && { createdAt: serverTimestamp() }),
        },
        { merge: true },
      );
      setModal(null);
    } catch (e) {
      alert('Failed: ' + e.message);
    } finally {
      setWorking({});
    }
  }

  async function handleToggle(z) {
    try {
      await updateDoc(doc(db, 'zones', z.id), {
        active: !z.active,
        updatedAt: serverTimestamp(),
      });
    } catch (e) {
      alert('Failed: ' + e.message);
    }
  }

  async function handleDelete(z) {
    if (!window.confirm(`Delete zone "${z.name}"?`)) return;
    try {
      await deleteDoc(doc(db, 'zones', z.id));
    } catch (e) {
      alert('Failed: ' + e.message);
    }
  }

  if (loading) return <div style={{ color: '#6B7280' }}>Loading…</div>;

  return (
    <>
      <div
        style={{
          display: 'flex',
          gap: 10,
          marginBottom: 12,
          flexWrap: 'wrap',
          justifyContent: 'space-between',
        }}
      >
        <select
          value={filterCountry}
          onChange={(e) => setFilterCountry(e.target.value)}
          style={{ ...inputStyle, maxWidth: 220 }}
        >
          <option value="all">All Countries</option>
          {countries.map((c) => (
            <option key={c.id} value={c.id}>
              {c.flag} {c.name}
            </option>
          ))}
        </select>
        <button onClick={() => setModal({ mode: 'add' })} style={addBtnStyle}>
          + Add Zone
        </button>
      </div>

      {filtered.length === 0 ? (
        <EmptyBox text="No zones yet." />
      ) : (
        <div style={cardContainerStyle}>
          {filtered.map((z, i) => {
            const country = countries.find((c) => c.id === z.countryCode);
            return (
              <div
                key={z.id}
                style={{
                  ...rowStyle(isMobile, '60px 2fr 1fr 1fr 180px'),
                  borderBottom:
                    i < filtered.length - 1 ? '1px solid #F1EEEA' : 'none',
                }}
              >
                <div style={{ fontSize: 22 }}>{country?.flag || '📍'}</div>
                <div>
                  <div style={primaryTextStyle}>{z.name}</div>
                  <div style={secondaryTextStyle}>{z.slug}</div>
                </div>
                <div style={secondaryTextStyle}>{z.countryCode}</div>
                <div style={secondaryTextStyle}>Order {z.order ?? 0}</div>
                <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                  <button
                    onClick={() => setModal({ mode: 'edit', data: z })}
                    style={actionBtn('#1E4B8F')}
                  >
                    Edit
                  </button>
                  <button
                    onClick={() => handleToggle(z)}
                    style={actionBtn(z.active ? '#A67920' : '#2E9E5B')}
                  >
                    {z.active ? 'Hide' : 'Show'}
                  </button>
                  <button
                    onClick={() => handleDelete(z)}
                    style={actionBtn('#D64545')}
                  >
                    Delete
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {modal && (
        <ZoneModal
          mode={modal.mode}
          initial={modal.data}
          countries={countries}
          working={!!working.save}
          onClose={() => setModal(null)}
          onSave={handleSave}
        />
      )}
    </>
  );
}

function ZoneModal({ mode, initial, countries, working, onClose, onSave }) {
  const [form, setForm] = useState({
    name: initial?.name || '',
    slug: initial?.slug || '',
    countryCode: initial?.countryCode || countries[0]?.id || 'QA',
    order: initial?.order ?? 0,
    active: initial?.active ?? true,
  });

  return (
    <ModalShell
      title={mode === 'add' ? 'Add Zone' : 'Edit Zone'}
      onClose={onClose}
    >
      <Field label="Country *">
        <select
          value={form.countryCode}
          onChange={(e) => setForm({ ...form, countryCode: e.target.value })}
          style={inputStyle}
        >
          {countries.map((c) => (
            <option key={c.id} value={c.id}>
              {c.flag} {c.name}
            </option>
          ))}
        </select>
      </Field>
      <Field label="Name *">
        <input
          value={form.name}
          onChange={(e) => setForm({ ...form, name: e.target.value })}
          placeholder="Doha Metro"
          style={inputStyle}
        />
      </Field>
      <Field label="Slug (optional — auto from name)">
        <input
          value={form.slug}
          onChange={(e) => setForm({ ...form, slug: e.target.value })}
          placeholder="doha-metro"
          style={inputStyle}
        />
      </Field>
      <Field label="Display Order">
        <input
          type="number"
          value={form.order}
          onChange={(e) => setForm({ ...form, order: e.target.value })}
          style={inputStyle}
        />
      </Field>
      <ActiveToggle
        checked={form.active}
        onChange={(v) => setForm({ ...form, active: v })}
      />
      <ModalActions
        onCancel={onClose}
        onSave={() => onSave(form)}
        working={working}
        isEdit={mode === 'edit'}
      />
    </ModalShell>
  );
}

// ============================================================
// AREAS TAB
// ============================================================
function AreasTab({ isMobile }) {
  const [areas, setAreas] = useState([]);
  const [zones, setZones] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filterZone, setFilterZone] = useState('all');
  const [modal, setModal] = useState(null);
  const [working, setWorking] = useState({});

  useEffect(() => {
    const unsub1 = onSnapshot(collection(db, 'areas'), (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      list.sort((a, b) => (a.order ?? 0) - (b.order ?? 0));
      setAreas(list);
      setLoading(false);
    });
    const unsub2 = onSnapshot(collection(db, 'zones'), (snap) => {
      setZones(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
    });
    return () => {
      unsub1();
      unsub2();
    };
  }, []);

  const filtered = useMemo(() => {
    if (filterZone === 'all') return areas;
    return areas.filter((a) => a.zoneSlug === filterZone);
  }, [areas, filterZone]);

  async function handleSave(form) {
    setWorking({ save: true });
    try {
      const slug = (form.slug || form.name)
        .toLowerCase()
        .trim()
        .replace(/\s+/g, '-');
      if (!slug) throw new Error('Slug/name required');

      await setDoc(
        doc(db, 'areas', slug),
        {
          zoneSlug: form.zoneSlug,
          name: form.name.trim(),
          slug,
          agencyUid: form.agencyUid || null,
          order: Number(form.order) || 0,
          active: form.active !== false,
          updatedAt: serverTimestamp(),
          ...(modal.mode === 'add' && { createdAt: serverTimestamp() }),
        },
        { merge: true },
      );
      setModal(null);
    } catch (e) {
      alert('Failed: ' + e.message);
    } finally {
      setWorking({});
    }
  }

  async function handleToggle(a) {
    try {
      await updateDoc(doc(db, 'areas', a.id), {
        active: !a.active,
        updatedAt: serverTimestamp(),
      });
    } catch (e) {
      alert('Failed: ' + e.message);
    }
  }

  async function handleDelete(a) {
    if (!window.confirm(`Delete area "${a.name}"?`)) return;
    try {
      await deleteDoc(doc(db, 'areas', a.id));
    } catch (e) {
      alert('Failed: ' + e.message);
    }
  }

  if (loading) return <div style={{ color: '#6B7280' }}>Loading…</div>;

  return (
    <>
      <div
        style={{
          display: 'flex',
          gap: 10,
          marginBottom: 12,
          flexWrap: 'wrap',
          justifyContent: 'space-between',
        }}
      >
        <select
          value={filterZone}
          onChange={(e) => setFilterZone(e.target.value)}
          style={{ ...inputStyle, maxWidth: 220 }}
        >
          <option value="all">All Zones</option>
          {zones.map((z) => (
            <option key={z.id} value={z.id}>
              {z.name}
            </option>
          ))}
        </select>
        <button onClick={() => setModal({ mode: 'add' })} style={addBtnStyle}>
          + Add Area
        </button>
      </div>

      {filtered.length === 0 ? (
        <EmptyBox text="No areas yet." />
      ) : (
        <div style={cardContainerStyle}>
          {filtered.map((a, i) => (
            <div
              key={a.id}
              style={{
                ...rowStyle(isMobile, '2fr 1fr 1fr 1fr 180px'),
                borderBottom:
                  i < filtered.length - 1 ? '1px solid #F1EEEA' : 'none',
              }}
            >
              <div>
                <div style={primaryTextStyle}>{a.name}</div>
                <div style={secondaryTextStyle}>{a.slug}</div>
              </div>
              <div style={secondaryTextStyle}>{a.zoneSlug}</div>
              <div style={secondaryTextStyle}>
                {a.agencyUid ? '✅ Assigned' : '—'}
              </div>
              <div>
                <StatusBadge active={a.active} />
              </div>
              <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                <button
                  onClick={() => setModal({ mode: 'edit', data: a })}
                  style={actionBtn('#1E4B8F')}
                >
                  Edit
                </button>
                <button
                  onClick={() => handleToggle(a)}
                  style={actionBtn(a.active ? '#A67920' : '#2E9E5B')}
                >
                  {a.active ? 'Hide' : 'Show'}
                </button>
                <button
                  onClick={() => handleDelete(a)}
                  style={actionBtn('#D64545')}
                >
                  Delete
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {modal && (
        <AreaModal
          mode={modal.mode}
          initial={modal.data}
          zones={zones}
          working={!!working.save}
          onClose={() => setModal(null)}
          onSave={handleSave}
        />
      )}
    </>
  );
}

function AreaModal({ mode, initial, zones, working, onClose, onSave }) {
  const [form, setForm] = useState({
    name: initial?.name || '',
    slug: initial?.slug || '',
    zoneSlug: initial?.zoneSlug || zones[0]?.id || '',
    order: initial?.order ?? 0,
    active: initial?.active ?? true,
  });

  return (
    <ModalShell
      title={mode === 'add' ? 'Add Area' : 'Edit Area'}
      onClose={onClose}
    >
      <Field label="Zone *">
        <select
          value={form.zoneSlug}
          onChange={(e) => setForm({ ...form, zoneSlug: e.target.value })}
          style={inputStyle}
        >
          {zones.map((z) => (
            <option key={z.id} value={z.id}>
              {z.name}
            </option>
          ))}
        </select>
      </Field>
      <Field label="Name *">
        <input
          value={form.name}
          onChange={(e) => setForm({ ...form, name: e.target.value })}
          placeholder="The Pearl"
          style={inputStyle}
        />
      </Field>
      <Field label="Slug (optional — auto from name)">
        <input
          value={form.slug}
          onChange={(e) => setForm({ ...form, slug: e.target.value })}
          placeholder="the-pearl"
          style={inputStyle}
        />
      </Field>
      <Field label="Display Order">
        <input
          type="number"
          value={form.order}
          onChange={(e) => setForm({ ...form, order: e.target.value })}
          style={inputStyle}
        />
      </Field>
      <ActiveToggle
        checked={form.active}
        onChange={(v) => setForm({ ...form, active: v })}
      />
      <ModalActions
        onCancel={onClose}
        onSave={() => onSave(form)}
        working={working}
        isEdit={mode === 'edit'}
      />
    </ModalShell>
  );
}

// ============================================================
// AGENCIES TAB
// ============================================================
function AgenciesTab({ isMobile }) {
  const [agencies, setAgencies] = useState([]);
  const [areas, setAreas] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(null);
  const [working, setWorking] = useState({});

  useEffect(() => {
    const unsub1 = onSnapshot(collection(db, 'agencies'), (snap) => {
      const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      setAgencies(list);
      setLoading(false);
    });
    const unsub2 = onSnapshot(collection(db, 'areas'), (snap) => {
      setAreas(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
    });
    return () => {
      unsub1();
      unsub2();
    };
  }, []);

  async function handleSave(form) {
    setWorking({ save: true });
    try {
      const id = form.id || doc(collection(db, 'agencies')).id;
      await setDoc(
        doc(db, 'agencies', id),
        {
          ownerUid: form.ownerUid.trim(),
          name: form.name.trim(),
          email: form.email?.trim() || null,
          phone: form.phone?.trim() || null,
          areaIds: form.areaIds || [],
          countryCode: form.countryCode || 'QA',
          zoneSlug: form.zoneSlug || null,
          revenueShare: Number(form.revenueShare) || 0.4,
          status: form.status || 'active',
          updatedAt: serverTimestamp(),
          ...(modal.mode === 'add' && {
            createdAt: serverTimestamp(),
          }),
        },
        { merge: true },
      );
      setModal(null);
    } catch (e) {
      alert('Failed: ' + e.message);
    } finally {
      setWorking({});
    }
  }

  async function handleDelete(a) {
    if (!window.confirm(`Delete agency "${a.name}"?`)) return;
    try {
      await deleteDoc(doc(db, 'agencies', a.id));
    } catch (e) {
      alert('Failed: ' + e.message);
    }
  }

  if (loading) return <div style={{ color: '#6B7280' }}>Loading…</div>;

  return (
    <>
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 12 }}>
        <button onClick={() => setModal({ mode: 'add' })} style={addBtnStyle}>
          + Add Agency
        </button>
      </div>

      {agencies.length === 0 ? (
        <EmptyBox text="No agencies yet. Create an agency user first (Users → Roles → Agency)." />
      ) : (
        <div style={cardContainerStyle}>
          {agencies.map((a, i) => (
            <div
              key={a.id}
              style={{
                ...rowStyle(isMobile, '2fr 1fr 1fr 1fr 180px'),
                borderBottom:
                  i < agencies.length - 1 ? '1px solid #F1EEEA' : 'none',
              }}
            >
              <div>
                <div style={primaryTextStyle}>{a.name}</div>
                <div style={secondaryTextStyle}>
                  {a.email || a.ownerUid?.substring(0, 12)}
                </div>
              </div>
              <div style={secondaryTextStyle}>
                {a.areaIds?.length || 0} areas
              </div>
              <div style={secondaryTextStyle}>
                {Math.round((a.revenueShare ?? 0.4) * 100)}%
              </div>
              <div>
                <StatusBadge active={a.status === 'active'} />
              </div>
              <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                <button
                  onClick={() => setModal({ mode: 'edit', data: a })}
                  style={actionBtn('#1E4B8F')}
                >
                  Edit
                </button>
                <button
                  onClick={() => handleDelete(a)}
                  style={actionBtn('#D64545')}
                >
                  Delete
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {modal && (
        <AgencyModal
          mode={modal.mode}
          initial={modal.data}
          areas={areas}
          working={!!working.save}
          onClose={() => setModal(null)}
          onSave={handleSave}
        />
      )}
    </>
  );
}

function AgencyModal({ mode, initial, areas, working, onClose, onSave }) {
  const [form, setForm] = useState({
    id: initial?.id || '',
    ownerUid: initial?.ownerUid || '',
    name: initial?.name || '',
    email: initial?.email || '',
    phone: initial?.phone || '',
    areaIds: initial?.areaIds || [],
    countryCode: initial?.countryCode || 'QA',
    revenueShare: initial?.revenueShare ?? 0.4,
    status: initial?.status || 'active',
  });

  function toggleArea(slug) {
    const has = form.areaIds.includes(slug);
    setForm({
      ...form,
      areaIds: has
        ? form.areaIds.filter((s) => s !== slug)
        : [...form.areaIds, slug],
    });
  }

  return (
    <ModalShell
      title={mode === 'add' ? 'Add Agency' : 'Edit Agency'}
      onClose={onClose}
    >
      <Field label="Owner UID * (user with role=agency)">
        <input
          value={form.ownerUid}
          onChange={(e) => setForm({ ...form, ownerUid: e.target.value })}
          placeholder="Paste user UID from Users page"
          style={inputStyle}
        />
      </Field>
      <Field label="Agency Name *">
        <input
          value={form.name}
          onChange={(e) => setForm({ ...form, name: e.target.value })}
          placeholder="Pearl Franchise"
          style={inputStyle}
        />
      </Field>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        <Field label="Email">
          <input
            value={form.email}
            onChange={(e) => setForm({ ...form, email: e.target.value })}
            style={inputStyle}
          />
        </Field>
        <Field label="Phone">
          <input
            value={form.phone}
            onChange={(e) => setForm({ ...form, phone: e.target.value })}
            style={inputStyle}
          />
        </Field>
      </div>
      <Field label="Revenue Share (0-1, e.g. 0.40 = 40%)">
        <input
          type="number"
          step="0.05"
          value={form.revenueShare}
          onChange={(e) =>
            setForm({ ...form, revenueShare: e.target.value })
          }
          style={inputStyle}
        />
      </Field>
      <Field label={`Assigned Areas (${form.areaIds.length} selected)`}>
        <div
          style={{
            maxHeight: 180,
            overflowY: 'auto',
            border: '1px solid #E5E7EB',
            borderRadius: 10,
            padding: 8,
          }}
        >
          {areas.map((a) => {
            const checked = form.areaIds.includes(a.id);
            return (
              <label
                key={a.id}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                  padding: 6,
                  fontSize: 13,
                  cursor: 'pointer',
                }}
              >
                <input
                  type="checkbox"
                  checked={checked}
                  onChange={() => toggleArea(a.id)}
                />
                <span>
                  {a.name} <span style={{ color: '#9CA3AF' }}>({a.zoneSlug})</span>
                </span>
              </label>
            );
          })}
        </div>
      </Field>
      <Field label="Status">
        <select
          value={form.status}
          onChange={(e) => setForm({ ...form, status: e.target.value })}
          style={inputStyle}
        >
          <option value="active">Active</option>
          <option value="pending">Pending</option>
          <option value="suspended">Suspended</option>
        </select>
      </Field>
      <ModalActions
        onCancel={onClose}
        onSave={() => onSave(form)}
        working={working}
        isEdit={mode === 'edit'}
      />
    </ModalShell>
  );
}

// ============================================================
// SHARED UI
// ============================================================
function ModalShell({ title, children, onClose }) {
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
          padding: 24,
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
            marginBottom: 18,
            marginTop: 0,
          }}
        >
          {title}
        </h2>
        {children}
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
        }}
      >
        {label}
      </label>
      {children}
    </div>
  );
}

function ActiveToggle({ checked, onChange }) {
  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        marginBottom: 16,
      }}
    >
      <input
        type="checkbox"
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
        style={{ width: 18, height: 18 }}
      />
      <span style={{ fontSize: 14 }}>Show in app</span>
    </div>
  );
}

function ModalActions({ onCancel, onSave, working, isEdit }) {
  return (
    <div
      style={{
        display: 'flex',
        gap: 10,
        justifyContent: 'flex-end',
        marginTop: 12,
      }}
    >
      <button onClick={onCancel} style={cancelBtnStyle} disabled={working}>
        Cancel
      </button>
      <button onClick={onSave} style={saveBtnStyle} disabled={working}>
        {working ? 'Saving…' : isEdit ? 'Update' : 'Create'}
      </button>
    </div>
  );
}

function StatusBadge({ active }) {
  return (
    <span
      style={{
        display: 'inline-block',
        padding: '3px 10px',
        borderRadius: 6,
        background: active ? '#E5F5EA' : '#FEE2E2',
        color: active ? '#2E9E5B' : '#D64545',
        fontSize: 10,
        fontWeight: 800,
        textTransform: 'uppercase',
      }}
    >
      {active ? 'Active' : 'Hidden'}
    </span>
  );
}

function EmptyBox({ text }) {
  return (
    <div
      style={{
        background: 'white',
        borderRadius: 16,
        padding: 48,
        textAlign: 'center',
        color: '#6B7280',
      }}
    >
      {text}
    </div>
  );
}

// ---------- STYLES ----------
const cardContainerStyle = {
  background: 'white',
  borderRadius: 16,
  boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
  overflow: 'hidden',
};

const inputStyle = {
  width: '100%',
  padding: '10px 14px',
  borderRadius: 10,
  border: '1px solid #E5E7EB',
  fontSize: 14,
  outline: 'none',
  background: 'white',
  boxSizing: 'border-box',
};

const addBtnStyle = {
  padding: '10px 20px',
  borderRadius: 10,
  border: 'none',
  background: 'linear-gradient(135deg, #F0C566 0%, #D4A13A 100%)',
  color: '#0B2B5B',
  fontSize: 14,
  fontWeight: 800,
  cursor: 'pointer',
};

const cancelBtnStyle = {
  padding: '10px 20px',
  borderRadius: 8,
  border: '1px solid #E5E7EB',
  background: 'white',
  color: '#6B7280',
  fontSize: 14,
  fontWeight: 700,
  cursor: 'pointer',
};

const saveBtnStyle = {
  padding: '10px 24px',
  borderRadius: 8,
  border: 'none',
  background: 'linear-gradient(135deg, #F0C566 0%, #D4A13A 100%)',
  color: '#0B2B5B',
  fontSize: 14,
  fontWeight: 800,
  cursor: 'pointer',
};

const primaryTextStyle = {
  fontSize: 14,
  fontWeight: 800,
  color: '#0B2B5B',
  marginBottom: 2,
};

const secondaryTextStyle = {
  fontSize: 12,
  color: '#6B7280',
};

function rowStyle(isMobile, desktopGrid) {
  if (isMobile) {
    return {
      display: 'flex',
      flexDirection: 'column',
      gap: 10,
      padding: 16,
    };
  }
  return {
    display: 'grid',
    gridTemplateColumns: desktopGrid,
    alignItems: 'center',
    padding: '14px 20px',
    fontSize: 13,
    color: '#374151',
    gap: 12,
  };
}

function actionBtn(color) {
  return {
    padding: '6px 10px',
    borderRadius: 6,
    border: 'none',
    background: color + '15',
    color,
    fontSize: 11,
    fontWeight: 800,
    cursor: 'pointer',
  };
}