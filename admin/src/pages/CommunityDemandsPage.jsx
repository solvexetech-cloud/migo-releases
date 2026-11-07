import React, { useEffect, useState } from 'react';
import { db } from '../firebase';
import { collection, getDocs } from 'firebase/firestore';

const CommunityDemandsPage = () => {
  const [demands, setDemands] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedDemand, setSelectedDemand] = useState(null);

  useEffect(() => {
    const fetchAllData = async () => {
      try {
        setLoading(true);
        const [demandSnapshot, bidsSnapshot, commitsSnapshot, usersSnapshot, businessSnapshot] = await Promise.all([
          getDocs(collection(db, 'demands')),
          getDocs(collection(db, 'demand_bids')),
          getDocs(collection(db, 'demand_commits')),
          getDocs(collection(db, 'users')),
          getDocs(collection(db, 'businesses'))
        ]);

        const demandList = demandSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        const bidsList = bidsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        const commitsList = commitsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        const usersList = usersSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        const businessList = businessSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

        const usersMap = {};
        usersList.forEach(u => {
            usersMap[u.id] = u.name || u.displayName || u.phone || u.email || u.userName || 'Unknown User';
        });

        const businessMap = {};
        businessList.forEach(b => {
            businessMap[b.id] = b.name?.en || b.name || b.businessName?.en || b.businessName || 'Unknown Shop';
        });

        const enrichedDemands = demandList.map(demand => {
          const demandBids = bidsList.filter(b => b.demandId === demand.id).map(b => ({
            ...b, shopName: businessMap[b.businessId] || b.businessName?.en || b.businessId
          }));
          
          const demandCommits = commitsList.filter(c => c.demandId === demand.id).map(c => {
            // ബിസിനസ്സ് ഐഡി ഏത് ഫീൽഡിലാണെന്ന് ഉറപ്പാക്കാൻ (businessId, shopId, അല്ലെങ്കിൽ bid-ൽ നിന്ന് എടുക്കാൻ)
            let shopId = c.businessId || c.shopId;
            if (!shopId && c.bidId) {
                const relatedBid = bidsList.find(b => b.id === c.bidId);
                if (relatedBid) shopId = relatedBid.businessId;
            }
            return {
              ...c, 
              userName: usersMap[c.userId] || c.userId, 
              shopName: businessMap[shopId] || c.businessName?.en || c.businessName || 'Unknown Shop'
            }
          });

          return { 
            ...demand, 
            bids: demandBids, 
            commits: demandCommits,
            creatorName: usersMap[demand.userId] || demand.userName || demand.userId
          };
        }).sort((a, b) => (b.createdAt?.seconds || 0) - (a.createdAt?.seconds || 0));

        setDemands(enrichedDemands);
      } catch (error) {
        console.error("Error fetching data: ", error);
      } finally {
        setLoading(false);
      }
    };
    fetchAllData();
  }, []);

  const filteredDemands = demands.filter(d => 
    (d.title?.en || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
    (d.creatorName || '').toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (loading) return <div style={{ padding: 40, textAlign: 'center', fontSize: 18 }}>Loading Demands...</div>;

  return (
    <div style={{ padding: 30, backgroundColor: '#F6F3EE', minHeight: '100vh', fontFamily: 'sans-serif' }}>
      
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 25 }}>
        <div>
          <h1 style={{ fontSize: 24, fontWeight: 'bold', color: '#0B2B5B', margin: 0 }}>Community Demands Overview</h1>
          <p style={{ fontSize: 14, color: '#666', marginTop: 5 }}>Track customer demands, shop offers, and commitments.</p>
        </div>
        <div>
          <input 
            type="text" 
            placeholder="ðŸ” Search by Title or User..." 
            style={{ padding: '10px 15px', borderRadius: 8, border: '1px solid #ccc', width: 300, fontSize: 14, outline: 'none' }}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>

      {/* Table */}
      <div style={{ backgroundColor: 'white', borderRadius: 12, boxShadow: '0 2px 10px rgba(0,0,0,0.05)', overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead style={{ backgroundColor: '#f8f9fa', borderBottom: '1px solid #eee' }}>
            <tr>
              <th style={{ padding: 15, fontSize: 12, color: '#666', textTransform: 'uppercase' }}>Demand Details</th>
              <th style={{ padding: 15, fontSize: 12, color: '#666', textTransform: 'uppercase' }}>Target Price</th>
              <th style={{ padding: 15, fontSize: 12, color: '#666', textTransform: 'uppercase' }}>Offers</th>
              <th style={{ padding: 15, fontSize: 12, color: '#666', textTransform: 'uppercase' }}>Commits</th>
              <th style={{ padding: 15, fontSize: 12, color: '#666', textTransform: 'uppercase' }}>Status</th>
              <th style={{ padding: 15, fontSize: 12, color: '#666', textTransform: 'uppercase', textAlign: 'center' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredDemands.length === 0 ? (
              <tr>
                <td colSpan="6" style={{ padding: 30, textAlign: 'center', color: '#999' }}>No demands found.</td>
              </tr>
            ) : (
              filteredDemands.map((demand) => (
                <tr key={demand.id} style={{ borderBottom: '1px solid #eee' }}>
                  <td style={{ padding: 15 }}>
                    <p style={{ margin: 0, fontWeight: 'bold', color: '#333', fontSize: 15 }}>{demand.title?.en || demand.title?.ar || 'No Title'}</p>
                    <p style={{ margin: '5px 0 0 0', fontSize: 12, color: '#777' }}>By: <span style={{ fontWeight: 'bold', color: '#0B2B5B' }}>{demand.creatorName}</span></p>
                  </td>
                  <td style={{ padding: 15, fontWeight: 'bold', color: '#0B2B5B' }}>
                    {demand.targetPrice} {demand.currency}
                  </td>
                  <td style={{ padding: 15 }}>{demand.bids.length}</td>
                  <td style={{ padding: 15 }}>{demand.commits.length} / 15</td>
                  <td style={{ padding: 15 }}>
                    <span style={{ padding: '5px 10px', borderRadius: 20, fontSize: 11, fontWeight: 'bold', backgroundColor: demand.status === 'open' ? '#FFF3E0' : '#E8F5E9', color: demand.status === 'open' ? '#E65100' : '#2E7D32' }}>
                      {demand.status?.toUpperCase() || 'OPEN'}
                    </span>
                  </td>
                  <td style={{ padding: 15, textAlign: 'center' }}>
                    <button 
                      onClick={() => setSelectedDemand(demand)}
                      style={{ backgroundColor: '#F0C566', color: '#0B2B5B', border: 'none', padding: '8px 16px', borderRadius: 6, fontWeight: 'bold', cursor: 'pointer', fontSize: 12 }}
                    >
                      View
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Modal */}
      {selectedDemand && (
        <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.5)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000 }}>
          <div style={{ backgroundColor: 'white', borderRadius: 12, width: '90%', maxWidth: 800, maxHeight: '90vh', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
            
            <div style={{ backgroundColor: '#0B2B5B', padding: 20, color: 'white', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <h2 style={{ margin: 0, fontSize: 20 }}>{selectedDemand.title?.en || selectedDemand.title?.ar}</h2>
                <p style={{ margin: '5px 0 0 0', fontSize: 13, color: '#ccc' }}>Requested by: {selectedDemand.creatorName}</p>
              </div>
              <button onClick={() => setSelectedDemand(null)} style={{ background: 'none', border: 'none', color: 'white', fontSize: 24, cursor: 'pointer' }}>&times;</button>
            </div>

            <div style={{ padding: 20, overflowY: 'auto', display: 'flex', gap: 20, flexWrap: 'wrap' }}>
               
               {/* Offers */}
               <div style={{ flex: 1, minWidth: 300, backgroundColor: '#F8FAFC', padding: 15, borderRadius: 8, border: '1px solid #E2E8F0' }}>
                  <h3 style={{ margin: '0 0 15px 0', fontSize: 16, color: '#0B2B5B', borderBottom: '2px solid #CBD5E1', paddingBottom: 8 }}>Shops Placed Offers ({selectedDemand.bids.length})</h3>
                  {selectedDemand.bids.length === 0 ? (
                    <p style={{ color: '#94A3B8', fontSize: 14 }}>No offers yet.</p>
                  ) : (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                      {selectedDemand.bids.map(bid => (
                        <div key={bid.id} style={{ backgroundColor: 'white', padding: 12, borderRadius: 6, border: '1px solid #E2E8F0' }}>
                          <p style={{ margin: 0, fontWeight: 'bold', color: '#1E293B' }}>{bid.shopName}</p>
                          <p style={{ margin: '5px 0', fontSize: 13 }}>Offer: <strong style={{ color: '#0B2B5B' }}>{bid.offerPrice} QAR</strong></p>
                          <p style={{ margin: 0, fontSize: 12, color: '#64748B' }}>Requires: {bid.minCommitments} users</p>
                          <span style={{ display: 'inline-block', marginTop: 8, fontSize: 10, fontWeight: 'bold', color: 'green', backgroundColor: '#DCFCE7', padding: '2px 8px', borderRadius: 10 }}>{bid.status.toUpperCase()}</span>
                        </div>
                      ))}
                    </div>
                  )}
               </div>

               {/* Commits */}
               <div style={{ flex: 1, minWidth: 300, backgroundColor: '#F0FDF4', padding: 15, borderRadius: 8, border: '1px solid #BBF7D0' }}>
                  <h3 style={{ margin: '0 0 15px 0', fontSize: 16, color: '#166534', borderBottom: '2px solid #BBF7D0', paddingBottom: 8 }}>Committed Users ({selectedDemand.commits.length})</h3>
                  {selectedDemand.commits.length === 0 ? (
                    <p style={{ color: '#94A3B8', fontSize: 14 }}>No users yet.</p>
                  ) : (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 10, maxHeight: 300, overflowY: 'auto' }}>
                      {selectedDemand.commits.map(commit => (
                        <div key={commit.id} style={{ backgroundColor: 'white', padding: 12, borderRadius: 6, border: '1px solid #E2E8F0', display: 'flex', justifyContent: 'space-between' }}>
                          <div>
                             <p style={{ margin: 0, fontWeight: 'bold', color: '#1E293B', fontSize: 14 }}>{commit.userName}</p>
                             <p style={{ margin: '5px 0 0 0', fontSize: 12, color: '#64748B' }}>to: {commit.shopName}</p>
                          </div>
                          <div style={{ textAlign: 'right' }}>
                             <p style={{ margin: 0, fontWeight: 'bold', color: '#0B2B5B' }}>{commit.finalPrice} QAR</p>
                             <span style={{ fontSize: 10, fontWeight: 'bold', color: commit.status === 'locked' ? '#16A34A' : '#D97706' }}>{commit.status.toUpperCase()}</span>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
               </div>
            </div>
            
            <div style={{ padding: 15, borderTop: '1px solid #eee', textAlign: 'right', backgroundColor: '#F8FAFC' }}>
               <button onClick={() => setSelectedDemand(null)} style={{ backgroundColor: '#E2E8F0', border: 'none', color: '#333', padding: '10px 20px', borderRadius: 6, fontWeight: 'bold', cursor: 'pointer' }}>Close</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default CommunityDemandsPage;