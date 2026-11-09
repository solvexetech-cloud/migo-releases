import React, { useState, useEffect, useMemo } from "react";
import { collection, getDocs, doc, updateDoc, deleteDoc } from "firebase/firestore";
import { db } from "../firebase";

const ProductRequestsPage = () => {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState("all");
  const [searchQuery, setSearchQuery] = useState("");

  useEffect(() => {
    const fetchRequests = async () => {
      try {
        const snapshot = await getDocs(collection(db, "product_requests"));
        const list = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
        setRequests(list);
      } catch (err) {
        console.error("Error fetching requests:", err);
      } finally {
        setLoading(false);
      }
    };
    fetchRequests();
  }, []);

  const handleStatusChange = async (id, newStatus) => {
    await updateDoc(doc(db, "product_requests", id), { status: newStatus });
    setRequests((prev) =>
      prev.map((r) => (r.id === id ? { ...r, status: newStatus } : r))
    );
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Delete this request?")) return;
    await deleteDoc(doc(db, "product_requests", id));
    setRequests((prev) => prev.filter((r) => r.id !== id));
  };

  const filteredRequests = useMemo(() => {
    let list = requests;
    if (filterStatus !== "all") {
      list = list.filter((r) => (r.status || "pending") === filterStatus);
    }
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      list = list.filter(
        (r) =>
          (r.productName || "").toLowerCase().includes(q) ||
          (r.userName || "").toLowerCase().includes(q)
      );
    }
    return list;
  }, [requests, filterStatus, searchQuery]);

  if (loading) return <div style={{ padding: 20 }}>Loading...</div>;

  const statusColors = {
    pending: { bg: "#FFF3E0", color: "#E65100" },
    fulfilled: { bg: "#E6F7E6", color: "#2E7D32" },
    rejected: { bg: "#FFE6E6", color: "#C62828" },
  };

  return (
    <div style={{ padding: 20 }}>
      <h1 style={{ fontSize: 24, fontWeight: 900, color: "#0F2B5B", marginBottom: 20 }}>
        Product Requests
      </h1>

      {/* Filters */}
      <div style={{ display: "flex", gap: 12, marginBottom: 20, flexWrap: "wrap" }}>
        <input
          type="text"
          placeholder="Search by product or user..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          style={{ flex: 1, minWidth: 200, padding: "10px 14px", border: "1px solid #ccc", borderRadius: 8, fontSize: 14 }}
        />
        {["all", "pending", "fulfilled", "rejected"].map((status) => (
          <button
            key={status}
            onClick={() => setFilterStatus(status)}
            style={{
              padding: "10px 18px",
              borderRadius: 8,
              border: "1px solid #ccc",
              background: filterStatus === status ? "#0F2B5B" : "#fff",
              color: filterStatus === status ? "#fff" : "#333",
              fontWeight: "bold",
              cursor: "pointer",
              textTransform: "capitalize",
            }}
          >
            {status}
          </button>
        ))}
      </div>

      <div style={{ background: "#fff", borderRadius: 12, padding: 20, boxShadow: "0 2px 8px rgba(0,0,0,0.1)" }}>
        {filteredRequests.length === 0 ? (
          <p style={{ textAlign: "center", color: "#999", padding: 20 }}>No product requests found.</p>
        ) : (
          <table style={{ width: "100%", borderCollapse: "collapse" }}>
            <thead>
              <tr style={{ background: "#F6F3EE", textAlign: "left" }}>
                <th style={{ padding: 12 }}>Product</th>
                <th style={{ padding: 12 }}>Description</th>
                <th style={{ padding: 12 }}>Target Price</th>
                <th style={{ padding: 12 }}>User</th>
                <th style={{ padding: 12 }}>Status</th>
                <th style={{ padding: 12 }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredRequests.map((req) => {
                const status = req.status || "pending";
                const sc = statusColors[status] || statusColors.pending;
                return (
                  <tr key={req.id} style={{ borderBottom: "1px solid #eee" }}>
                    <td style={{ padding: 12, fontWeight: "bold" }}>{req.productName || "Unknown"}</td>
                    <td style={{ padding: 12, color: "#666", maxWidth: 200, overflow: "hidden", textOverflow: "ellipsis" }}>
                      {req.description || "—"}
                    </td>
                    <td style={{ padding: 12 }}>{req.targetPrice ? `QAR ${req.targetPrice}` : "—"}</td>
                    <td style={{ padding: 12 }}>{req.userName || "Unknown"}</td>
                    <td style={{ padding: 12 }}>
                      <span style={{
                        padding: "4px 10px", borderRadius: 6, fontSize: 12, fontWeight: "bold",
                        background: sc.bg, color: sc.color,
                      }}>
                        {status}
                      </span>
                    </td>
                    <td style={{ padding: 12, display: "flex", gap: 6 }}>
                      <button onClick={() => handleStatusChange(req.id, "fulfilled")} style={{ padding: "6px 10px", background: "#2E7D32", color: "#fff", border: "none", borderRadius: 6, cursor: "pointer", fontSize: 12 }}>Fulfill</button>
                      <button onClick={() => handleStatusChange(req.id, "rejected")} style={{ padding: "6px 10px", background: "#C62828", color: "#fff", border: "none", borderRadius: 6, cursor: "pointer", fontSize: 12 }}>Reject</button>
                      <button onClick={() => handleDelete(req.id)} style={{ padding: "6px 10px", background: "#999", color: "#fff", border: "none", borderRadius: 6, cursor: "pointer", fontSize: 12 }}>Delete</button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};

export default ProductRequestsPage;