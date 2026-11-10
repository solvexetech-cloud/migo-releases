// admin/src/pages/DemandGroupsPage.jsx
// FIXED - Correctly shows Personal Order for Bulk
import React, { useState, useEffect } from 'react';
import { collection, onSnapshot, query, orderBy, doc, deleteDoc, updateDoc } from 'firebase/firestore';
import { db } from '../firebase';

const DemandGroupsPage = () => {
  const [groups, setGroups] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState('all');

  useEffect(() => {
    const q = query(collection(db, 'demand_groups'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const groupsData = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
      setGroups(groupsData);
      setLoading(false);
    }, (error) => {
      console.error("Error fetching groups:", error);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const filteredGroups = groups.filter((g) => {
    if (filterStatus === 'all') return true;
    return g.status === filterStatus;
  });

  const handleDelete = async (groupId) => {
    if (!window.confirm("Are you sure you want to delete this group? This action cannot be undone.")) return;
    try {
      await deleteDoc(doc(db, 'demand_groups', groupId));
    } catch (error) {
      console.error("Error deleting group:", error);
      alert("Failed to delete group.");
    }
  };

  const handleForceThreshold = async (groupId) => {
    if (!window.confirm("Force this group to reach the threshold and show it to businesses?")) return;
    try {
      await updateDoc(doc(db, 'demand_groups', groupId), {
        status: 'threshold_reached',
        thresholdReachedAt: new Date(),
      });
    } catch (error) {
      console.error("Error updating group:", error);
      alert("Failed to update group.");
    }
  };

  const getStatusBadge = (status) => {
    switch (status) {
      case 'collecting': return { text: 'Collecting', color: '#ed8936', bg: '#feebc8' };
      case 'threshold_reached': return { text: 'Threshold Reached', color: '#38a169', bg: '#c6f6d5' };
      case 'bidding': return { text: 'Bidding', color: '#3182ce', bg: '#bee3f8' };
      case 'fulfilled': return { text: 'Fulfilled', color: '#2f855a', bg: '#c6f6d5' };
      case 'expired': return { text: 'Expired', color: '#e53e3e', bg: '#fed7d7' };
      default: return { text: status, color: '#718096', bg: '#edf2f7' };
    }
  };

  if (loading) return <div style={{ padding: '20px' }}>Loading groups...</div>;

  return (
    <div style={{ padding: '24px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
        <div>
          <h1 style={{ fontSize: '24px', fontWeight: 'bold', margin: 0 }}>Demand Groups</h1>
          <p style={{ color: '#666', margin: '4px 0 0 0' }}>View and manage all customer demands.</p>
        </div>

        <select
          value={filterStatus}
          onChange={(e) => setFilterStatus(e.target.value)}
          style={{ padding: '10px', borderRadius: '6px', border: '1px solid #ccc' }}
        >
          <option value="all">All Statuses</option>
          <option value="collecting">Collecting</option>
          <option value="threshold_reached">Threshold Reached</option>
          <option value="bidding">Bidding</option>
        </select>
      </div>

      {filteredGroups.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '40px', backgroundColor: '#fff', borderRadius: '12px' }}>
          <p style={{ color: '#666' }}>No groups found.</p>
        </div>
      ) : (
        <div style={{ display: 'grid', gap: '16px' }}>
          {filteredGroups.map((group) => {
            const badge = getStatusBadge(group.status);
            const isBulk = group.threshold === 1; // ðŸ†• Detect Bulk

            return (
              <div
                key={group.id}
                style={{
                  backgroundColor: '#fff',
                  borderRadius: '12px',
                  padding: '20px',
                  boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
                  borderLeft: `4px solid ${isBulk ? '#6b21a8' : badge.color}`,
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div>
                    <h3 style={{ margin: '0 0 8px 0', fontSize: '18px', fontWeight: 'bold' }}>
                      {group.title}
                    </h3>
                    <div style={{ display: 'flex', gap: '8px', fontSize: '12px', color: '#666', marginBottom: '12px' }}>
                      <span>Category: <strong>{group.category}</strong></span>
                      <span>â€¢</span>
                      <span>Zone: <strong>{group.zoneId}</strong></span>
                      <span>â€¢</span>
                      <span>ID: <strong>{group.id.substring(0, 8)}...</strong></span>
                    </div>
                  </div>
                  <div style={{ display: 'flex', gap: '8px' }}>
                    {isBulk && (
                      <span style={{ backgroundColor: '#f3e8ff', color: '#6b21a8', padding: '4px 10px', borderRadius: '20px', fontSize: '12px', fontWeight: 'bold' }}>
                        Personal Order
                      </span>
                    )}
                    <span style={{ backgroundColor: badge.bg, color: badge.color, padding: '4px 10px', borderRadius: '20px', fontSize: '12px', fontWeight: 'bold' }}>
                      {badge.text}
                    </span>
                  </div>
                </div>

                <div style={{ display: 'flex', gap: '24px', margin: '16px 0' }}>
                  <div>
                    <div style={{ fontSize: '12px', color: '#666' }}>Members</div>
                    <div style={{ fontSize: '20px', fontWeight: 'bold', color: '#3182ce' }}>
                      {group.memberCount} / {group.threshold}
                    </div>
                  </div>
                  <div>
                    <div style={{ fontSize: '12px', color: '#666' }}>Total Quantity</div>
                    <div style={{ fontSize: '20px', fontWeight: 'bold' }}>{group.totalQuantity}</div>
                  </div>
                  <div>
                    <div style={{ fontSize: '12px', color: '#666' }}>Price Range</div>
                    <div style={{ fontSize: '16px', fontWeight: 'bold' }}>
                      {group.minTargetPrice} - {group.maxTargetPrice} QAR
                    </div>
                  </div>
                </div>

                <div style={{ display: 'flex', gap: '12px', marginTop: '16px', paddingTop: '16px', borderTop: '1px solid #eee' }}>
                  {group.status === 'collecting' && (
                    <button
                      onClick={() => handleForceThreshold(group.id)}
                      style={{ padding: '8px 16px', backgroundColor: '#38a169', color: '#fff', border: 'none', borderRadius: '6px', cursor: 'pointer', fontSize: '13px', fontWeight: 'bold' }}
                    >
                      Force Threshold Reached
                    </button>
                  )}
                  <button
                    onClick={() => handleDelete(group.id)}
                    style={{ padding: '8px 16px', backgroundColor: '#fff', color: '#e53e3e', border: '1px solid #e53e3e', borderRadius: '6px', cursor: 'pointer', fontSize: '13px', fontWeight: 'bold' }}
                  >
                    {isBulk ? 'Cancel Personal Order' : 'Delete Group'}
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};

export default DemandGroupsPage;