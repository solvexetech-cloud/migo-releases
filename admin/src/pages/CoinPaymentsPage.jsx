import { useEffect, useState } from 'react';
import { collection, onSnapshot, query, orderBy } from 'firebase/firestore';
import { db } from '../firebase';

export default function CoinPaymentsPage() {
  const [payments, setPayments] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const q = query(collection(db, 'coin_payments'), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(q, (snap) => {
      setPayments(snap.docs.map(d => ({ id: d.id, ...d.data() })));
      setLoading(false);
    });
    return () => unsub();
  }, []);

  if (loading) return <div style={{ padding: 24 }}>Loading...</div>;

  return (
    <div style={{ padding: 24, maxWidth: 1400 }}>
      <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 20 }}>Coin Payments Report 💰</h1>
      
      <div style={{ overflowX: 'auto' }}>
        <table style={{ width: '100%', backgroundColor: 'white', borderRadius: 8, boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid #e5e7eb', backgroundColor: '#f9fafb' }}>
              <th style={{ padding: 12, textAlign: 'left' }}>Date</th>
              <th style={{ padding: 12, textAlign: 'left' }}>Customer</th>
              <th style={{ padding: 12, textAlign: 'left' }}>Offer</th> {/* 🆕 */}
              <th style={{ padding: 12, textAlign: 'left' }}>Business</th>
              <th style={{ padding: 12, textAlign: 'left' }}>Bill (QAR)</th>
              <th style={{ padding: 12, textAlign: 'left' }}>Coins Used</th>
              <th style={{ padding: 12, textAlign: 'left' }}>Status</th>
            </tr>
          </thead>
          <tbody>
            {payments.map(p => (
              <tr key={p.id} style={{ borderBottom: '1px solid #e5e7eb' }}>
                <td style={{ padding: 12 }}>{p.createdAt?.toDate().toLocaleString()}</td>
                <td style={{ padding: 12 }}>{p.userName} <br/><small style={{color: '#9ca3af'}}>{p.userEmail || ''}</small></td> {/* 🆕 ഇമെയിൽ */}
                <td style={{ padding: 12 }}>{p.offerTitle || '—'}</td> {/* 🆕 ഓഫർ */}
                <td style={{ padding: 12 }}>{p.businessName}</td>
                <td style={{ padding: 12 }}>{p.billAmount?.toFixed(2)}</td>
                <td style={{ padding: 12, fontWeight: 'bold', color: '#D4A13A' }}>{p.coinsUsed}</td>
                <td style={{ padding: 12 }}>
                  <span style={{
                    padding: '4px 8px', borderRadius: 4, fontSize: 12, fontWeight: 600,
                    backgroundColor: p.status === 'accepted' ? '#dcfce7' : '#fef9c3',
                    color: p.status === 'accepted' ? '#166534' : '#854d0e'
                  }}>
                    {p.status?.toUpperCase()}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}