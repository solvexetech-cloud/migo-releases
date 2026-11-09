import React, { useState, useEffect } from "react";
import { collection, getDocs, doc, updateDoc } from "firebase/firestore";
import { db } from "../firebase";

const DemandBidsPage = () => {
  const [bids, setBids] = useState([]);
  const [loading, setLoading] = useState(true);
  const [editingBid, setEditingBid] = useState(null);
  const [newScore, setNewScore] = useState("");

  useEffect(() => {
    const fetchBids = async () => {
      const snapshot = await getDocs(collection(db, "demand_bids"));
      const list = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
      setBids(list);
      setLoading(false);
    };
    fetchBids();
  }, []);

  const handleUpdateScore = async (bid) => {
    const score = parseFloat(newScore);
    if (isNaN(score) || score < 0 || score > 100) {
      alert("Score must be between 0 and 100");
      return;
    }

    // 1. ബിഡിലെ സ്കോർ അപ്ഡേറ്റ് ചെയ്യുക
    await updateDoc(doc(db, "demand_bids", bid.id), { businessTrustScore: score });

    // 2. ബിസിനസിന്റെ ട്രസ്റ്റ് സ്കോർ അപ്ഡേറ്റ് ചെയ്യുക
    const bizSnapshot = await getDocs(collection(db, "businesses"));
    const bizDoc = bizSnapshot.docs.find((d) => d.data().ownerUid === bid.businessId);
    if (bizDoc) {
      await updateDoc(doc(db, "businesses", bizDoc.id), { trustScore: score });
    }

    setBids((prev) =>
      prev.map((b) => (b.id === bid.id ? { ...b, businessTrustScore: score } : b))
    );
    setEditingBid(null);
    setNewScore("");
    alert("✅ Trust score updated!");
  };

  if (loading) return <div style={{ padding: 20 }}>Loading...</div>;

  return (
    <div style={{ padding: 20 }}>
      <h1 style={{ fontSize: 24, fontWeight: 900, color: "#0F2B5B", marginBottom: 20 }}>
        Demand Bids & Trust Scores
      </h1>

      <div style={{ background: "#fff", borderRadius: 12, padding: 20, boxShadow: "0 2px 8px rgba(0,0,0,0.1)" }}>
        <table style={{ width: "100%", borderCollapse: "collapse" }}>
          <thead>
            <tr style={{ background: "#F6F3EE", textAlign: "left" }}>
              <th style={{ padding: 12 }}>Business</th>
              <th style={{ padding: 12 }}>Price</th>
              <th style={{ padding: 12 }}>Status</th>
              <th style={{ padding: 12 }}>Trust Score</th>
              <th style={{ padding: 12 }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {bids.map((bid) => (
              <tr key={bid.id} style={{ borderBottom: "1px solid #eee" }}>
                <td style={{ padding: 12 }}>{bid.businessName?.en || "Unknown"}</td>
                <td style={{ padding: 12 }}>QAR {bid.offerPrice}</td>
                <td style={{ padding: 12 }}>
                  <span style={{
                    padding: "4px 10px", borderRadius: 6, fontSize: 12, fontWeight: "bold",
                    background: bid.status === "approved" ? "#E6F7E6" : bid.status === "rejected" ? "#FFE6E6" : "#FFF3E0",
                    color: bid.status === "approved" ? "#2E7D32" : bid.status === "rejected" ? "#C62828" : "#E65100",
                  }}>
                    {bid.status}
                  </span>
                </td>
                <td style={{ padding: 12, fontWeight: 800 }}>
                  {editingBid === bid.id ? (
                    <input
                      type="number"
                      value={newScore}
                      onChange={(e) => setNewScore(e.target.value)}
                      style={{ width: 60, padding: 4 }}
                    />
                  ) : (
                    `${bid.businessTrustScore?.toFixed(1) || 50.0} / 100`
                  )}
                </td>
                <td style={{ padding: 12 }}>
                  {editingBid === bid.id ? (
                    <>
                      <button onClick={() => handleUpdateScore(bid)} style={{ padding: "6px 12px", background: "#2E7D32", color: "#fff", border: "none", borderRadius: 6, cursor: "pointer", marginRight: 8 }}>Save</button>
                      <button onClick={() => setEditingBid(null)} style={{ padding: "6px 12px", background: "#999", color: "#fff", border: "none", borderRadius: 6, cursor: "pointer" }}>Cancel</button>
                    </>
                  ) : (
                    <button onClick={() => { setEditingBid(bid.id); setNewScore(bid.businessTrustScore?.toFixed(1) || "50.0"); }} style={{ padding: "6px 12px", background: "#0F2B5B", color: "#fff", border: "none", borderRadius: 6, cursor: "pointer" }}>Edit Score</button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {bids.length === 0 && <p style={{ textAlign: "center", color: "#999", padding: 20 }}>No bids found.</p>}
      </div>
    </div>
  );
};

export default DemandBidsPage;