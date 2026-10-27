import { useEffect, useState } from 'react';
import { collection, onSnapshot, query, orderBy, doc, updateDoc, deleteDoc } from 'firebase/firestore';
import { db } from '../firebase';

export default function AllOffersPage() {
  const [offers, setOffers] = useState([]);
  const [loading, setLoading] = useState(true);
  
  // Edit Modal State
  const [editingOffer, setEditingOffer] = useState(null);
  const [editLoading, setEditLoading] = useState(false);

  // ഫിൽട്ടർ സ്റ്റേറ്റുകൾ
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState('all');
  const [filterCountry, setFilterCountry] = useState('all');
  const [isAr, setIsAr] = useState(false);

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
    const confirmMsg = isAr ? 'هل أنت متأكد أنك تريد حذف هذا العرض؟' : 'Are you sure you want to delete this offer?';
    if (window.confirm(confirmMsg)) {
      await deleteDoc(doc(db, 'offers', id));
    }
  };

  const handlePromote = async (id, currentStatus) => {
    try {
      await updateDoc(doc(db, 'offers', id), { isPromoted: !currentStatus });
    } catch (error) {
      console.error("Error updating promotion:", error);
    }
  };

  // 🆕 Edit ചെയ്ത് സേവ് ചെയ്യാനുള്ള ഫങ്ക്ഷൻ
  const handleSaveEdit = async () => {
    if (!editingOffer) return;
    setEditLoading(true);
    try {
      await updateDoc(doc(db, 'offers', editingOffer.id), {
        title: editingOffer.title,
        originalPrice: Number(editingOffer.originalPrice),
        offerPrice: Number(editingOffer.offerPrice),
        status: editingOffer.status,
      });
      setEditingOffer(null); // Close modal on success
    } catch (error) {
      alert("Failed to update offer: " + error.message);
    } finally {
      setEditLoading(false);
    }
  };

  const filteredOffers = offers.filter(offer => {
    const matchesSearch = 
      offer.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      offer.businessName?.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesType = filterType === 'all' || offer.type === filterType;
    const matchesCountry = filterCountry === 'all' || offer.countryCode === filterCountry;
    return matchesSearch && matchesType && matchesCountry;
  });

  // ഭാഷാ വിവർത്തനങ്ങൾ
  const t = {
    title: isAr ? 'جميع العروض' : 'All Offers',
    search: isAr ? 'البحث بالعنوان أو النشاط التجاري...' : 'Search by title or business...',
    allTypes: isAr ? 'جميع الأنواع' : 'All Types',
    allCountries: isAr ? 'جميع الدول' : 'All Countries',
    colTitle: isAr ? 'العنوان' : 'Title',
    colBusiness: isAr ? 'النشاط التجاري' : 'Business',
    colPrice: isAr ? 'السعر' : 'Price',
    colStatus: isAr ? 'الحالة' : 'Status',
    colActions: isAr ? 'الإجراءات' : 'Actions',
    approve: isAr ? 'موافقة' : 'Approve',
    pause: isAr ? 'إيقاف مؤقت' : 'Pause',
    featured: isAr ? '⭐ مميز' : '⭐ Featured',
    promote: isAr ? '☆ تمييز' : '☆ Promote',
    edit: isAr ? 'تعديل' : 'Edit',
    delete: isAr ? 'حذف' : 'Delete',
  };

  if (loading) return <div style={{ padding: 24 }}>Loading...</div>;

  return (
    <div dir={isAr ? 'rtl' : 'ltr'} style={{ padding: 24, textAlign: isAr ? 'right' : 'left' }}>
      
      {/* Header & Language Toggle */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <h1 style={{ fontSize: 24, fontWeight: 700, margin: 0 }}>{t.title}</h1>
        <button 
          onClick={() => setIsAr(!isAr)}
          style={{ padding: '8px 16px', backgroundColor: '#1e3a8a', color: 'white', border: 'none', borderRadius: 6, cursor: 'pointer', fontWeight: 'bold' }}
        >
          {isAr ? 'English' : 'العربية'}
        </button>
      </div>

      {/* Filters */}
      <div style={{ display: 'flex', gap: 12, marginBottom: 20, flexWrap: 'wrap' }}>
        <input
          type="text"
          placeholder={t.search}
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          style={{ padding: '8px 12px', border: '1px solid #d1d5db', borderRadius: 6, minWidth: 250, flex: 1 }}
        />
        <select value={filterType} onChange={(e) => setFilterType(e.target.value)} style={{ padding: '8px 12px', border: '1px solid #d1d5db', borderRadius: 6 }}>
          <option value="all">{t.allTypes}</option>
          <option value="standard">Standard</option>
          <option value="flash">Flash</option>
          <option value="group">Group</option>
        </select>
        <select value={filterCountry} onChange={(e) => setFilterCountry(e.target.value)} style={{ padding: '8px 12px', border: '1px solid #d1d5db', borderRadius: 6 }}>
          <option value="all">{t.allCountries}</option>
          <option value="QA">Qatar</option>
          <option value="AE">UAE</option>
        </select>
      </div>

      {/* Table */}
      <div style={{ overflowX: 'auto' }}>
        <table style={{ width: '100%', backgroundColor: 'white', borderRadius: 8, boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid #e5e7eb', backgroundColor: '#f9fafb' }}>
              <th style={{ padding: 12, textAlign: isAr ? 'right' : 'left' }}>{t.colTitle}</th>
              <th style={{ padding: 12, textAlign: isAr ? 'right' : 'left' }}>{t.colBusiness}</th>
              <th style={{ padding: 12, textAlign: isAr ? 'right' : 'left' }}>{t.colPrice}</th>
              <th style={{ padding: 12, textAlign: isAr ? 'right' : 'left' }}>{t.colStatus}</th>
              <th style={{ padding: 12, textAlign: isAr ? 'right' : 'left' }}>{t.colActions}</th>
            </tr>
          </thead>
          <tbody>
            {filteredOffers.map(offer => (
              <tr key={offer.id} style={{ borderBottom: '1px solid #e5e7eb' }}>
                <td style={{ padding: 12 }}>
                  {offer.isPromoted && <span style={{ marginRight: 4 }}>⭐</span>}
                  {offer.title}
                </td>
                <td style={{ padding: 12 }}>{offer.businessName}</td>
                <td style={{ padding: 12 }}>QAR {offer.offerPrice}</td>
                <td style={{ padding: 12 }}>
                  <span style={{
                    padding: '4px 8px', borderRadius: 4, fontSize: 12, fontWeight: 600,
                    backgroundColor: offer.status === 'live' ? '#dcfce7' : offer.status === 'pending' ? '#fef9c3' : '#fee2e2',
                    color: offer.status === 'live' ? '#166534' : offer.status === 'pending' ? '#854d0e' : '#991b1b'
                  }}>
                    {offer.status?.toUpperCase()}
                  </span>
                </td>
                <td style={{ padding: 12, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                  {offer.status === 'live' && (
                    <button onClick={() => handlePause(offer.id)} style={{ padding: '6px 10px', backgroundColor: '#3b82f6', color: 'white', border: 'none', borderRadius: 4, cursor: 'pointer', fontSize: 12 }}>{t.pause}</button>
                  )}
                  {(offer.status === 'pending' || offer.status === 'paused') && (
                    <button onClick={() => handleApprove(offer.id)} style={{ padding: '6px 10px', backgroundColor: '#22c55e', color: 'white', border: 'none', borderRadius: 4, cursor: 'pointer', fontSize: 12 }}>{t.approve}</button>
                  )}
                  
                  <button 
                    onClick={() => handlePromote(offer.id, offer.isPromoted)} 
                    style={{ padding: '6px 10px', backgroundColor: offer.isPromoted ? '#f59e0b' : '#d1d5db', color: offer.isPromoted ? 'white' : '#374151', border: 'none', borderRadius: 4, cursor: 'pointer', fontSize: 12, fontWeight: 600 }}
                  >
                    {offer.isPromoted ? t.featured : t.promote}
                  </button>

                  <button onClick={() => setEditingOffer(offer)} style={{ padding: '6px 10px', backgroundColor: '#8b5cf6', color: 'white', border: 'none', borderRadius: 4, cursor: 'pointer', fontSize: 12 }}>{t.edit}</button>
                  <button onClick={() => handleDelete(offer.id)} style={{ padding: '6px 10px', backgroundColor: '#ef4444', color: 'white', border: 'none', borderRadius: 4, cursor: 'pointer', fontSize: 12 }}>{t.delete}</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* 🆕 Edit Modal (Popup) */}
      {editingOffer && (
        <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.5)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000, direction: 'ltr' }}>
          <div style={{ backgroundColor: 'white', padding: 24, borderRadius: 8, width: 400, maxWidth: '90%' }}>
            <h2 style={{ fontSize: 20, fontWeight: 700, marginBottom: 16 }}>Edit Offer</h2>
            
            <label style={{ display: 'block', fontSize: 12, color: '#6b7280', marginBottom: 4 }}>Title</label>
            <input 
              type="text" 
              value={editingOffer.title} 
              onChange={(e) => setEditingOffer({...editingOffer, title: e.target.value})}
              style={{ width: '100%', padding: 8, border: '1px solid #d1d5db', borderRadius: 4, marginBottom: 12 }} 
            />

            <div style={{ display: 'flex', gap: 10, marginBottom: 12 }}>
              <div style={{ flex: 1 }}>
                <label style={{ display: 'block', fontSize: 12, color: '#6b7280', marginBottom: 4 }}>Original Price</label>
                <input 
                  type="number" 
                  value={editingOffer.originalPrice} 
                  onChange={(e) => setEditingOffer({...editingOffer, originalPrice: e.target.value})}
                  style={{ width: '100%', padding: 8, border: '1px solid #d1d5db', borderRadius: 4 }} 
                />
              </div>
              <div style={{ flex: 1 }}>
                <label style={{ display: 'block', fontSize: 12, color: '#6b7280', marginBottom: 4 }}>MIGO Price</label>
                <input 
                  type="number" 
                  value={editingOffer.offerPrice} 
                  onChange={(e) => setEditingOffer({...editingOffer, offerPrice: e.target.value})}
                  style={{ width: '100%', padding: 8, border: '1px solid #d1d5db', borderRadius: 4 }} 
                />
              </div>
            </div>

            <label style={{ display: 'block', fontSize: 12, color: '#6b7280', marginBottom: 4 }}>Status</label>
            <select 
              value={editingOffer.status} 
              onChange={(e) => setEditingOffer({...editingOffer, status: e.target.value})}
              style={{ width: '100%', padding: 8, border: '1px solid #d1d5db', borderRadius: 4, marginBottom: 20 }}
            >
              <option value="pending">Pending</option>
              <option value="live">Live</option>
              <option value="paused">Paused</option>
              <option value="rejected">Rejected</option>
            </select>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10 }}>
              <button onClick={() => setEditingOffer(null)} style={{ padding: '8px 16px', backgroundColor: '#e5e7eb', color: '#374151', border: 'none', borderRadius: 4, cursor: 'pointer', fontWeight: 600 }}>Cancel</button>
              <button onClick={handleSaveEdit} disabled={editLoading} style={{ padding: '8px 16px', backgroundColor: '#22c55e', color: 'white', border: 'none', borderRadius: 4, cursor: 'pointer', fontWeight: 600 }}>
                {editLoading ? 'Saving...' : 'Save Changes'}
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}