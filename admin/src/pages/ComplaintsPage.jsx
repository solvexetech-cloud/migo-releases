import { useState, useEffect } from 'react';
import { collection, query, onSnapshot, doc, updateDoc } from 'firebase/firestore';
import { db } from '../firebase';

export default function ComplaintsPage() {
  const [complaints, setComplaints] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('open'); // 'open', 'resolved', 'all'

  useEffect(() => {
    setLoading(true);
    const q = query(collection(db, 'community_complaints'));

    const unsubscribe = onSnapshot(q, (snapshot) => {
      let data = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
      
      // Sort by date (newest first)
      data.sort((a, b) => {
        const dateA = a.createdAt?.toMillis() || 0;
        const dateB = b.createdAt?.toMillis() || 0;
        return dateB - dateA;
      });
      
      if (filter !== 'all') {
        data = data.filter((d) => d.status === filter);
      }
      
      setComplaints(data);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [filter]);

  const handleStatusChange = async (complaintId, newStatus) => {
    try {
      await updateDoc(doc(db, 'community_complaints', complaintId), {
        status: newStatus,
      });
    } catch (error) {
      console.error('Error updating complaint status:', error);
      alert('Failed to update complaint status.');
    }
  };

  const getStatusColor = (status) => {
    switch(status) {
      case 'open': return { bg: '#FFF3E0', text: '#E65100' };
      case 'resolved': return { bg: '#E8F5E9', text: '#2E7D32' };
      default: return { bg: '#F5F5F5', text: '#616161' };
    }
  };

  return (
    <div style={{ padding: 24, fontFamily: 'sans-serif' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <h1 style={{ fontSize: 24, fontWeight: 800, color: '#0B2B5B', margin: 0 }}>Complaint Management</h1>
        
        <div style={{ display: 'flex', gap: 8 }}>
          {['open', 'resolved', 'all'].map((status) => (
            <button
              key={status}
              onClick={() => setFilter(status)}
              style={{
                padding: '8px 16px',
                borderRadius: 8,
                fontSize: 14,
                fontWeight: 700,
                textTransform: 'capitalize',
                cursor: 'pointer',
                border: filter === status ? 'none' : '1px solid #ccc',
                background: filter === status ? 'linear-gradient(135deg, #F0C566 0%, #D4A13A 100%)' : 'white',
                color: filter === status ? '#0B2B5B' : '#666',
                boxShadow: filter === status ? '0 4px 10px rgba(240,197,102,0.3)' : 'none',
              }}
            >
              {status}
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: 40, color: '#888' }}>Loading complaints...</div>
      ) : complaints.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 40, background: 'white', borderRadius: 12, border: '1px solid #eee', color: '#888' }}>
          No {filter} complaints found.
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: 16 }}>
          {complaints.map((c) => {
            const colors = getStatusColor(c.status);
            return (
              <div key={c.id} style={{ background: 'white', borderRadius: 12, padding: 20, boxShadow: '0 4px 20px rgba(0,0,0,0.05)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 }}>
                  <div>
                    <h3 style={{ margin: 0, fontSize: 16, fontWeight: 800, color: '#0B2B5B' }}>{c.category}</h3>
                    <p style={{ margin: '4px 0 0 0', fontSize: 12, color: '#888' }}>Business: {c.businessName}</p>
                  </div>
                  <span style={{
                    padding: '4px 12px',
                    borderRadius: 20,
                    fontSize: 12,
                    fontWeight: 700,
                    background: colors.bg,
                    color: colors.text,
                    textTransform: 'capitalize'
                  }}>
                    {c.status}
                  </span>
                </div>
                
                <p style={{ fontSize: 14, color: '#333', lineHeight: 1.5, marginBottom: 16 }}>{c.description}</p>
                
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <span style={{ fontSize: 12, color: '#aaa' }}>
                    {c.createdAt ? new Date(c.createdAt.toMillis()).toLocaleString() : 'N/A'}
                  </span>
                  
                  {c.status === 'open' && (
                    <button
                      onClick={() => handleStatusChange(c.id, 'resolved')}
                      style={{ background: '#4CAF50', color: 'white', border: 'none', padding: '8px 16px', borderRadius: 6, fontWeight: 700, fontSize: 12, cursor: 'pointer' }}
                    >
                      Mark as Resolved
                    </button>
                  )}
                  {c.status === 'resolved' && (
                    <button
                      onClick={() => handleStatusChange(c.id, 'open')}
                      style={{ background: '#F44336', color: 'white', border: 'none', padding: '8px 16px', borderRadius: 6, fontWeight: 700, fontSize: 12, cursor: 'pointer' }}
                    >
                      Reopen
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}