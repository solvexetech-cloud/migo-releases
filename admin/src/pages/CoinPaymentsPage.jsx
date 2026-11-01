import { useEffect, useState } from 'react';
import { collection, onSnapshot, query, orderBy, doc, updateDoc, runTransaction, serverTimestamp, increment } from 'firebase/firestore';
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

  // Approve / Reject ഫംഗ്ഷൻ
  const handleStatusChange = async (paymentId, newStatus) => {
    if (!window.confirm(`Are you sure you want to ${newStatus} this payment?`)) return;
    try {
      const paymentRef = doc(db, 'coin_payments', paymentId);

      if (newStatus === 'accepted') {
        // Firestore Transaction ഉപയോഗിച്ച് കോയിൻ കുറയ്ക്കുന്നു
        await runTransaction(db, async (transaction) => {
          const paymentDoc = await transaction.get(paymentRef);
          if (!paymentDoc.exists()) throw new Error("Payment not found");
          const data = paymentDoc.data();
          if (data.status !== 'pending') throw new Error("Already processed");

          const customerUid = data.userId;
          const coinsUsed = data.coinsUsed;
          const userRef = doc(db, 'users', customerUid);

          // 1. പേയ്‌മെന്റ് സ്റ്റാറ്റസ് അപ്ഡേറ്റ് ചെയ്യുന്നു
          transaction.update(paymentRef, {
            status: 'accepted',
            acceptedAt: serverTimestamp(),
          });

          // 2. കസ്റ്റമറുടെ കോയിൻ കുറയ്ക്കുന്നു
          transaction.update(userRef, {
            coins: increment(-coinsUsed),
            updatedAt: serverTimestamp(),
          });

          // 3. കോയിൻ ട്രാൻസാക്ഷൻ ലോഗ് ചെയ്യുന്നു
          const txRef = doc(collection(db, 'coin_transactions'));
          transaction.set(txRef, {
            uid: customerUid,
            amount: -coinsUsed,
            type: 'spent',
            description: `Paid at business (ID: ${data.businessId})`,
            createdAt: serverTimestamp(),
          });
        });
        alert('Payment accepted successfully!');
      } else {
        // Reject ചെയ്യുമ്പോൾ സ്റ്റാറ്റസ് മാത്രം മാറ്റുന്നു
        await updateDoc(paymentRef, { status: 'rejected' });
        alert('Payment rejected.');
      }
    } catch (error) {
      alert('Error updating status: ' + error.message);
    }
  };

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
              <th style={{ padding: 12, textAlign: 'left' }}>Offer</th>
              <th style={{ padding: 12, textAlign: 'left' }}>Business</th>
              <th style={{ padding: 12, textAlign: 'left' }}>Bill</th>
              <th style={{ padding: 12, textAlign: 'left' }}>Coins Used</th>
              <th style={{ padding: 12, textAlign: 'left' }}>Status</th>
              <th style={{ padding: 12, textAlign: 'left' }}>Actions</th> {/* 🆕 */}
            </tr>
          </thead>
          <tbody>
            {payments.map(p => (
              <tr key={p.id} style={{ borderBottom: '1px solid #e5e7eb' }}>
                <td style={{ padding: 12 }}>{p.createdAt?.toDate().toLocaleString()}</td>
                <td style={{ padding: 12 }}>
                  <div style={{ fontWeight: 600 }}>{p.userName}</div>
                  <div style={{ fontSize: 12, color: '#9ca3af' }}>{p.userEmail || ''}</div>
                  {p.userPhone && <div style={{ fontSize: 12, color: '#9ca3af' }}>{p.userPhone}</div>}
                </td>
                <td style={{ padding: 12 }}>
                  <div>{p.offerTitle || '—'}</div>
                  {p.offerId && <div style={{ fontSize: 11, color: '#9ca3af' }}>ID: {p.offerId}</div>}
                </td>
                <td style={{ padding: 12 }}>{p.businessName}</td>
                <td style={{ padding: 12 }}>{p.billAmount?.toFixed(2)} {p.currency || 'QAR'}</td>
                <td style={{ padding: 12, fontWeight: 'bold', color: '#D4A13A' }}>{p.coinsUsed}</td>
                <td style={{ padding: 12 }}>
                  <span style={{
                    padding: '4px 8px', borderRadius: 4, fontSize: 12, fontWeight: 600,
                    backgroundColor: p.status === 'accepted' ? '#dcfce7' : (p.status === 'rejected' ? '#fee2e2' : '#fef9c3'),
                    color: p.status === 'accepted' ? '#166534' : (p.status === 'rejected' ? '#991b1b' : '#854d0e')
                  }}>
                    {p.status?.toUpperCase()}
                  </span>
                </td>
                <td style={{ padding: 12 }}>
                  {p.status === 'pending' && (
                    <>
                      <button 
                        onClick={() => handleStatusChange(p.id, 'accepted')}
                        style={{ marginRight: 4, padding: '4px 8px', backgroundColor: '#22c55e', color: 'white', border: 'none', borderRadius: 4, cursor: 'pointer' }}
                      >
                        Accept
                      </button>
                      <button 
                        onClick={() => handleStatusChange(p.id, 'rejected')}
                        style={{ padding: '4px 8px', backgroundColor: '#ef4444', color: 'white', border: 'none', borderRadius: 4, cursor: 'pointer' }}
                      >
                        Reject
                      </button>
                    </>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}