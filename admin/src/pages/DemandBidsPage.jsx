// admin/src/pages/DemandBidsPage.jsx
// UPDATED - Delete both bid and its parent group
import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, doc, updateDoc, deleteDoc, orderBy, query, getDoc } from 'firebase/firestore';
import { db } from '../firebase';

const DemandBidsPage = () => {
  const [bids, setBids] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');
  const [search, setSearch] = useState('');

  useEffect(() => {
    const q = query(collection(db, 'demand_bids'), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map((doc) => {
        const docData = doc.data();
        return { 
          id: doc.id, 
          ...docData,
          displayTitle: docData.groupTitle || 'Unknown Demand',
          dateStr: docData.createdAt ? docData.createdAt.toDate().toLocaleDateString() : 'N/A'
        };
      });
      setBids(data);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  const handleStatusChange = async (bidId, newStatus) => {
    try {
      await updateDoc(doc(db, 'demand_bids', bidId), { status: newStatus });
    } catch (error) {
      console.error("Error updating status:", error);
      alert("Failed to update status.");
    }
  };

  const handleDelete = async (bidId, groupId) => {
    if (!window.confirm("Are you sure you want to delete this bid and its demand?")) return;
    try {
      // 1. Delete Bid
      await deleteDoc(doc(db, 'demand_bids', bidId));
      
      // 2. Delete associated group (if exists)
      if (groupId) {
        try {
          await deleteDoc(doc(db, 'demand_groups', groupId));
        } catch (e) {
          console.log("Group might already be deleted:", e);
        }
      }
    } catch (error) {
      console.error("Error deleting bid:", error);
      alert("Failed to delete bid: " + error.message);
    }
  };

  const renderBusinessName = (name) => {
    if (!name) return 'Unknown';
    if (typeof name === 'string') return name;
    if (typeof name === 'object' && name.en) return name.en;
    return 'Unknown';
  };

  const filteredBids = bids.filter((b) => {
    const matchesStatus = filter === 'all' || b.status === filter;
    const searchLower = search.toLowerCase();
    const matchesSearch = 
      (b.displayTitle || '').toLowerCase().includes(searchLower) ||
      renderBusinessName(b.businessName).toLowerCase().includes(searchLower);
    return matchesStatus && matchesSearch;
  });

  if (loading) return <div style={{ padding: '20px' }}>Loading bids...</div>;

  return (
    <div style={{ padding: '24px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '20px', flexWrap: 'wrap', gap: '16px' }}>
        <h1 style={{ fontSize: '24px', fontWeight: 'bold', margin: 0 }}>Demand Bids & Trust Scores</h1>
        
        <div style={{ display: 'flex', gap: '12px' }}>
          <input
            type="text"
            placeholder="Search demand or business..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            style={{ padding: '10px', borderRadius: '6px', border: '1px solid #ccc', width: '250px' }}
          />
          <select value={filter} onChange={(e) => setFilter(e.target.value)} style={{ padding: '10px', borderRadius: '6px', border: '1px solid #ccc' }}>
            <option value="all">All Statuses</option>
            <option value="pending">Pending</option>
            <option value="approved">Approved</option>
            <option value="rejected">Rejected</option>
          </select>
        </div>
      </div>

      <div style={{ backgroundColor: '#fff', borderRadius: '12px', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ backgroundColor: '#f8f9fa', borderBottom: '1px solid #eee' }}>
              <th style={{ textAlign: 'left', padding: '12px 16px', fontSize: '14px', color: '#666' }}>Demand</th>
              <th style={{ textAlign: 'left', padding: '12px 16px', fontSize: '14px', color: '#666' }}>Business</th>
              <th style={{ textAlign: 'left', padding: '12px 16px', fontSize: '14px', color: '#666' }}>Price</th>
              <th style={{ textAlign: 'left', padding: '12px 16px', fontSize: '14px', color: '#666' }}>Status</th>
              <th style={{ textAlign: 'left', padding: '12px 16px', fontSize: '14px', color: '#666' }}>Trust Score</th>
              <th style={{ textAlign: 'left', padding: '12px 16px', fontSize: '14px', color: '#666' }}>Date</th>
              <th style={{ textAlign: 'left', padding: '12px 16px', fontSize: '14px', color: '#666' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredBids.map((bid) => (
              <tr key={bid.id} style={{ borderBottom: '1px solid #f0f0f0' }}>
                <td style={{ padding: '12px 16px', fontWeight: 'bold', color: '#1E3A8A' }}>{bid.displayTitle}</td>
                <td style={{ padding: '12px 16px', fontWeight: '500' }}>{renderBusinessName(bid.businessName)}</td>
                <td style={{ padding: '12px 16px' }}>QAR {bid.offerPrice}</td>
                <td style={{ padding: '12px 16px' }}>
                  <span style={{
                    padding: '4px 8px', borderRadius: '12px', fontSize: '12px', fontWeight: 'bold',
                    backgroundColor: bid.status === 'approved' ? '#c6f6d5' : bid.status === 'rejected' ? '#fed7d7' : '#feebc8',
                    color: bid.status === 'approved' ? '#2f855a' : bid.status === 'rejected' ? '#c53030' : '#c05621',
                  }}>
                    {bid.status}
                  </span>
                </td>
                <td style={{ padding: '12px 16px', fontWeight: 'bold' }}>{bid.businessTrustScore || 50} / 100</td>
                <td style={{ padding: '12px 16px', fontSize: '12px', color: '#666' }}>{bid.dateStr}</td>
                <td style={{ padding: '12px 16px' }}>
                  <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
                    {bid.status === 'pending' && (
                      <>
                        <button onClick={() => handleStatusChange(bid.id, 'approved')} style={{ padding: '6px 12px', backgroundColor: '#38a169', color: '#fff', border: 'none', borderRadius: '6px', cursor: 'pointer', fontSize: '12px' }}>Approve</button>
                        <button onClick={() => handleStatusChange(bid.id, 'rejected')} style={{ padding: '6px 12px', backgroundColor: '#e53e3e', color: '#fff', border: 'none', borderRadius: '6px', cursor: 'pointer', fontSize: '12px' }}>Reject</button>
                      </>
                    )}
                    <button onClick={() => handleDelete(bid.id, bid.groupId)} style={{ padding: '6px 12px', backgroundColor: '#fff', color: '#e53e3e', border: '1px solid #e53e3e', borderRadius: '6px', cursor: 'pointer', fontSize: '12px' }}>Delete</button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default DemandBidsPage;