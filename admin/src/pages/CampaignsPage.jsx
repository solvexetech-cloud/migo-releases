import { useState, useEffect } from 'react';
import { collection, query, onSnapshot, doc, updateDoc } from 'firebase/firestore';
import { db } from '../firebase';

export default function CampaignsPage() {
  const [campaigns, setCampaigns] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all'); // 'all', 'open', 'threshold_reached', 'locked'

  useEffect(() => {
    setLoading(true);
    // Fetch all demands, then sort in memory to avoid index errors
    const q = query(collection(db, 'demands'));

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
      
      setCampaigns(data);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [filter]);

  const handleAction = async (demandId, newStatus) => {
    try {
      await updateDoc(doc(db, 'demands', demandId), { status: newStatus });
    } catch (error) {
      console.error('Error updating campaign:', error);
      alert('Failed to update campaign status.');
    }
  };

  const getStatusColor = (status) => {
    switch(status) {
      case 'open': return { bg: '#FFF3E0', text: '#E65100' };
      case 'threshold_reached': return { bg: '#E8F5E9', text: '#2E7D32' };
      case 'locked': return { bg: '#E3F2FD', text: '#0D47A1' };
      default: return { bg: '#F5F5F5', text: '#616161' };
    }
  };

  return (
    <div style={{ padding: 24, fontFamily: 'sans-serif' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <h1 style={{ fontSize: 24, fontWeight: 800, color: '#0B2B5B', margin: 0 }}>Campaign Management</h1>
        
        <div style={{ display: 'flex', gap: 8 }}>
          {['all', 'open', 'threshold_reached', 'locked'].map((status) => (
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
              {status.replace('_', ' ')}
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: 40, color: '#888' }}>Loading campaigns...</div>
      ) : campaigns.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 40, background: 'white', borderRadius: 12, border: '1px solid #eee', color: '#888' }}>
          No campaigns found for this filter.
        </div>
      ) : (
        <div style={{ background: 'white', borderRadius: 12, boxShadow: '0 4px 20px rgba(0,0,0,0.05)', overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
            <thead style={{ background: '#F6F3EE', borderBottom: '2px solid #E0E0E0' }}>
              <tr>
                <th style={thStyle}>Product</th>
                <th style={thStyle}>Target Price</th>
                <th style={thStyle}>Progress</th>
                <th style={thStyle}>Status</th>
                <th style={thStyle}>Created At</th>
                <th style={thStyle}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {campaigns.map((c) => {
                const colors = getStatusColor(c.status);
                const productName = c.title?.en || c.title?.ar || 'Unknown Product';
                return (
                  <tr key={c.id} style={{ borderBottom: '1px solid #eee' }}>
                    <td style={{ ...tdStyle, fontWeight: 700 }}>{productName}</td>
                    <td style={{ ...tdStyle, fontWeight: 800, color: '#0B2B5B' }}>
                      {c.currency} {c.targetPrice}
                    </td>
                    <td style={tdStyle}>
                      {c.currentCount} / {c.requiredCount}
                    </td>
                    <td style={tdStyle}>
                      <span style={{
                        padding: '4px 8px',
                        borderRadius: 20,
                        fontSize: 12,
                        fontWeight: 700,
                        background: colors.bg,
                        color: colors.text,
                        textTransform: 'capitalize'
                      }}>
                        {c.status.replace('_', ' ')}
                      </span>
                    </td>
                    <td style={tdStyle}>
                      {c.createdAt ? new Date(c.createdAt.toMillis()).toLocaleString() : 'N/A'}
                    </td>
                    <td style={tdStyle}>
                      {c.status === 'open' && (
                        <button
                          onClick={() => handleAction(c.id, 'threshold_reached')}
                          style={{ background: '#4CAF50', color: 'white', border: 'none', padding: '6px 12px', borderRadius: 6, fontWeight: 700, fontSize: 12, cursor: 'pointer' }}
                        >
                          Force Activate
                        </button>
                      )}
                      {c.status === 'threshold_reached' && (
                        <button
                          onClick={() => handleAction(c.id, 'locked')}
                          style={{ background: '#F44336', color: 'white', border: 'none', padding: '6px 12px', borderRadius: 6, fontWeight: 700, fontSize: 12, cursor: 'pointer' }}
                        >
                          Close Bidding
                        </button>
                      )}
                      {c.status === 'locked' && (
                        <span style={{ color: '#aaa', fontStyle: 'italic' }}>Completed</span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

const thStyle = {
  padding: '16px',
  fontSize: 12,
  fontWeight: 800,
  color: '#555',
  textTransform: 'uppercase',
};

const tdStyle = {
  padding: '16px',
  fontSize: 14,
  color: '#333',
};