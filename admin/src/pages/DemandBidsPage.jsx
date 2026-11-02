import { useState, useEffect } from 'react';
import { collection, query, where, onSnapshot, doc, updateDoc } from 'firebase/firestore';
import { db } from '../firebase';

export default function DemandBidsPage() {
  const [bids, setBids] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('pending');

  useEffect(() => {
    setLoading(true);
    const q = query(
      collection(db, 'demand_bids'),
      where('status', '==', filter)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const bidsData = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
      bidsData.sort((a, b) => b.createdAt?.toMillis() - a.createdAt?.toMillis());
      setBids(bidsData);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [filter]);

  const handleAction = async (bidId, newStatus) => {
    try {
      await updateDoc(doc(db, 'demand_bids', bidId), {
        status: newStatus,
      });
    } catch (error) {
      console.error('Error updating bid status:', error);
      alert('Failed to update bid status.');
    }
  };

  return (
    <div style={{ padding: 24, fontFamily: 'sans-serif' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <h1 style={{ fontSize: 24, fontWeight: 800, color: '#0B2B5B', margin: 0 }}>Demand Bids Approvals</h1>
        
        <div style={{ display: 'flex', gap: 8 }}>
          {['pending', 'approved', 'rejected'].map((status) => (
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
        <div style={{ textAlign: 'center', padding: 40, color: '#888' }}>Loading bids...</div>
      ) : bids.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 40, background: 'white', borderRadius: 12, border: '1px solid #eee', color: '#888' }}>
          No {filter} bids found.
        </div>
      ) : (
        <div style={{ background: 'white', borderRadius: 12, boxShadow: '0 4px 20px rgba(0,0,0,0.05)', overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
            <thead style={{ background: '#F6F3EE', borderBottom: '2px solid #E0E0E0' }}>
              <tr>
                <th style={thStyle}>Date</th>
                <th style={thStyle}>Business</th>
                <th style={thStyle}>Offer Price</th>
                <th style={thStyle}>Authenticity</th>
                <th style={thStyle}>Fulfillment</th>
                <th style={thStyle}>Score</th>
                <th style={thStyle}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {bids.map((bid) => (
                <tr key={bid.id} style={{ borderBottom: '1px solid #eee' }}>
                  <td style={tdStyle}>
                    {bid.createdAt ? new Date(bid.createdAt.toMillis()).toLocaleString() : 'N/A'}
                  </td>
                  <td style={{ ...tdStyle, fontWeight: 700 }}>
                    {bid.businessName?.en || bid.businessName?.ar || 'Unknown Business'}
                  </td>
                  <td style={{ ...tdStyle, fontWeight: 800, color: '#0B2B5B' }}>
                    QAR {bid.offerPrice}
                  </td>
                  <td style={tdStyle}>
                    <span style={{
                      padding: '4px 8px',
                      borderRadius: 20,
                      fontSize: 12,
                      fontWeight: 700,
                      background: bid.authenticity === 'Original' ? '#E8F5E9' : '#FFF3E0',
                      color: bid.authenticity === 'Original' ? '#2E7D32' : '#E65100',
                    }}>
                      {bid.authenticity}
                    </span>
                  </td>
                  <td style={tdStyle}>
                    {bid.fulfillmentType}
                  </td>
                  <td style={{ ...tdStyle, fontWeight: 800 }}>
                    {bid.businessTrustScore?.toFixed(1) || 'N/A'}
                  </td>
                  <td style={tdStyle}>
                    {filter === 'pending' ? (
                      <div style={{ display: 'flex', gap: 8 }}>
                        <button
                          onClick={() => handleAction(bid.id, 'approved')}
                          style={{ background: '#4CAF50', color: 'white', border: 'none', padding: '6px 12px', borderRadius: 6, fontWeight: 700, fontSize: 12, cursor: 'pointer' }}
                        >
                          Approve
                        </button>
                        <button
                          onClick={() => handleAction(bid.id, 'rejected')}
                          style={{ background: '#F44336', color: 'white', border: 'none', padding: '6px 12px', borderRadius: 6, fontWeight: 700, fontSize: 12, cursor: 'pointer' }}
                        >
                          Reject
                        </button>
                      </div>
                    ) : (
                      <span style={{ color: '#aaa', fontStyle: 'italic' }}>No actions</span>
                    )}
                  </td>
                </tr>
              ))}
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