import { useEffect, useState } from 'react';
import { collection, onSnapshot, query, orderBy, doc, updateDoc, deleteDoc } from 'firebase/firestore';
import { db } from '../firebase';

export default function AllOffersPage() {
  const [offers, setOffers] = useState([]);
  const [loading, setLoading] = useState(true);

  // ഫിൽട്ടർ സ്റ്റേറ്റുകൾ
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState('all');
  const [filterCountry, setFilterCountry] = useState('all');

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

  const handleEdit = (offer) => {
    // TODO: Edit page-ലേക്ക് navigate ചെയ്യുക
    alert(`Edit offer: ${offer.title}`);
  };

  // ഫിൽട്ടർ ചെയ്ത ഓഫറുകൾ
  const filteredOffers = offers.filter(offer => {
    const matchesSearch = 
      offer.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      offer.businessName?.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesType = filterType === 'all' || offer.type === filterType;
    const matchesCountry = filterCountry === 'all' || offer.countryCode === filterCountry;
    return matchesSearch && matchesType && matchesCountry;
  });

  if (loading) return <div style={{ padding: 24 }}>Loading...</div>;

  return (
    <div style={{ padding: 24 }}>
      <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 24 }}>All Offers</h1>

      {/* ഫിൽട്ടർ ബാർ */}
      <div style={{ 
        display: 'flex', 
        gap: 12, 
        marginBottom: 20, 
        flexWrap: 'wrap',
        alignItems: 'center'
      }}>
        <input
          type="text"
          placeholder="Search by title or business..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          style={{
            padding: '8px 12px',
            border: '1px solid #d1d5db',
            borderRadius: 6,
            fontSize: 14,
            minWidth: 250,
            flex: 1,
          }}
        />
        <select
          value={filterType}
          onChange={(e) => setFilterType(e.target.value)}
          style={{
            padding: '8px 12px',
            border: '1px solid #d1d5db',
            borderRadius: 6,
            fontSize: 14,
          }}
        >
          <option value="all">All Types</option>
          <option value="standard">Standard Deal</option>
          <option value="flash">Flash Deal</option>
          <option value="group">Group Deal</option>
          <option value="hidden">Hidden Gem</option>
          <option value="birthday">Birthday Deal</option>
        </select>
        <select
          value={filterCountry}
          onChange={(e) => setFilterCountry(e.target.value)}
          style={{
            padding: '8px 12px',
            border: '1px solid #d1d5db',
            borderRadius: 6,
            fontSize: 14,
          }}
        >
          <option value="all">All Countries</option>
          <option value="QA">Qatar</option>
          <option value="AE">UAE</option>
          <option value="SA">Saudi Arabia</option>
          <option value="KW">Kuwait</option>
          <option value="OM">Oman</option>
          <option value="BH">Bahrain</option>
          <option value="IN">India</option>
        </select>
        <div style={{ fontSize: 14, color: '#6b7280' }}>
          {filteredOffers.length} offers
        </div>
      </div>

      <div style={{ overflowX: 'auto' }}>
        <table style={{ width: '100%', backgroundColor: 'white', borderRadius: 8, boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid #e5e7eb' }}>
              <th style={{ padding: 12, textAlign: 'left' }}>Title</th>
              <th style={{ padding: 12, textAlign: 'left' }}>Business</th>
              <th style={{ padding: 12, textAlign: 'left' }}>Type</th>
              <th style={{ padding: 12, textAlign: 'left' }}>Country</th>
              <th style={{ padding: 12, textAlign: 'left' }}>Price</th>
              <th style={{ padding: 12, textAlign: 'left' }}>Status</th>
              <th style={{ padding: 12, textAlign: 'left' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredOffers.map(offer => (
              <tr key={offer.id} style={{ borderBottom: '1px solid #e5e7eb' }}>
                <td style={{ padding: 12 }}>{offer.title}</td>
                <td style={{ padding: 12 }}>{offer.businessName}</td>
                <td style={{ padding: 12 }}>
                  <span style={{
                    padding: '2px 8px',
                    borderRadius: 4,
                    fontSize: 11,
                    fontWeight: 600,
                    backgroundColor: '#e0e7ff',
                    color: '#3730a3'
                  }}>
                    {offer.type?.toUpperCase() || 'STANDARD'}
                  </span>
                </td>
                <td style={{ padding: 12 }}>{offer.countryCode || 'QA'}</td>
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
                <td style={{ padding: 12, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                  {offer.status === 'pending' && (
                    <>
                      <button onClick={() => handleApprove(offer.id)} style={{ padding: '6px 10px', backgroundColor: '#22c55e', color: 'white', border: 'none', borderRadius: 4, cursor: 'pointer', fontSize: 12 }}>Approve</button>
                      <button onClick={() => handleReject(offer.id)} style={{ padding: '6px 10px', backgroundColor: '#eab308', color: 'white', border: 'none', borderRadius: 4, cursor: 'pointer', fontSize: 12 }}>Reject</button>
                    </>
                  )}

                  {offer.status === 'live' && (
                    <button onClick={() => handlePause(offer.id)} style={{ padding: '6px 10px', backgroundColor: '#3b82f6', color: 'white', border: 'none', borderRadius: 4, cursor: 'pointer', fontSize: 12 }}>Pause</button>
                  )}

                  {(offer.status === 'rejected' || offer.status === 'paused') && (
                    <button onClick={() => handleApprove(offer.id)} style={{ padding: '6px 10px', backgroundColor: '#22c55e', color: 'white', border: 'none', borderRadius: 4, cursor: 'pointer', fontSize: 12 }}>Approve</button>
                  )}

                  <button onClick={() => handleEdit(offer)} style={{ padding: '6px 10px', backgroundColor: '#8b5cf6', color: 'white', border: 'none', borderRadius: 4, cursor: 'pointer', fontSize: 12 }}>Edit</button>

                  <button onClick={() => handleDelete(offer.id)} style={{ padding: '6px 10px', backgroundColor: '#ef4444', color: 'white', border: 'none', borderRadius: 4, cursor: 'pointer', fontSize: 12 }}>Delete</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}