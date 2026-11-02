import { useState, useEffect } from 'react';
import { collection, query, onSnapshot, doc, updateDoc } from 'firebase/firestore';
import { db } from '../firebase';

export default function OrdersPage() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('locked'); // 'locked', 'redeemed'

  useEffect(() => {
    setLoading(true);
    const q = query(collection(db, 'demand_claims'));

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
      
      setOrders(data);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [filter]);

  const getStatusColor = (status) => {
    switch(status) {
      case 'locked': return { bg: '#E3F2FD', text: '#0D47A1' };
      case 'redeemed': return { bg: '#E8F5E9', text: '#2E7D32' };
      default: return { bg: '#F5F5F5', text: '#616161' };
    }
  };

  return (
    <div style={{ padding: 24, fontFamily: 'sans-serif' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <h1 style={{ fontSize: 24, fontWeight: 800, color: '#0B2B5B', margin: 0 }}>Order Management</h1>
        
        <div style={{ display: 'flex', gap: 8 }}>
          {['locked', 'redeemed'].map((status) => (
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
        <div style={{ textAlign: 'center', padding: 40, color: '#888' }}>Loading orders...</div>
      ) : orders.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 40, background: 'white', borderRadius: 12, border: '1px solid #eee', color: '#888' }}>
          No {filter} orders found.
        </div>
      ) : (
        <div style={{ background: 'white', borderRadius: 12, boxShadow: '0 4px 20px rgba(0,0,0,0.05)', overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
            <thead style={{ background: '#F6F3EE', borderBottom: '2px solid #E0E0E0' }}>
              <tr>
                <th style={thStyle}>Business</th>
                <th style={thStyle}>Product</th>
                <th style={thStyle}>Final Price</th>
                <th style={thStyle}>Fulfillment</th>
                <th style={thStyle}>Status</th>
                <th style={thStyle}>Order Date</th>
              </tr>
            </thead>
            <tbody>
              {orders.map((o) => {
                const colors = getStatusColor(o.status);
                return (
                  <tr key={o.id} style={{ borderBottom: '1px solid #eee' }}>
                    <td style={{ ...tdStyle, fontWeight: 700 }}>
                      {o.businessName?.en || o.businessName?.ar || 'Unknown Business'}
                    </td>
                    <td style={{ ...tdStyle, fontWeight: 600 }}>
                      {o.demandId ? 'Demand' : 'N/A'}
                    </td>
                    <td style={{ ...tdStyle, fontWeight: 800, color: '#0B2B5B' }}>
                      {o.finalPrice} QAR
                    </td>
                    <td style={tdStyle}>
                      {o.fulfillmentType}
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
                        {o.status}
                      </span>
                    </td>
                    <td style={tdStyle}>
                      {o.createdAt ? new Date(o.createdAt.toMillis()).toLocaleString() : 'N/A'}
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