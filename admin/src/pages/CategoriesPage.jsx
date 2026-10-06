import { useEffect, useState } from 'react';
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

// Icon options — must match CategoryModel.iconData switch in Flutter
const ICON_OPTIONS = [
  { value: 'restaurant_outlined', label: '🍽️ Restaurant (Food)' },
  { value: 'local_cafe_outlined', label: '☕ Cafe (Coffee)' },
  { value: 'local_pizza_outlined', label: '🍕 Pizza' },
  { value: 'bakery_dining_outlined', label: '🥐 Bakery' },
  { value: 'icecream_outlined', label: '🍦 Ice Cream' },
  { value: 'spa_outlined', label: '🌸 Spa (Beauty)' },
  { value: 'content_cut_outlined', label: '✂️ Salon' },
  { value: 'face_retouching_natural_outlined', label: '💅 Beauty' },
  { value: 'directions_car_outlined', label: '🚗 Auto' },
  { value: 'celebration_outlined', label: '🎉 Events' },
  { value: 'camera_alt_outlined', label: '📷 Photography' },
  { value: 'fitness_center_outlined', label: '💪 Fitness' },
  { value: 'shopping_bag_outlined', label: '🛍️ Shopping' },
  { value: 'school_outlined', label: '🎓 Education' },
  { value: 'home_repair_service_outlined', label: '🔧 Home Services' },
  { value: 'local_laundry_service_outlined', label: '🧺 Laundry' },
  { value: 'cleaning_services_outlined', label: '🧹 Cleaning' },
  { value: 'plumbing_outlined', label: '🔧 Plumbing' },
  { value: 'electrical_services_outlined', label: '⚡ Electrical' },
  { value: 'local_shipping_outlined', label: '🚚 Delivery' },
  { value: 'flight_outlined', label: '✈️ Travel' },
  { value: 'hotel_outlined', label: '🏨 Hotel' },
  { value: 'local_hospital_outlined', label: '🏥 Hospital' },
  { value: 'medication_outlined', label: '💊 Pharmacy' },
  { value: 'pets_outlined', label: '🐾 Pets' },
  { value: 'child_care_outlined', label: '👶 Kids' },
  { value: 'sports_soccer_outlined', label: '⚽ Sports' },
  { value: 'self_improvement_outlined', label: '🧘 Yoga' },
  { value: 'book_outlined', label: '📚 Books' },
  { value: 'computer_outlined', label: '💻 Computers' },
  { value: 'phone_iphone_outlined', label: '📱 Mobiles' },
  { value: 'checkroom_outlined', label: '👕 Fashion' },
  { value: 'watch_outlined', label: '⌚ Watches' },
  { value: 'diamond_outlined', label: '💎 Jewelry' },
  { value: 'local_florist_outlined', label: '💐 Flowers' },
  { value: 'event_outlined', label: '📅 Events' },
  { value: 'music_note_outlined', label: '🎵 Music' },
  { value: 'movie_outlined', label: '🎬 Movies' },
  { value: 'sports_esports_outlined', label: '🎮 Gaming' },
  { value: 'toys_outlined', label: '🧸 Toys' },
  { value: 'category_outlined', label: '📦 Other' },
];

const EMPTY_FORM = {
  name: '',
  icon: 'restaurant_outlined',
  order: 10,
  active: true,
};

export default function CategoriesPage() {
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [form, setForm] = useState(EMPTY_FORM);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    const q = query(
      collection(db, 'categories'),
      orderBy('order', 'asc'),
    );
    const unsub = onSnapshot(
      q,
      (snap) => {
        const list = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
        setCategories(list);
        setLoading(false);
      },
      (err) => {
        console.error('Firestore error:', err);
        setLoading(false);
      },
    );
    return () => unsub();
  }, []);

  function openAdd() {
    setEditingId(null);
    setForm(EMPTY_FORM);
    setError('');
    setShowModal(true);
  }

  function openEdit(cat) {
    setEditingId(cat.id);
    setForm({
      name: cat.name || '',
      icon: cat.icon || 'restaurant_outlined',
      order: cat.order ?? 10,
      active: cat.active ?? true,
    });
    setError('');
    setShowModal(true);
  }

  async function handleSave() {
    if (!form.name.trim()) {
      setError('Name is required');
      return;
    }

    setSaving(true);
    setError('');

    try {
      if (editingId) {
        // Update existing
        await updateDoc(doc(db, 'categories', editingId), {
          name: form.name.trim(),
          icon: form.icon,
          order: Number(form.order) || 10,
          active: form.active,
          updatedAt: serverTimestamp(),
        });
      } else {
        // Add new — use slugified doc ID
        const docId = form.name
          .trim()
          .toLowerCase()
          .replace(/\s+/g, '-');
        await addDoc(collection(db, 'categories'), {
          name: form.name.trim(),
          icon: form.icon,
          order: Number(form.order) || 10,
          active: form.active,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        });
      }
      setShowModal(false);
    } catch (e) {
      console.error('Save error:', e);
      setError(e.message || 'Failed to save');
    } finally {
      setSaving(false);
    }
  }

  async function handleToggleActive(cat) {
    try {
      await updateDoc(doc(db, 'categories', cat.id), {
        active: !cat.active,
        updatedAt: serverTimestamp(),
      });
    } catch (e) {
      alert('Failed to toggle: ' + e.message);
    }
  }

  async function handleDelete(cat) {
    if (
      !window.confirm(
        `Delete "${cat.name}"? This cannot be undone.`,
      )
    ) {
      return;
    }
    try {
      await deleteDoc(doc(db, 'categories', cat.id));
    } catch (e) {
      alert('Failed to delete: ' + e.message);
    }
  }

  return (
    <div style={{ padding: 32, maxWidth: 1200 }}>
      <header
        style={{
          marginBottom: 24,
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
            Categories
          </h1>
          <p style={{ fontSize: 14, color: '#6B7280' }}>
            {categories.length} categor
            {categories.length !== 1 ? 'ies' : 'y'} on MIGO.
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
          + Add Category
        </button>
      </header>

      {loading ? (
        <div style={{ color: '#6B7280' }}>Loading…</div>
      ) : categories.length === 0 ? (
        <div
          style={{
            background: 'white',
            borderRadius: 16,
            padding: 48,
            textAlign: 'center',
            color: '#6B7280',
          }}
        >
          No categories yet. Click "Add Category" to create one.
        </div>
      ) : (
        <div
          style={{
            background: 'white',
            borderRadius: 16,
            boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
            overflow: 'hidden',
          }}
        >
          {/* Header row */}
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: '60px 2fr 1fr 80px 100px 180px',
              padding: '14px 20px',
              background: '#F6F3EE',
              fontSize: 11,
              fontWeight: 800,
              color: '#6B7280',
              letterSpacing: 0.5,
              borderBottom: '1px solid #ECE7DE',
            }}
          >
            <div>ICON</div>
            <div>NAME</div>
            <div>ICON KEY</div>
            <div>ORDER</div>
            <div>STATUS</div>
            <div>ACTIONS</div>
          </div>

          {/* Data rows */}
          {categories.map((c, i) => (
            <div
              key={c.id}
              style={{
                display: 'grid',
                gridTemplateColumns: '60px 2fr 1fr 80px 100px 180px',
                padding: '14px 20px',
                fontSize: 13,
                color: '#374151',
                borderBottom:
                  i < categories.length - 1
                    ? '1px solid #F1EEEA'
                    : 'none',
                alignItems: 'center',
              }}
            >
              <div>
                <span style={{ fontSize: 20 }}>
                  {getEmojiForIcon(c.icon)}
                </span>
              </div>

              <div
                style={{
                  fontWeight: 800,
                  color: '#0B2B5B',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  whiteSpace: 'nowrap',
                }}
              >
                {c.name}
              </div>

              <div
                style={{
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: '#6B7280',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  whiteSpace: 'nowrap',
                }}
              >
                {c.icon}
              </div>

              <div style={{ fontWeight: 700 }}>{c.order ?? 0}</div>

              <div>
                <span
                  style={{
                    display: 'inline-block',
                    padding: '3px 10px',
                    borderRadius: 6,
                    background: c.active ? '#E5F5EA' : '#FEE2E2',
                    color: c.active ? '#2E9E5B' : '#D64545',
                    fontSize: 10,
                    fontWeight: 800,
                    letterSpacing: 0.5,
                    textTransform: 'uppercase',
                  }}
                >
                  {c.active ? 'Active' : 'Hidden'}
                </span>
              </div>

              <div style={{ display: 'flex', gap: 6 }}>
                <button
                  onClick={() => openEdit(c)}
                  style={actionBtn('#1E4B8F')}
                >
                  Edit
                </button>
                <button
                  onClick={() => handleToggleActive(c)}
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

      {/* Modal */}
      {showModal && (
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
          onClick={() => !saving && setShowModal(false)}
        >
          <div
            onClick={(e) => e.stopPropagation()}
            style={{
              background: 'white',
              borderRadius: 16,
              padding: 28,
              maxWidth: 480,
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
              {editingId ? 'Edit Category' : 'Add Category'}
            </h2>

            <div style={{ marginBottom: 16 }}>
              <label style={labelStyle}>Name *</label>
              <input
                type="text"
                value={form.name}
                onChange={(e) =>
                  setForm({ ...form, name: e.target.value })
                }
                placeholder="e.g., Restaurants"
                style={inputStyle}
                autoFocus
              />
            </div>

            <div style={{ marginBottom: 16 }}>
              <label style={labelStyle}>Icon</label>
              <select
                value={form.icon}
                onChange={(e) =>
                  setForm({ ...form, icon: e.target.value })
                }
                style={inputStyle}
              >
                {ICON_OPTIONS.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label}
                  </option>
                ))}
              </select>
            </div>

            <div style={{ marginBottom: 16 }}>
              <label style={labelStyle}>Display Order</label>
              <input
                type="number"
                value={form.order}
                onChange={(e) =>
                  setForm({ ...form, order: e.target.value })
                }
                style={inputStyle}
              />
              <div
                style={{
                  fontSize: 11,
                  color: '#9CA3AF',
                  marginTop: 4,
                }}
              >
                Lower numbers appear first (1, 2, 3…)
              </div>
            </div>

            <div
              style={{
                marginBottom: 20,
                display: 'flex',
                alignItems: 'center',
                gap: 10,
              }}
            >
              <input
                id="active-toggle"
                type="checkbox"
                checked={form.active}
                onChange={(e) =>
                  setForm({ ...form, active: e.target.checked })
                }
                style={{ width: 18, height: 18 }}
              />
              <label
                htmlFor="active-toggle"
                style={{ fontSize: 14, color: '#374151' }}
              >
                Show in app
              </label>
            </div>

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
                onClick={() => setShowModal(false)}
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
                onClick={handleSave}
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
      )}
    </div>
  );
}

// ---------- Helpers ----------

const labelStyle = {
  display: 'block',
  fontSize: 12,
  fontWeight: 800,
  color: '#374151',
  marginBottom: 6,
  letterSpacing: 0.3,
};

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

function actionBtn(color) {
  return {
    padding: '6px 10px',
    borderRadius: 6,
    border: 'none',
    background: color + '15',
    color: color,
    fontSize: 11,
    fontWeight: 800,
    cursor: 'pointer',
  };
}

function getEmojiForIcon(iconKey) {
  const found = ICON_OPTIONS.find((o) => o.value === iconKey);
  return found ? found.label.split(' ')[0] : '📦';
}