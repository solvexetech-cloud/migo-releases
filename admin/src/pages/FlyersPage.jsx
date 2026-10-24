import { useEffect, useState } from 'react';
import { db } from '../firebase';
import {
  collection,
  query,
  where,
  getDocs,
  getDoc,
  doc,
  updateDoc,
  deleteDoc,
} from 'firebase/firestore';

export default function FlyersPage() {
  const [flyers, setFlyers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [editingExpiry, setEditingExpiry] = useState(null);
  const [newExpiryDate, setNewExpiryDate] = useState('');

  // Viewers Dialog state
  const [viewersDialog, setViewersDialog] = useState(null); // { title, viewed, fullyRead }

  useEffect(() => {
    fetchFlyers();
  }, []);

  async function fetchFlyers() {
    setLoading(true);
    try {
      const q = query(collection(db, 'flyers'));
      const snapshot = await getDocs(q);
      const list = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
      list.sort((a, b) => {
        const aTime = a.createdAt?.seconds || 0;
        const bTime = b.createdAt?.seconds || 0;
        return bTime - aTime;
      });
      setFlyers(list);
    } catch (error) {
      console.error('Error fetching flyers:', error);
    } finally {
      setLoading(false);
    }
  }

  async function getViewerNames(uids) {
    if (!uids || !Array.isArray(uids) || uids.length === 0) return [];
    try {
      const names = [];
      for (const uid of uids) {
        if (typeof uid !== 'string') {
          names.push(String(uid));
          continue;
        }
        try {
          const userSnap = await getDoc(doc(db, 'users', uid));
          if (userSnap.exists()) {
            const userData = userSnap.data();
            const name = userData.displayName || userData.email || uid;
            names.push(name);
          } else {
            names.push(uid);
          }
        } catch (e) {
          names.push(uid);
        }
      }
      return names;
    } catch (error) {
      console.error('Error fetching user names:', error);
      return [];
    }
  }

  async function showViewers(flyer) {
    const viewed = await getViewerNames(flyer.viewedBy);
    const fullyRead = await getViewerNames(flyer.fullyViewedBy);
    setViewersDialog({
      title: flyer.title,
      viewed,
      fullyRead,
    });
  }

  async function handleApprove(id) {
    if (!window.confirm('Approve this flyer? It will be visible to customers.')) return;
    try {
      await updateDoc(doc(db, 'flyers', id), { status: 'approved' });
      alert('Flyer Approved! ✅');
      fetchFlyers();
    } catch (error) {
      console.error('Error approving flyer:', error);
    }
  }

  async function handleReject(id) {
    if (!window.confirm('Reject this flyer? It will NOT be visible to customers.')) return;
    try {
      await updateDoc(doc(db, 'flyers', id), { status: 'rejected' });
      alert('Flyer Rejected ❌');
      fetchFlyers();
    } catch (error) {
      console.error('Error rejecting flyer:', error);
    }
  }

  async function handleDelete(id) {
    if (!window.confirm('Delete this flyer permanently? This cannot be undone.')) return;
    try {
      await deleteDoc(doc(db, 'flyers', id));
      alert('Flyer Deleted 🗑️');
      fetchFlyers();
    } catch (error) {
      console.error('Error deleting flyer:', error);
    }
  }

  async function handleUpdateExpiry(id) {
    if (!newExpiryDate) {
      alert('Please select a date');
      return;
    }
    try {
      const dateObj = new Date(newExpiryDate);
      await updateDoc(doc(db, 'flyers', id), {
        endDate: {
          seconds: Math.floor(dateObj.getTime() / 1000),
          nanoseconds: 0,
        },
      });
      alert('Expiry date updated! ✅');
      setEditingExpiry(null);
      setNewExpiryDate('');
      fetchFlyers();
    } catch (error) {
      console.error('Error updating expiry:', error);
    }
  }

  function formatDate(timestamp) {
    if (!timestamp) return 'N/A';
    const date = timestamp.seconds
      ? new Date(timestamp.seconds * 1000)
      : new Date(timestamp);
    return date.toLocaleDateString('en-GB');
  }

  function getStatusStyle(status) {
    switch (status) {
      case 'approved':
        return { bg: '#D1FAE5', color: '#065F46', label: '✅ APPROVED' };
      case 'pending':
        return { bg: '#FEF3C7', color: '#92400E', label: '⏳ PENDING' };
      case 'rejected':
        return { bg: '#FEE2E2', color: '#991B1B', label: '❌ REJECTED' };
      default:
        return { bg: '#E5E7EB', color: '#374151', label: status?.toUpperCase() };
    }
  }

  return (
    <div style={{ padding: 24 }}>
      <h1 style={{ fontSize: 28, fontWeight: 800, marginBottom: 6, color: '#0B2B5B' }}>
        📄 Flyers Management
      </h1>
      <p style={{ color: '#666', marginBottom: 24 }}>
        Approve, reject, or manage all business flyers.
      </p>

      {loading ? (
        <p>Loading...</p>
      ) : flyers.length === 0 ? (
        <div style={{ padding: 40, textAlign: 'center', color: '#999' }}>
          <p style={{ fontSize: 48 }}>📭</p>
          <p>No flyers found.</p>
        </div>
      ) : (
        <div style={{ display: 'grid', gap: 16 }}>
          {flyers.map((flyer) => {
            const statusStyle = getStatusStyle(flyer.status);
            const isEditing = editingExpiry === flyer.id;

            return (
              <div
                key={flyer.id}
                style={{
                  background: 'white',
                  borderRadius: 12,
                  padding: 20,
                  boxShadow: '0 2px 8px rgba(0,0,0,0.06)',
                  border: '1px solid #E5E7EB',
                }}
              >
                {/* Header Row */}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div>
                    <h3 style={{ margin: 0, fontSize: 18, fontWeight: 800, color: '#0B2B5B' }}>
                      {flyer.title}
                    </h3>
                    <p style={{ margin: '4px 0', color: '#666', fontSize: 13 }}>
                      🏢 {flyer.businessName} · 📁 {flyer.category || 'General'}
                    </p>
                  </div>
                  <span
                    style={{
                      padding: '6px 12px',
                      borderRadius: 20,
                      background: statusStyle.bg,
                      color: statusStyle.color,
                      fontSize: 11,
                      fontWeight: 800,
                    }}
                  >
                    {statusStyle.label}
                  </span>
                </div>

                {/* Dates */}
                <div style={{ display: 'flex', gap: 24, marginTop: 12, fontSize: 13 }}>
                  <div>
                    <span style={{ color: '#999' }}>Start: </span>
                    <strong>{formatDate(flyer.startDate)}</strong>
                  </div>
                  <div>
                    <span style={{ color: '#999' }}>Expires: </span>
                    <strong>{formatDate(flyer.endDate)}</strong>
                  </div>
                </div>

                {/* Views Tracking */}
                <div style={{ display: 'flex', gap: 24, marginTop: 8, fontSize: 13 }}>
                  <div>
                    <span style={{ color: '#999' }}>👁️ Views: </span>
                    <strong>{flyer.viewedBy?.length || 0}</strong>
                  </div>
                  <div>
                    <span style={{ color: '#999' }}>✅ Fully Read: </span>
                    <strong>{flyer.fullyViewedBy?.length || 0}</strong>
                  </div>
                </div>

                {/* Expiry Edit Row */}
                {isEditing && (
                  <div style={{ marginTop: 12, display: 'flex', gap: 8, alignItems: 'center' }}>
                    <input
                      type="date"
                      value={newExpiryDate}
                      onChange={(e) => setNewExpiryDate(e.target.value)}
                      style={{ padding: 8, borderRadius: 6, border: '1px solid #ccc' }}
                    />
                    <button
                      onClick={() => handleUpdateExpiry(flyer.id)}
                      style={{
                        padding: '8px 16px',
                        background: '#0B2B5B',
                        color: 'white',
                        border: 'none',
                        borderRadius: 6,
                        cursor: 'pointer',
                        fontWeight: 700,
                      }}
                    >
                      Save
                    </button>
                    <button
                      onClick={() => {
                        setEditingExpiry(null);
                        setNewExpiryDate('');
                      }}
                      style={{
                        padding: '8px 16px',
                        background: '#E5E7EB',
                        color: '#333',
                        border: 'none',
                        borderRadius: 6,
                        cursor: 'pointer',
                      }}
                    >
                      Cancel
                    </button>
                  </div>
                )}

                {/* Actions */}
                <div style={{ display: 'flex', gap: 8, marginTop: 16, flexWrap: 'wrap' }}>
                  <a
                    href={flyer.pdfUrl}
                    target="_blank"
                    rel="noreferrer"
                    style={{
                      padding: '8px 16px',
                      background: '#E0E7FF',
                      color: '#3730A3',
                      borderRadius: 6,
                      textDecoration: 'none',
                      fontSize: 13,
                      fontWeight: 700,
                    }}
                  >
                    👁️ View PDF
                  </a>

                  {flyer.status !== 'approved' && (
                    <button
                      onClick={() => handleApprove(flyer.id)}
                      style={{
                        padding: '8px 16px',
                        background: '#10B981',
                        color: 'white',
                        border: 'none',
                        borderRadius: 6,
                        cursor: 'pointer',
                        fontWeight: 700,
                        fontSize: 13,
                      }}
                    >
                      ✅ Approve
                    </button>
                  )}

                  {flyer.status !== 'rejected' && (
                    <button
                      onClick={() => handleReject(flyer.id)}
                      style={{
                        padding: '8px 16px',
                        background: '#EF4444',
                        color: 'white',
                        border: 'none',
                        borderRadius: 6,
                        cursor: 'pointer',
                        fontWeight: 700,
                        fontSize: 13,
                      }}
                    >
                      ❌ Reject
                    </button>
                  )}

                  <button
                    onClick={() => {
                      setEditingExpiry(flyer.id);
                      setNewExpiryDate('');
                    }}
                    style={{
                      padding: '8px 16px',
                      background: '#F59E0B',
                      color: 'white',
                      border: 'none',
                      borderRadius: 6,
                      cursor: 'pointer',
                      fontWeight: 700,
                      fontSize: 13,
                    }}
                  >
                    📅 Edit Expiry
                  </button>

                  <button
                    onClick={() => handleDelete(flyer.id)}
                    style={{
                      padding: '8px 16px',
                      background: '#6B7280',
                      color: 'white',
                      border: 'none',
                      borderRadius: 6,
                      cursor: 'pointer',
                      fontWeight: 700,
                      fontSize: 13,
                    }}
                  >
                    🗑️ Delete
                  </button>

                  <button
                    onClick={() => showViewers(flyer)}
                    style={{
                      padding: '8px 16px',
                      background: '#3B82F6',
                      color: 'white',
                      border: 'none',
                      borderRadius: 6,
                      cursor: 'pointer',
                      fontWeight: 700,
                      fontSize: 13,
                    }}
                  >
                    👥 Viewers
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Viewers Dialog */}
      {viewersDialog && (
        <div
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: 'rgba(0,0,0,0.5)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1000,
          }}
          onClick={() => setViewersDialog(null)}
        >
          <div
            style={{
              background: 'white',
              borderRadius: 12,
              padding: 24,
              maxWidth: 500,
              width: '90%',
              maxHeight: '80vh',
              overflowY: 'auto',
              boxShadow: '0 4px 20px rgba(0,0,0,0.15)',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <h2 style={{ fontSize: 20, fontWeight: 800, marginBottom: 16, color: '#0B2B5B' }}>
              👥 Viewers — {viewersDialog.title}
            </h2>

            <div style={{ marginBottom: 16 }}>
              <h3 style={{ fontSize: 14, fontWeight: 700, color: '#666', marginBottom: 8 }}>
                👁️ Viewed by ({viewersDialog.viewed.length})
              </h3>
              {viewersDialog.viewed.length === 0 ? (
                <p style={{ color: '#999', fontSize: 13 }}>No viewers yet.</p>
              ) : (
                <ul style={{ margin: 0, paddingLeft: 20 }}>
                  {viewersDialog.viewed.map((name, i) => (
                    <li key={i} style={{ fontSize: 13, marginBottom: 4 }}>{name}</li>
                  ))}
                </ul>
              )}
            </div>

            <div style={{ marginBottom: 16 }}>
              <h3 style={{ fontSize: 14, fontWeight: 700, color: '#666', marginBottom: 8 }}>
                ✅ Fully Read ({viewersDialog.fullyRead.length})
              </h3>
              {viewersDialog.fullyRead.length === 0 ? (
                <p style={{ color: '#999', fontSize: 13 }}>No one has fully read it yet.</p>
              ) : (
                <ul style={{ margin: 0, paddingLeft: 20 }}>
                  {viewersDialog.fullyRead.map((name, i) => (
                    <li key={i} style={{ fontSize: 13, marginBottom: 4 }}>{name}</li>
                  ))}
                </ul>
              )}
            </div>

            <button
              onClick={() => setViewersDialog(null)}
              style={{
                width: '100%',
                padding: '10px 16px',
                background: '#0B2B5B',
                color: 'white',
                border: 'none',
                borderRadius: 6,
                cursor: 'pointer',
                fontWeight: 700,
                fontSize: 14,
              }}
            >
              Close
            </button>
          </div>
        </div>
      )}
    </div>
  );
}