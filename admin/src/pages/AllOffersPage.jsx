import { useEffect, useState } from 'react';
import { collection, onSnapshot, query, orderBy, doc, updateDoc, deleteDoc } from 'firebase/firestore';
import { db } from '../firebase';

export default function AllOffersPage() {
  const [offers, setOffers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const q = query(collection(db, 'offers'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      setOffers(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  const handleApprove = async (id) => {
    await updateDoc(doc(db, 'offers', id), { status: 'live' });
  };

  const handlePause = async (id) => {
    await updateDoc(doc(db, 'offers', id), { status: 'paused' });
  };

  const handleReject = async (id) => {
    await updateDoc(doc(db, 'offers', id), { status: 'rejected' });
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this offer?')) {
      await deleteDoc(doc(db, 'offers', id));
    }
  };

  if (loading) return <div style={{ padding: 24 }}>Loading...</div>;

  return (
    <div style={{ padding: 24 }}>
      <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 24 }}>All Offers</h1>
      <div style={{ overflowX: 'auto' }}>
        <table style={{ width: '100%', backgroundColor: 'white', borderRadius: 8, boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid #e5e7eb' }}>
              <th style={{ padding: 12, textAlign: 'left' }}>Title</th>
              <th style={{ padding: 12, textAlign: 'left' }}>Business</th>
              <th style={{ padding: 12, textAlign: 'left' }}>Price</th>
              <th style={{ padding: 12, textAlign: 'left' }}>Status</th>
              <th style={{ padding: 12, textAlign: 'left' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {offers.map(offer => (
              <tr key={offer.id} style={{ borderBottom: '1px solid #e5e7eb' }}>
                <td style={{ padding: 12 }}>{offer.title}</td>
                <td style={{ padding: 12 }}>{offer.businessName}</td>
                <td style={{ padding: 12 }}>QAR {offer.offerPrice}</td>
                <td style={{ padding: 12 }}>
                  <span style={{
                    padding: '4px 8px',
                    borderRadius: 4,
                    fontSize: 12,
                    fontWeight: 600,
                    backgroundColor: offer.status === 'live' ? '#dcfce7' : offer.status === 'pending' ? '#fef9c3' : '#fee2e2',
                    color: offer.status === 'live' ? '#166534' : offer.status === 'pending' ? '#854d0e' : '#991b1b'
                  }}>
                    {offer.status?.toUpperCase() || 'UNKNOWN'}
                  </span>
                </td>
                <td style={{ padding: 12, display: 'flex', gap: 8 }}>
                  {offer.status === 'pending' && (
                    <>
                      <button onClick={() => handleApprove(offer.id)} style={{ padding: '6px 12px', backgroundColor: '#22c55e', color: 'white', border: 'none', borderRadius: 4, cursor: 'pointer' }}>Approve</button>
                      <button onClick={() => handleReject(offer.id)} style={{ padding: '6px 12px', backgroundColor: '#eab308', color: 'white', border: 'none', borderRadius: 4, cursor: 'pointer' }}>Reject</button>
                    </>
                  )}

                  {offer.status === 'live' && (
                    <button onClick={() => handlePause(offer.id)} style={{ padding: '6px 12px', backgroundColor: '#3b82f6', color: 'white', border: 'none', borderRadius: 4, cursor: 'pointer' }}>Pause</button>
                  )}

                                    {offer.status === 'rejected' && (
                    <button onClick={() => handleApprove(offer.id)} style={{ padding: '6px 12px', backgroundColor: '#22c55e', color: 'white', border: 'none', borderRadius: 4, cursor: 'pointer' }}>Approve</button>
                  )}

                  {offer.status === 'paused' && (
                    <button onClick={() => handleApprove(offer.id)} style={{ padding: '6px 12px', backgroundColor: '#22c55e', color: 'white', border: 'none', borderRadius: 4, cursor: 'pointer' }}>Approve</button>
                  )}

                  <button onClick={() => handleDelete(offer.id)} style={{ padding: '6px 12px', backgroundColor: '#ef4444', color: 'white', border: 'none', borderRadius: 4, cursor: 'pointer' }}>Delete</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}