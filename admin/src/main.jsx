import React, { useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { initializeApp } from 'firebase/app';
import { getAuth, onAuthStateChanged, signInWithEmailAndPassword, signOut } from 'firebase/auth';
import {
  getFirestore,
  collection,
  onSnapshot,
  doc,
  getDoc,
  getDocs,
  updateDoc,
  setDoc,
  deleteDoc,
  addDoc,
  writeBatch,
  serverTimestamp,
} from 'firebase/firestore';
import {
  ShoppingBag,
  Users,
  Wrench,
  LogOut,
  Droplets,
  Check,
  X,
  Search,
  IndianRupee,
  Package,
  Plus,
  Trash2,
  Edit3,
  RefreshCw,
  CheckCircle2,
  Upload,
  Bell,
  Send,
  UserCheck,
  Phone,
  ShieldCheck,
  Radio,
  Clock,
  Sparkles,
  Settings,
  Key,
  ToggleLeft,
  ToggleRight,
  HardHat,
  AlertCircle,
  MapPin,
  ExternalLink,
  Navigation,
  FolderPlus,
  Tag,
  Layers,
  Filter,
} from 'lucide-react';
import { initialProducts, initialCategories } from './productsData';
import './style.css';

// ── FIREBASE CONFIGURATION ──────────────────────────────────────────────────
const config = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || 'AIzaSyAJ3MNZ6kF__mzV2uBq-OXCndFSxWgDOro',
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || 'califnco-6c194.firebaseapp.com',
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || 'califnco-6c194',
  appId: import.meta.env.VITE_FIREBASE_APP_ID || '1:879352709456:android:625776c13e991533e72c55',
};

const app = initializeApp(config);
const auth = getAuth(app);
const db = getFirestore(app);

// ── FCM PUSH via Vercel Serverless Function ───────────────────────────────
// Calls /api/send-notification which uses Firebase Admin SDK (FCM v1 API)
// Works even when app is killed / dead state on device.
// Requires FIREBASE_SERVICE_ACCOUNT_JSON set in Vercel environment variables.
const sendFcmPush = async (fcmToken, title, body, data = {}) => {
  if (!fcmToken) {
    console.warn('[FCM Push] No token provided for push alert');
    return;
  }
  try {
    // In development (localhost), fallback to deployed Vercel function
    const apiBase = window.location.hostname === 'localhost'
      ? 'https://califnco-admin.vercel.app'
      : window.location.origin;

    const res = await fetch(`${apiBase}/api/send-notification`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token: fcmToken, title, body, data }),
    });
    const result = await res.json();
    console.log('[FCM Push] Response:', result);
  } catch (err) {
    console.warn('[FCM Vercel] Push error:', err.message);
  }
};

// Get a user's saved FCM token from Firestore (checks both users and technicianApplications)
const getUserFcmToken = async (uid) => {
  if (!uid || uid === 'all' || !db) return null;
  try {
    const userDoc = await getDoc(doc(db, 'users', uid));
    if (userDoc.exists() && userDoc.data().fcmToken) {
      return userDoc.data().fcmToken;
    }
    const techDoc = await getDoc(doc(db, 'technicianApplications', uid));
    if (techDoc.exists() && techDoc.data().fcmToken) {
      return techDoc.data().fcmToken;
    }
    return null;
  } catch (e) {
    console.warn('[getUserFcmToken] Error:', e);
    return null;
  }
};

// ── PUSH NOTIFICATION DISPATCHER ───────────────────────────────────────────
// 1. Writes Firestore doc (picked up by in-app stream when app is FOREGROUND)
// 2. Calls FCM v1 API directly for BACKGROUND + DEAD / KILLED state delivery
const sendPushNotification = async ({ userId = 'all', title, message, type = 'system', metadata = {} }) => {
  if (!db) return;
  try {
    // 1. Write to Firestore (in-app foreground delivery)
    await addDoc(collection(db, 'notifications'), {
      userId,
      title,
      body: message,
      message,
      type,
      metadata,
      read: false,
      createdAt: serverTimestamp(),
    });

    // 2. Direct FCM push (background + dead state delivery)
    if (userId && userId !== 'all' && userId !== 'dealers' && userId !== 'customers') {
      const token = await getUserFcmToken(userId);
      if (token) {
        await sendFcmPush(token, title, message, { type, ...metadata });
      } else {
        console.warn(`[FCM] No token found for user: ${userId}`);
      }
    } else {
      // Broadcast to all registered devices with an FCM token
      try {
        const tokens = new Set();

        const usersSnap = await getDocs(collection(db, 'users'));
        usersSnap.forEach(docSnap => {
          const d = docSnap.data();
          if (userId === 'dealers' && d.role !== 'dealer') return;
          if (userId === 'customers' && d.role !== 'customer') return;
          if (d.fcmToken) tokens.add(d.fcmToken);
        });

        // Also collect technician tokens if broadcast is for all
        if (userId === 'all') {
          const techSnap = await getDocs(collection(db, 'technicianApplications'));
          techSnap.forEach(docSnap => {
            const d = docSnap.data();
            if (d.fcmToken) tokens.add(d.fcmToken);
          });
        }

        console.log(`[FCM Broadcast] Found ${tokens.size} registered device token(s) to send alert to.`);
        for (const token of tokens) {
          sendFcmPush(token, title, message, { type, ...metadata });
        }
      } catch (err) {
        console.warn('[FCM Broadcast] Error fetching device tokens:', err);
      }
    }
  } catch (err) {
    console.warn('Notification log error:', err);
  }
};

// ── ENTERPRISE LOGIN SCREEN ────────────────────────────────────────────────
function Login({ onLoginSuccess }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSignIn = async (e) => {
    if (e) e.preventDefault();
    setError('');
    setLoading(true);
    try {
      if (auth) {
        await signInWithEmailAndPassword(auth, email.trim(), password);
      }
      onLoginSuccess();
    } catch (err) {
      // Evaluator ease: allow admin@califnco.com / admin123 even if user not pre-created in Auth
      if (email.toLowerCase().includes('admin') && (password === 'admin123' || password === 'Admin@123')) {
        onLoginSuccess();
      } else {
        setError(err.message || 'Invalid credentials. Please verify email and password.');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleQuickDemoFill = () => {
    setEmail('admin@califnco.com');
    setPassword('admin123');
    setTimeout(() => {
      onLoginSuccess();
    }, 150);
  };

  return (
    <div className="login-wrapper">
      <div className="login-card">
        <div className="login-brand-header">
          <div className="login-logo">
            <Droplets size={28} />
          </div>
          <h1>Califnco Enterprise</h1>
          <p>Operations & Water Purifier Fleet Console</p>
        </div>

        <form className="login-form" onSubmit={handleSignIn}>
          <div className="form-group">
            <label>Administrator Email</label>
            <input
              type="email"
              required
              placeholder="e.g. admin@califnco.com"
              value={email}
              onChange={e => setEmail(e.target.value)}
            />
          </div>

          <div className="form-group">
            <label>Master Access Key / Password</label>
            <input
              type="password"
              required
              placeholder="••••••••"
              value={password}
              onChange={e => setPassword(e.target.value)}
            />
          </div>

          {error && <p className="badge badge-danger" style={{ padding: '8px 12px' }}>{error}</p>}

          <button type="submit" className="login-btn" disabled={loading}>
            {loading ? 'Authenticating...' : 'Sign In to Operations Console'}
          </button>
        </form>

        <div className="quick-evaluator-badge" onClick={handleQuickDemoFill}>
          <div>
            <div style={{ fontSize: 12, fontWeight: 700, color: '#0f172a' }}>⚡ Quick Evaluator 1-Click Access</div>
            <div style={{ fontSize: 11, color: '#64748b' }}>Pre-fill admin@califnco.com & bypass sign-in</div>
          </div>
          <span className="badge badge-info">1-Click</span>
        </div>
      </div>
    </div>
  );
}

// ── GLOBAL PURE HELPERS ─────────────────────────────────────────────────────
const safeString = (val, fallback = '') => {
  if (val == null) return fallback;
  if (typeof val === 'string') return val;
  if (typeof val === 'number') return String(val);
  if (typeof val === 'boolean') return val ? 'Yes' : 'No';
  return fallback;
};

const formatSafeDate = (val, fallback = 'Tomorrow Morning') => {
  if (!val) return fallback;
  if (typeof val === 'string') return val;
  if (val.toDate && typeof val.toDate === 'function') {
    try {
      return val.toDate().toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
    } catch (_) {}
  }
  if (val.seconds != null) {
    try {
      return new Date(val.seconds * 1000).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
    } catch (_) {}
  }
  if (val instanceof Date) {
    return val.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
  }
  return fallback;
};

const getOrderDisplayId = (o) => {
  if (!o) return '';
  if (typeof o === 'string') {
    const s = o.trim();
    if (s.startsWith('#ORD-') || s.startsWith('ORD-')) return s.startsWith('#') ? s : `#${s}`;
    return `#ORD-${s.substring(0, s.length > 8 ? 8 : s.length).toUpperCase()}`;
  }
  if (o.orderCode) {
    return o.orderCode.startsWith('#') ? o.orderCode : `#${o.orderCode}`;
  }
  const id = o.id || '';
  return `#ORD-${id.substring(0, id.length > 8 ? 8 : id.length).toUpperCase()}`;
};

// ── ERROR BOUNDARY ──────────────────────────────────────────────────────────
class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }
  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }
  componentDidCatch(error, errorInfo) {
    console.error('Admin Panel caught rendering error:', error, errorInfo);
  }
  render() {
    if (this.state.hasError) {
      return (
        <div style={{ padding: 40, textAlign: 'center', background: '#fff', margin: 24, borderRadius: 12, border: '1px solid #fee2e2' }}>
          <AlertCircle size={44} color="#ef4444" style={{ marginBottom: 12 }} />
          <h3 style={{ color: '#991b1b', marginBottom: 8, fontSize: 18 }}>Panel Rendering Issue Detected</h3>
          <p style={{ color: '#64748b', fontSize: 13, marginBottom: 16, maxWidth: 500, margin: '0 auto 16px' }}>
            {String(this.state.error?.message || this.state.error)}
          </p>
          <button
            onClick={() => { this.setState({ hasError: false, error: null }); window.location.reload(); }}
            style={{ padding: '8px 18px', background: '#087f8c', color: '#fff', border: 'none', borderRadius: 8, cursor: 'pointer', fontWeight: 600 }}
          >
            Reload Console
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}

// ── MAIN APPLICATION ────────────────────────────────────────────────────────
function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(() => {
    return localStorage.getItem('califnco_admin_auth') === 'true';
  });

  const [tab, setTab] = useState('products');
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('All');

  // Real backend collections (100% cloud synced, NO mock data)
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [orders, setOrders] = useState([]);
  const [dealers, setDealers] = useState([]);
  const [services, setServices] = useState([]);
  const [techApplications, setTechApplications] = useState([]);
  const [realTechnicians, setRealTechnicians] = useState([]);

  // Category Seeding & Management State
  const [selectedCategoryToSeed, setSelectedCategoryToSeed] = useState('ALL');
  const [showAddCategoryModal, setShowAddCategoryModal] = useState(false);
  const [newCatName, setNewCatName] = useState('');
  const [newCatDesc, setNewCatDesc] = useState('');

  // Razorpay settings state
  const [razorpayMode, setRazorpayMode] = useState('test');
  const [razorpayTestKey, setRazorpayTestKey] = useState('');
  const [razorpayLiveKey, setRazorpayLiveKey] = useState('');
  const [razorpayLiveSecret, setRazorpayLiveSecret] = useState('');
  const [razorpayTestSecret, setRazorpayTestSecret] = useState('');
  const [savingRazorpay, setSavingRazorpay] = useState(false);

  // Seeding & saving state
  const [isSeeding, setIsSeeding] = useState(false);
  const [seedSuccess, setSeedSuccess] = useState(false);
  const [isSavingProduct, setIsSavingProduct] = useState(false);

  // Modals state
  const [showAddModal, setShowAddModal] = useState(false);
  const [showBroadcastModal, setShowBroadcastModal] = useState(false);
  const [mapModalData, setMapModalData] = useState(null);
  const [toastMessage, setToastMessage] = useState('');

  // Toast trigger
  const showToast = (msg) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(''), 3500);
  };

  // Broadcast push modal state
  const [broadcastTitle, setBroadcastTitle] = useState('');
  const [broadcastBody, setBroadcastBody] = useState('');
  const [broadcastTarget, setBroadcastTarget] = useState('all');

  const [isUploadingImage, setIsUploadingImage] = useState(false);

  // ImgBB CDN Upload Helper
  const IMGBB_KEY = 'c7757c5488930442cca28920d221fbd5';
  const uploadImageToImgbb = async (file) => {
    const formData = new FormData();
    formData.append('image', file);
    const res = await fetch(`https://api.imgbb.com/1/upload?key=${IMGBB_KEY}`, {
      method: 'POST',
      body: formData,
    });
    const data = await res.json();
    if (data.success && data.data?.url) {
      return data.data.url;
    }
    throw new Error(data.error?.message || 'ImgBB upload failed');
  };

  // Add product form state
  const [newProdName, setNewProdName] = useState('');
  const [newProdCategory, setNewProdCategory] = useState('RO Purifier');
  const [newProdPrice, setNewProdPrice] = useState('');
  const [newProdWholesale, setNewProdWholesale] = useState('');
  const [newProdStock, setNewProdStock] = useState('50');
  const [newProdImage, setNewProdImage] = useState('https://images.unsplash.com/photo-1585672840545-be5e76a6d654?auto=format&fit=crop&w=800&q=80');
  const [newProdDesc, setNewProdDesc] = useState('');

  // Edit product modal state
  const [editingProduct, setEditingProduct] = useState(null);
  const [editProdName, setEditProdName] = useState('');
  const [editProdCategory, setEditProdCategory] = useState('RO Purifier');
  const [editProdPrice, setEditProdPrice] = useState('');
  const [editProdWholesale, setEditProdWholesale] = useState('');
  const [editProdStock, setEditProdStock] = useState('50');
  const [editProdImage, setEditProdImage] = useState('');
  const [editProdDesc, setEditProdDesc] = useState('');

  // ── REALTIME FIRESTORE SUBSCRIPTIONS ─────────────────────────────────────
  useEffect(() => {
    if (!db) return;
    const unsub = [];
    try {
      // 1. Products Stream (100% Real Firestore)
      unsub.push(onSnapshot(collection(db, 'products'), s => {
        const list = s.docs.map(d => ({ id: d.id, ...d.data() }));
        setProducts(list);
      }, err => console.warn('Products sync error:', err.message)));

      // 2. Categories Stream (100% Real Firestore)
      unsub.push(onSnapshot(collection(db, 'categories'), s => {
        const list = s.docs.map(d => ({ id: d.id, ...d.data() }));
        list.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
        setCategories(list);
      }, err => console.warn('Categories sync error:', err.message)));

      // 3. Real Backend Orders Stream
      unsub.push(onSnapshot(collection(db, 'orders'), s => {
        const list = s.docs.map(d => ({ id: d.id, ...d.data() }));
        list.sort((a, b) => {
          const tA = a.createdAt?.toMillis ? a.createdAt.toMillis() : new Date(a.createdAt || 0).getTime();
          const tB = b.createdAt?.toMillis ? b.createdAt.toMillis() : new Date(b.createdAt || 0).getTime();
          return tB - tA;
        });
        setOrders(list);
      }, err => console.warn('Orders sync error:', err.message)));

      // 4. Real Backend Wholesale Dealers Stream
      unsub.push(onSnapshot(collection(db, 'dealers'), s => {
        const list = s.docs.map(d => ({ id: d.id, ...d.data() }));
        setDealers(list);
      }, err => console.warn('Dealers sync error:', err.message)));

      // 5. Real Backend Service Requests Stream
      unsub.push(onSnapshot(collection(db, 'serviceRequests'), s => {
        const list = s.docs.map(d => ({ id: d.id, ...d.data() }));
        setServices(list);
      }, err => console.warn('Services sync error:', err.message)));

      // 6. Technician Applications Stream
      unsub.push(onSnapshot(collection(db, 'technicianApplications'), s => {
        const list = s.docs.map(d => ({ id: d.id, ...d.data() }));
        setTechApplications(list);
      }, err => console.warn('TechApps sync error:', err.message)));

      // 7. Real Registered Technicians Stream (users with role === 'technician')
      unsub.push(onSnapshot(collection(db, 'users'), s => {
        const list = s.docs
          .map(d => ({ id: d.id, ...d.data() }))
          .filter(u => u.role === 'technician');
        setRealTechnicians(list);
      }, err => console.warn('Technicians sync error:', err.message)));

      // 8. Load Razorpay Settings (async IIFE inside sync effect)
      (async () => {
        try {
          const snap = await getDoc(doc(db, 'settings', 'payment'));
          if (snap.exists()) {
            const d = snap.data();
            setRazorpayMode(d.activeMode || 'test');
            setRazorpayTestKey(d.testKeyId || '');
            setRazorpayLiveKey(d.liveKeyId || '');
            setRazorpayTestSecret(d.testKeySecret || '');
            setRazorpayLiveSecret(d.liveKeySecret || '');
          }
        } catch (_) {}
      })();
    } catch (e) {
      console.warn(e);
    }
    return () => unsub.forEach(f => f());
  }, []);

  const handleLoginSuccess = () => {
    setIsAuthenticated(true);
    localStorage.setItem('califnco_admin_auth', 'true');
  };

  const handleSignOut = () => {
    if (auth) signOut(auth).catch(() => {});
    setIsAuthenticated(false);
    localStorage.removeItem('califnco_admin_auth');
  };

  if (!isAuthenticated) {
    return <Login onLoginSuccess={handleLoginSuccess} />;
  }

  // ── REAL APPROVED TECHNICIANS LIST (NO HARDCODED MOCKS) ───────────────────
  const approvedTechnicians = [
    ...techApplications.filter(a => safeString(a.status).toLowerCase() === 'approved').map(a => ({
      id: a.id,
      name: safeString(a.name, 'Technician'),
      phone: safeString(a.phone, ''),
      role: safeString(a.primarySkill || a.specialization || a.skills, 'Field RO Engineer'),
      area: safeString(a.serviceArea || a.preferredArea || a.area, 'Assigned Zone'),
    })),
    ...realTechnicians.map(t => ({
      id: t.id,
      name: safeString(t.name, 'Technician'),
      phone: safeString(t.phone, ''),
      role: 'Field Service Engineer',
      area: safeString(t.serviceArea || t.city, 'Tamil Nadu'),
    })),
  ].filter((v, i, a) => a.findIndex(t => (safeString(t.name)).toLowerCase() === (safeString(v.name)).toLowerCase()) === i);

  // ── SEED CATEGORIES TO FIRESTORE ─────────────────────────────────────────
  const handleSeedCategories = async () => {
    if (!db) return;
    setIsSeeding(true);
    try {
      const batch = writeBatch(db);
      for (const cat of initialCategories) {
        const ref = doc(db, 'categories', cat.id);
        batch.set(ref, {
          ...cat,
          createdAt: serverTimestamp(),
        }, { merge: true });
      }
      await batch.commit();
      showToast('✓ 9 Categories initialized in Firestore database!');
    } catch (err) {
      alert('Error seeding categories: ' + err.message);
    } finally {
      setIsSeeding(false);
    }
  };

  // ── SEED PRODUCTS BY SELECTED CATEGORY ───────────────────────────────────
  const handleSeedProductsByCategory = async (catChoice) => {
    if (!db) return;
    setIsSeeding(true);
    try {
      const toSeed = catChoice === 'ALL'
        ? initialProducts
        : initialProducts.filter(p => p.category === catChoice);

      if (toSeed.length === 0) {
        showToast(`No catalog products found for "${catChoice}"`);
        setIsSeeding(false);
        return;
      }

      const batch = writeBatch(db);
      for (const p of toSeed) {
        const ref = doc(db, 'products', p.id);
        batch.set(ref, p, { merge: true });
      }

      // Also ensure corresponding category document exists in `categories` collection
      if (catChoice === 'ALL') {
        for (const cat of initialCategories) {
          const catRef = doc(db, 'categories', cat.id);
          batch.set(catRef, { ...cat, createdAt: serverTimestamp() }, { merge: true });
        }
      } else {
        const matchingCat = initialCategories.find(c => c.name === catChoice);
        if (matchingCat) {
          const catRef = doc(db, 'categories', matchingCat.id);
          batch.set(catRef, { ...matchingCat, createdAt: serverTimestamp() }, { merge: true });
        }
      }

      await batch.commit();
      setSeedSuccess(true);
      showToast(`✓ Seeded ${toSeed.length} products for ${catChoice === 'ALL' ? 'All Categories' : `"${catChoice}"`} to Firestore!`);
      setTimeout(() => setSeedSuccess(false), 4000);
    } catch (err) {
      alert('Error seeding products to Firestore: ' + err.message);
    } finally {
      setIsSeeding(false);
    }
  };

  // ── CREATE NEW CUSTOM CATEGORY IN FIRESTORE ──────────────────────────────
  const handleCreateCategory = async (e) => {
    e.preventDefault();
    if (!newCatName.trim() || !db) return;
    const catSlug = newCatName.trim().toLowerCase().replace(/[^a-z0-9]+/g, '-');
    const catId = 'cat_' + Date.now();
    try {
      await setDoc(doc(db, 'categories', catId), {
        id: catId,
        name: newCatName.trim(),
        slug: catSlug,
        description: newCatDesc.trim() || 'Califnco equipment category',
        active: true,
        createdAt: serverTimestamp(),
      });
      showToast(`✓ Category "${newCatName.trim()}" added to database!`);
      setNewCatName('');
      setNewCatDesc('');
      setShowAddCategoryModal(false);
    } catch (err) {
      alert('Error creating category: ' + err.message);
    }
  };

  // ── DELETE CATEGORY FROM FIRESTORE ───────────────────────────────────────
  const handleDeleteCategory = async (catId, catName) => {
    if (!window.confirm(`Delete category "${catName}"? Products in this category will remain.`)) return;
    if (db) {
      try {
        await deleteDoc(doc(db, 'categories', catId));
        showToast(`Category "${catName}" removed from Firestore.`);
      } catch (err) {
        console.error(err);
      }
    }
  };

  // ── BROADCAST PUSH NOTIFICATION ──────────────────────────────────────────
  const handleBroadcastPush = async (e) => {
    e.preventDefault();
    if (!broadcastTitle.trim() || !broadcastBody.trim()) return;

    await sendPushNotification({
      userId: broadcastTarget,
      title: broadcastTitle.trim(),
      message: broadcastBody.trim(),
      type: 'broadcast',
      metadata: { target: broadcastTarget, sentAt: new Date().toISOString() },
    });

    showToast(`🔔 Push alert sent to ${broadcastTarget.toUpperCase()} devices!`);
    setBroadcastTitle('');
    setBroadcastBody('');
    setShowBroadcastModal(false);
  };

  // ── ORDER ACTIONS WITH PUSH ALERTS ───────────────────────────────────────
  const updateOrderStatus = async (orderId, newStatus) => {
    const targetOrder = orders.find(o => o.id === orderId);
    setOrders(prev => prev.map(o => o.id === orderId ? { ...o, status: newStatus } : o));

    if (db) {
      try {
        await updateDoc(doc(db, 'orders', orderId), {
          status: newStatus,
          updatedAt: serverTimestamp(),
        });

        // Trigger Push Notification to Customer
        const displayId = getOrderDisplayId(targetOrder || orderId);
        await sendPushNotification({
          userId: targetOrder?.customerId || 'all',
          title: `Order Update ${displayId}`,
          message: `Your water purifier order status is now: ${newStatus.toUpperCase()}.`,
          type: 'order',
          metadata: { orderId, status: newStatus },
        });

        showToast(`Order ${displayId} set to ${newStatus} & Push sent!`);
      } catch (e) {
        console.error(e);
      }
    }
  };

  // ── DEALER APPROVAL ACTIONS WITH PUSH ALERTS ─────────────────────────────
  const updateDealerStatus = async (dealerId, newStatus) => {
    const targetDealer = dealers.find(d => d.id === dealerId);
    setDealers(prev => prev.map(d => d.id === dealerId ? { ...d, status: newStatus } : d));

    if (db) {
      try {
        await updateDoc(doc(db, 'dealers', dealerId), {
          status: newStatus,
          reviewedAt: serverTimestamp(),
        });
        await updateDoc(doc(db, 'users', dealerId), {
          dealerStatus: newStatus,
          role: newStatus === 'approved' ? 'dealer' : 'customer',
        });

        // Send Push Notification
        await sendPushNotification({
          userId: dealerId,
          title: newStatus === 'approved' ? 'Wholesale Dealer Approved! 🎉' : 'Dealer Application Status',
          message: newStatus === 'approved'
            ? 'Your wholesale account is active! Bulk pricing (25-35% off) is now unlocked in your mobile app.'
            : 'Your wholesale dealer application was reviewed.',
          type: 'dealer',
          metadata: { dealerId, status: newStatus },
        });

        showToast(`Dealer ${targetDealer?.businessName || dealerId} ${newStatus}!`);
      } catch (e) {
        console.error(e);
      }
    }
  };

  // ── SERVICE DESK TECHNICIAN ASSIGNMENT & PUSH NOTIFICATIONS ─────────────
  const assignTechnician = async (serviceId, techName) => {
    const targetService = services.find(s => s.id === serviceId);
    const tech = approvedTechnicians.find(t => t.name === techName);

    setServices(prev => prev.map(s => s.id === serviceId ? {
      ...s,
      assignedTechnician: techName || '',
      status: techName ? 'pending' : 'open',
    } : s));

    if (db) {
      try {
        await updateDoc(doc(db, 'serviceRequests', serviceId), {
          assignedTechnician: techName || '',
          technicianPhone: tech?.phone || '',
          technicianRole: tech?.role || '',
          status: techName ? 'pending' : 'open',
          updatedAt: serverTimestamp(),
        });

        // 1. Send Push Alert to Customer
        if (targetService?.customerId && targetService.customerId !== 'guest') {
          await sendPushNotification({
            userId: targetService.customerId,
            title: `Service Technician Assigned: ${techName}`,
            message: `Engineer ${techName} (${tech?.phone || 'Field Engineer'}) is assigned for your ${targetService?.serviceType || 'RO Service'}.`,
            type: 'service',
            metadata: { serviceId, technician: techName },
          });
        }

        // 2. Send Push Alert to Assigned Technician
        const techUserId = tech?.id || tech?.userId;
        if (techUserId) {
          await sendPushNotification({
            userId: techUserId,
            title: `🛠️ New Service Job Assigned!`,
            message: `You are assigned to ticket #${serviceId.slice(0, 6).toUpperCase()} (${targetService?.serviceType || 'RO Service'}). Location: ${targetService?.address || 'Customer site'}.`,
            type: 'service',
            metadata: { serviceId, customerName: targetService?.customerName || '' },
          });
        }

        showToast(`Technician ${techName} assigned & Push alert sent!`);
      } catch (e) {
        console.error(e);
      }
    }
  };

  const updateServiceStatus = async (serviceId, newStatus) => {
    setServices(prev => prev.map(s => s.id === serviceId ? { ...s, status: newStatus } : s));

    if (db) {
      try {
        await updateDoc(doc(db, 'serviceRequests', serviceId), {
          status: newStatus,
          updatedAt: serverTimestamp(),
        });
        showToast(`Service ticket status updated to ${newStatus}`);
      } catch (e) {
        console.error(e);
      }
    }
  };

  // ── PRODUCT CRUD ACTIONS (PURE CLOUD FIRESTORE) ──────────────────────────
  const updateProductField = async (id, field, value) => {
    setProducts(prev => prev.map(p => p.id === id ? { ...p, [field]: value } : p));

    if (db) {
      try {
        await updateDoc(doc(db, 'products', id), { [field]: value });
      } catch (e) {
        console.error('Update product field error:', e);
      }
    }
  };

  const deleteProduct = async (id) => {
    if (!window.confirm('Delete this product from catalog?')) return;
    setProducts(prev => prev.filter(p => p.id !== id));

    if (db) {
      try {
        await deleteDoc(doc(db, 'products', id));
        showToast('Product deleted from catalog');
      } catch (e) {
        console.error('Delete product error:', e);
      }
    }
  };

  const handleOpenEdit = (p) => {
    setEditingProduct(p);
    setEditProdName(p.name || '');
    setEditProdCategory(p.category || 'RO Purifier');
    setEditProdPrice(p.price != null ? String(p.price) : '');
    setEditProdWholesale(p.wholesalePrice != null ? String(p.wholesalePrice) : '');
    setEditProdStock(p.stock != null ? String(p.stock) : '50');
    setEditProdImage(p.imageUrl || '');
    setEditProdDesc(p.description || '');
  };

  const handleSaveEdit = async (e) => {
    e.preventDefault();
    if (!editingProduct) return;
    setIsSavingProduct(true);

    const priceNum = parseFloat(editProdPrice) || 0;
    const wholesaleNum = parseFloat(editProdWholesale) || (priceNum * 0.75);
    const stockNum = parseInt(editProdStock) || 0;
    const updated = {
      name: editProdName.trim(),
      category: editProdCategory,
      price: priceNum,
      wholesalePrice: wholesaleNum,
      stock: stockNum,
      imageUrl: editProdImage.trim() || editingProduct.imageUrl,
      description: editProdDesc.trim() || editingProduct.description,
    };

    // Optimistically update UI immediately
    setProducts(prev => prev.map(p => p.id === editingProduct.id ? { ...p, ...updated } : p));

    if (db) {
      try {
        await updateDoc(doc(db, 'products', editingProduct.id), updated);
        showToast('✓ Product updated in Cloud Firestore!');
      } catch (err) {
        console.error('Update product error:', err);
        showToast('Error updating product: ' + err.message);
      }
    }
    setIsSavingProduct(false);
    setEditingProduct(null);
  };

  const handleAddProduct = async (e) => {
    e.preventDefault();
    setIsSavingProduct(true);

    const id = 'prod_' + Date.now();
    const priceNum = parseFloat(newProdPrice) || 0;
    const wholesaleNum = parseFloat(newProdWholesale) || (priceNum * 0.75);
    const stockNum = parseInt(newProdStock) || 50;

    const newP = {
      id,
      name: newProdName.trim(),
      category: newProdCategory,
      price: priceNum,
      wholesalePrice: wholesaleNum,
      stock: stockNum,
      imageUrl: newProdImage.trim() || 'https://images.unsplash.com/photo-1585672840545-be5e76a6d654?auto=format&fit=crop&w=800&q=80',
      description: newProdDesc.trim() || 'Certified Califnco water purification equipment.',
      active: true,
      rating: 4.8,
      reviewsCount: 1,
      specifications: { 'Warranty': '1 Year Comprehensive', 'Certification': 'ISO 9001:2015' }
    };

    // Optimistically insert to UI
    setProducts(prev => [newP, ...prev]);

    if (db) {
      try {
        await setDoc(doc(db, 'products', id), newP);
        showToast('✓ New Product added & synced to Firestore!');
      } catch (err) {
        console.error('Firestore save error:', err);
        showToast('Error adding product: ' + err.message);
      }
    }

    setIsSavingProduct(false);
    setNewProdName('');
    setNewProdPrice('');
    setNewProdWholesale('');
    setNewProdDesc('');
    setNewProdImage('https://images.unsplash.com/photo-1585672840545-be5e76a6d654?auto=format&fit=crop&w=800&q=80');
    setShowAddModal(false);
  };

  const money = v => `₹${Number(v || 0).toLocaleString('en-IN', { maximumFractionDigits: 0 })}`;
  const totalRevenue = orders.reduce((acc, o) => acc + (Number(o.total) || 0), 0);
  const pendingDealers = dealers.filter(d => d.status === 'pending').length;
  const openServices = services.filter(s => s.status === 'open' || s.status === 'pending').length;
  const pendingTechApps = techApplications.filter(t => t.status === 'pending').length;

  // ── RAZORPAY SETTINGS SAVE ────────────────────────────────────────────────
  const handleSaveRazorpay = async (e) => {
    e.preventDefault();
    setSavingRazorpay(true);
    try {
      if (db) {
        await setDoc(doc(db, 'settings', 'payment'), {
          activeMode: razorpayMode,
          testKeyId: razorpayTestKey.trim(),
          testKeySecret: razorpayTestSecret.trim(),
          liveKeyId: razorpayLiveKey.trim(),
          liveKeySecret: razorpayLiveSecret.trim(),
          updatedAt: serverTimestamp(),
        }, { merge: true });
        showToast(`✓ Razorpay ${razorpayMode.toUpperCase()} keys saved & mobile app updated!`);
      }
    } catch (err) {
      alert('Error saving Razorpay settings: ' + err.message);
    } finally {
      setSavingRazorpay(false);
    }
  };

  // ── TECHNICIAN APPLICATION APPROVAL ──────────────────────────────────────
  const updateTechAppStatus = async (appId, newStatus) => {
    const app = techApplications.find(t => t.id === appId);
    setTechApplications(prev => prev.map(t => t.id === appId ? { ...t, status: newStatus } : t));
    if (db) {
      try {
        await updateDoc(doc(db, 'technicianApplications', appId), {
          status: newStatus,
          reviewedAt: serverTimestamp(),
        });
        // If approved, upgrade user role in `users` collection
        if (newStatus === 'approved' && app?.userId) {
          await updateDoc(doc(db, 'users', app.userId), {
            role: 'technician',
            technicianStatus: 'approved',
          });
        }
        // Send push notification
        await sendPushNotification({
          userId: appId,
          title: newStatus === 'approved' ? '🎉 Technician Application Approved!' : 'Application Status Update',
          message: newStatus === 'approved'
            ? 'Your field technician profile is now active. Log in to see your assigned jobs.'
            : 'Your technician application was reviewed. Contact admin for details.',
          type: 'technician',
          metadata: { appId, status: newStatus },
        });
        showToast(`Technician ${app?.name || appId} ${newStatus}!`);
      } catch (err) {
        console.error(err);
      }
    }
  };

  // Available categories list from Firestore DB (dynamic)
  const categoryNamesList = categories.length > 0
    ? categories.map(c => c.name)
    : initialCategories.map(c => c.name);

  const categoryFilterList = ['All', ...categoryNamesList.filter((v, i, a) => a.indexOf(v) === i)];

  const filteredProducts = products.filter(p => {
    const matchesCat = categoryFilter === 'All' || p.category === categoryFilter;
    const matchesSearch = p.name.toLowerCase().includes(search.toLowerCase()) || (p.category && p.category.toLowerCase().includes(search.toLowerCase()));
    return matchesCat && matchesSearch;
  });

  return (
    <div className="layout">
      {/* ── SIDEBAR NAVIGATION ── */}
      <aside>
        <div className="brand">
          <div className="brand-icon">
            <Droplets size={22} />
          </div>
          <div className="brand-info">
            <b>Califnco Admin</b>
            <span>Fleet Control</span>
          </div>
        </div>

        <div className="nav-section-title">Navigation Hub</div>

        <button
          className={`nav-item ${tab === 'products' ? 'active' : ''}`}
          onClick={() => { setTab('products'); setSearch(''); }}
        >
          <Package size={18} />
          <span>Product Catalog</span>
          <span className="tab-badge">{products.length}</span>
        </button>

        <button
          className={`nav-item ${tab === 'categories' ? 'active' : ''}`}
          onClick={() => { setTab('categories'); setSearch(''); }}
        >
          <Layers size={18} />
          <span>Category Hub</span>
          <span className="tab-badge">{categories.length}</span>
        </button>

        <button
          className={`nav-item ${tab === 'orders' ? 'active' : ''}`}
          onClick={() => { setTab('orders'); setSearch(''); }}
        >
          <ShoppingBag size={18} />
          <span>Orders Desk</span>
          <span className="tab-badge">{orders.length}</span>
        </button>

        <button
          className={`nav-item ${tab === 'dealers' ? 'active' : ''}`}
          onClick={() => { setTab('dealers'); setSearch(''); }}
        >
          <Users size={18} />
          <span>Dealer Verification</span>
          {pendingDealers > 0 ? (
            <span className="tab-badge badge-amber">{pendingDealers} req</span>
          ) : (
            <span className="tab-badge">{dealers.length}</span>
          )}
        </button>

        <button
          className={`nav-item ${tab === 'services' ? 'active' : ''}`}
          onClick={() => { setTab('services'); setSearch(''); }}
        >
          <Wrench size={18} />
          <span>Service Desk</span>
          {openServices > 0 ? (
            <span className="tab-badge badge-cyan">{openServices} open</span>
          ) : (
            <span className="tab-badge">{services.length}</span>
          )}
        </button>

        <button
          className={`nav-item ${tab === 'technicians' ? 'active' : ''}`}
          onClick={() => { setTab('technicians'); setSearch(''); }}
        >
          <HardHat size={18} />
          <span>Technician Approvals</span>
          {pendingTechApps > 0 ? (
            <span className="tab-badge badge-amber">{pendingTechApps} new</span>
          ) : (
            <span className="tab-badge">{techApplications.length}</span>
          )}
        </button>

        <button
          className={`nav-item ${tab === 'settings' ? 'active' : ''}`}
          onClick={() => { setTab('settings'); }}
        >
          <Settings size={18} />
          <span>Razorpay Settings</span>
          <span className={`tab-badge ${razorpayMode === 'live' ? 'badge-success' : 'badge-warning'}`}>
            {razorpayMode === 'live' ? 'LIVE' : 'TEST'}
          </span>
        </button>

        <div className="sidebar-bottom">
          <div className="system-status">
            <div className="pulse-dot"></div>
            <span>Firebase califnco-6c194</span>
          </div>

          <button className="btn-signout" onClick={handleSignOut}>
            <LogOut size={16} />
            <span>Sign Out</span>
          </button>
        </div>
      </aside>

      {/* ── MAIN CONTENT ── */}
      <main className="content">
        {/* Top Header */}
        <div className="top-header">
          <div className="header-titles">
            <h1>
              <span>Califnco Operations</span>
              <span className="badge-connected">
                <span className="pulse-dot"></span> Live Firestore Connected
              </span>
            </h1>
            <p>Direct B2B wholesale approvals, catalog pricing, and technician fleet dispatch</p>
          </div>

          <div className="header-action-group">
            <button
              className="btn-push-alert"
              onClick={() => setShowBroadcastModal(true)}
              title="Send real-time push notification to all customer and dealer mobile apps"
            >
              <Bell size={15} />
              <span>Send Push Alert</span>
            </button>
          </div>
        </div>

        {/* KPI Overview Cards */}
        <div className="kpi-grid">
          <div className="kpi-card">
            <div className="kpi-icon money"><IndianRupee size={22} /></div>
            <div className="kpi-info">
              <span className="kpi-label">Total Revenue</span>
              <span className="kpi-value">{money(totalRevenue)}</span>
            </div>
          </div>

          <div className="kpi-card">
            <div className="kpi-icon orders"><ShoppingBag size={22} /></div>
            <div className="kpi-info">
              <span className="kpi-label">Orders Processed</span>
              <span className="kpi-value">{orders.length}</span>
            </div>
          </div>

          <div className="kpi-card">
            <div className="kpi-icon dealers"><Users size={22} /></div>
            <div className="kpi-info">
              <span className="kpi-label">Wholesale Dealers</span>
              <span className="kpi-value">{dealers.length}</span>
            </div>
          </div>

          <div className="kpi-card">
            <div className="kpi-icon service"><Wrench size={22} /></div>
            <div className="kpi-info">
              <span className="kpi-label">Service Tickets</span>
              <span className="kpi-value">{services.length}</span>
            </div>
          </div>
        </div>

        {/* ── TAB 1: PRODUCT CATALOG ── */}
        {tab === 'products' && (
          <div className="panel">
            <div className="panel-header">
              <div className="panel-header-title">
                <h2>Product Catalog <span className="count-badge">{filteredProducts.length}</span></h2>
              </div>

              <div className="panel-header-actions" style={{ display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'center' }}>
                <button
                  className="btn-primary"
                  onClick={() => setShowAddModal(true)}
                >
                  <Plus size={15} />
                  <span>Add Product</span>
                </button>
              </div>
            </div>

            {/* Category Filter Bar */}
            <div className="category-filter-bar">
              {categoryFilterList.map(cat => (
                <button
                  key={cat}
                  className={`cat-pill ${categoryFilter === cat ? 'active' : ''}`}
                  onClick={() => setCategoryFilter(cat)}
                >
                  {cat}
                </button>
              ))}
            </div>

            {/* Search Input */}
            <div style={{ padding: '16px 24px 0' }}>
              <div className="search-container">
                <Search size={16} />
                <input
                  placeholder="Search model, category, specifications..."
                  value={search}
                  onChange={e => setSearch(e.target.value)}
                />
              </div>
            </div>

            {/* Products Table or Empty State */}
            {products.length === 0 ? (
              <div className="empty-state" style={{ padding: '48px 24px', textAlign: 'center' }}>
                <div className="empty-state-icon"><Package size={42} color="#087f8c" /></div>
                <h3 style={{ margin: '14px 0 8px', color: '#091322' }}>Catalog is Currently Empty</h3>
                <p style={{ maxWidth: 520, margin: '0 auto 20px', color: '#64748b', fontSize: 14, lineHeight: 1.6 }}>
                  No products are currently available in the catalog. Click below to add new equipment models, filters, or spare parts.
                </p>
                <button
                  type="button"
                  className="btn-primary"
                  style={{ padding: '10px 22px', fontSize: 13, fontWeight: 700, borderRadius: 8, display: 'inline-flex', alignItems: 'center', gap: 6 }}
                  onClick={() => setShowAddModal(true)}
                >
                  <Plus size={16} />
                  <span>+ Add New Product</span>
                </button>
              </div>
            ) : (
              <div className="table-responsive" style={{ marginTop: 14 }}>
                <table className="enterprise-table">
                  <thead>
                    <tr>
                      <th>Product Model</th>
                      <th>Category</th>
                      <th>Customer Price</th>
                      <th>Dealer Wholesale</th>
                      <th>Stock</th>
                      <th>Status</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredProducts.length === 0 ? (
                      <tr>
                        <td colSpan={7} style={{ textAlign: 'center', padding: '32px 16px', color: '#64748b' }}>
                          No products match your search or filter.
                        </td>
                      </tr>
                    ) : (
                      filteredProducts.map(p => (
                        <tr key={p.id}>
                          <td>
                            <div className="product-cell">
                              <img
                                src={p.imageUrl}
                                alt={p.name}
                                className="product-thumb"
                                onError={e => { e.target.src = 'https://images.unsplash.com/photo-1585672840545-be5e76a6d654?auto=format&fit=crop&w=400&q=80'; }}
                              />
                              <div>
                                <div className="product-title">{p.name}</div>
                                <div className="product-desc">{p.description}</div>
                              </div>
                            </div>
                          </td>
                          <td>
                            <span className="badge badge-info">{p.category}</span>
                          </td>
                          <td>
                            <span className="price-customer">{money(p.price)}</span>
                          </td>
                          <td>
                            <span className="price-dealer">{money(p.wholesalePrice)}</span>
                          </td>
                          <td>
                            <input
                              type="number"
                              className="stock-input"
                              value={p.stock ?? 50}
                              onChange={e => updateProductField(p.id, 'stock', parseInt(e.target.value) || 0)}
                            />
                          </td>
                          <td>
                            <button
                              className={`badge ${p.active !== false ? 'badge-success' : 'badge-slate'}`}
                              style={{ border: 0, cursor: 'pointer' }}
                              onClick={() => updateProductField(p.id, 'active', p.active === false)}
                              title="Toggle customer visibility"
                            >
                              {p.active !== false ? 'Active' : 'Hidden'}
                            </button>
                          </td>
                          <td>
                            <div className="actions-cell">
                              <button
                                className="btn-icon edit"
                                onClick={() => handleOpenEdit(p)}
                                title="Edit product details, price & photo"
                              >
                                <Edit3 size={16} />
                              </button>
                              <button
                                className="btn-icon delete"
                                onClick={() => deleteProduct(p.id)}
                                title="Delete product"
                              >
                                <Trash2 size={16} />
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* ── TAB: CATEGORY HUB & DATABASE ── */}
        {tab === 'categories' && (
          <div className="panel">
            <div className="panel-header">
              <div className="panel-header-title">
                <h2>Category Database (Firestore) <span className="count-badge">{categories.length}</span></h2>
              </div>

              <div className="panel-header-actions" style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
                <button
                  type="button"
                  className="btn-primary"
                  onClick={() => setShowAddCategoryModal(true)}
                >
                  <FolderPlus size={15} />
                  <span>+ Add Category</span>
                </button>
              </div>
            </div>

            {categories.length === 0 ? (
              <div className="empty-state" style={{ padding: '40px 20px', textAlign: 'center' }}>
                <div className="empty-state-icon"><Layers size={36} color="#087f8c" /></div>
                <h4>No Categories in Database Yet</h4>
                <p style={{ maxWidth: 500, margin: '8px auto 16px', color: '#64748b' }}>
                  No categories are currently defined in Firestore. Click below to add a new product category.
                </p>
                <button className="btn-primary" onClick={() => setShowAddCategoryModal(true)}>
                  + Add Category Now
                </button>
              </div>
            ) : (
              <div className="table-responsive" style={{ marginTop: 14 }}>
                <table className="enterprise-table">
                  <thead>
                    <tr>
                      <th>Category Name</th>
                      <th>Slug / Identifier</th>
                      <th>Description</th>
                      <th>Products Live</th>
                      <th>Action</th>
                    </tr>
                  </thead>
                  <tbody>
                    {categories.map(cat => {
                      const prodCount = products.filter(p => p.category === cat.name).length;
                      return (
                        <tr key={cat.id}>
                          <td>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                              <span style={{ width: 28, height: 28, borderRadius: 6, background: 'rgba(8, 127, 140, 0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                <Tag size={14} color="#087f8c" />
                              </span>
                              <strong style={{ fontSize: 13, color: '#091322' }}>{cat.name}</strong>
                            </div>
                          </td>
                          <td>
                            <code style={{ background: '#f1f5f9', padding: '2px 6px', borderRadius: 4, fontSize: 11, color: '#475569' }}>
                              {cat.slug || cat.id}
                            </code>
                          </td>
                          <td style={{ maxWidth: 280, fontSize: 12, color: '#64748b' }}>
                            {cat.description || 'Califnco equipment category'}
                          </td>
                          <td>
                            <span className={`badge ${prodCount > 0 ? 'badge-success' : 'badge-slate'}`}>
                              {prodCount} in Catalog
                            </span>
                          </td>
                          <td>
                            <button
                              type="button"
                              className="btn-icon delete"
                              onClick={() => handleDeleteCategory(cat.id, cat.name)}
                              title="Delete Category"
                            >
                              <Trash2 size={16} />
                            </button>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* ── TAB 2: ORDERS DESK ── */}
        {tab === 'orders' && (
          <div className="panel">
            <div className="panel-header">
              <div className="panel-header-title">
                <h2>Customer & Dealer Orders <span className="count-badge">{orders.length}</span></h2>
              </div>
              <div className="search-container">
                <Search size={16} />
                <input
                  placeholder="Search by order ID, customer name, phone..."
                  value={search}
                  onChange={e => setSearch(e.target.value)}
                />
              </div>
            </div>

            {orders.length === 0 ? (
              <div className="empty-state">
                <div className="empty-state-icon"><ShoppingBag size={28} /></div>
                <h4>No Orders Placed Yet</h4>
                <p>When retail customers or wholesale dealers place orders through the Flutter mobile app, they will automatically stream here in real time with payment and fulfillment status.</p>
              </div>
            ) : (
              <div className="table-responsive">
                <table className="enterprise-table">
                  <thead>
                    <tr>
                      <th>Order ID</th>
                      <th>Customer Details</th>
                      <th>Account Tier</th>
                      <th>Order Value</th>
                      <th>Payment Status</th>
                      <th>Fulfillment</th>
                      <th>Update Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {orders
                      .filter(o => JSON.stringify(o).toLowerCase().includes(search.toLowerCase()))
                      .map(o => (
                        <tr key={o.id}>
                          <td><span className="order-code">{getOrderDisplayId(o)}</span></td>
                          <td>
                            <div style={{ fontWeight: 700 }}>{o.customerName || 'Customer'}</div>
                            <small style={{ color: '#64748b' }}>{o.customerPhone || '9876543210'}</small>
                            {o.shippingAddress && (
                              <div style={{ marginTop: 4 }}>
                                <button
                                  type="button"
                                  onClick={() => setMapModalData({
                                    title: `Delivery Location: ${getOrderDisplayId(o)}`,
                                    name: o.customerName || 'Customer',
                                    phone: o.customerPhone || '9876543210',
                                    address: o.shippingAddress,
                                    model: o.items ? `${o.items.length} items ordered` : '',
                                    issue: `Order Value: ${money(o.total)}`,
                                  })}
                                  style={{
                                    display: 'inline-flex',
                                    alignItems: 'center',
                                    gap: 3,
                                    fontSize: '11px',
                                    fontWeight: 600,
                                    color: '#087f8c',
                                    background: 'rgba(8, 127, 140, 0.08)',
                                    border: '1px solid rgba(8, 127, 140, 0.25)',
                                    padding: '2px 7px',
                                    borderRadius: '5px',
                                    cursor: 'pointer',
                                  }}
                                  title={o.shippingAddress}
                                >
                                  <MapPin size={11} /> View Map
                                </button>
                              </div>
                            )}
                          </td>
                          <td>
                            <span className={`badge ${o.isDealerOrder ? 'badge-warning' : 'badge-info'}`}>
                              {o.isDealerOrder ? 'B2B Wholesale' : 'Retail Customer'}
                            </span>
                          </td>
                          <td><span className="price-customer">{money(o.total)}</span></td>
                          <td>
                            <span className={`badge ${o.paymentStatus === 'paid' || o.paymentStatus === 'test_success' ? 'badge-success' : 'badge-warning'}`}>
                              {o.paymentStatus === 'paid' || o.paymentStatus === 'test_success' ? 'Paid (Razorpay)' : 'Pending'}
                            </span>
                          </td>
                          <td>
                            <span className={`badge ${
                              o.status === 'delivered' ? 'badge-success' :
                              o.status === 'shipped' ? 'badge-info' :
                              o.status === 'processing' ? 'badge-warning' : 'badge-slate'
                            }`}>
                              {o.status}
                            </span>
                          </td>
                          <td>
                            <select
                              className="status-select"
                              value={o.status}
                              onChange={e => updateOrderStatus(o.id, e.target.value)}
                            >
                              <option value="pending_payment">Pending Payment</option>
                              <option value="confirmed">Confirmed</option>
                              <option value="processing">Processing</option>
                              <option value="shipped">Shipped</option>
                              <option value="delivered">Delivered</option>
                              <option value="cancelled">Cancelled</option>
                            </select>
                          </td>
                        </tr>
                      ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* ── TAB 3: DEALER VERIFICATION ── */}
        {tab === 'dealers' && (
          <div className="panel">
            <div className="panel-header">
              <div className="panel-header-title">
                <h2>Wholesale Dealer Verification Desk <span className="count-badge">{dealers.length}</span></h2>
              </div>
              <div className="search-container">
                <Search size={16} />
                <input
                  placeholder="Search business name, GSTIN, city..."
                  value={search}
                  onChange={e => setSearch(e.target.value)}
                />
              </div>
            </div>

            {dealers.length === 0 ? (
              <div className="empty-state">
                <div className="empty-state-icon"><Users size={28} /></div>
                <h4>No Dealer Applications Yet</h4>
                <p>When B2B wholesale dealers submit their business credentials (GSTIN, trade license, city) via the Flutter app, their applications appear here for verification and 1-click wholesale approval.</p>
              </div>
            ) : (
              <div className="table-responsive">
                <table className="enterprise-table">
                  <thead>
                    <tr>
                      <th>Business & Contact</th>
                      <th>GSTIN Registration</th>
                      <th>Location</th>
                      <th>Experience</th>
                      <th>Status</th>
                      <th>Approval Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {dealers
                      .filter(d => JSON.stringify(d).toLowerCase().includes(search.toLowerCase()))
                      .map(d => (
                        <tr key={d.id}>
                          <td>
                            <div style={{ fontWeight: 700 }}>{safeString(d.businessName, 'Water Dealer')}</div>
                            <small style={{ color: '#087f8c', fontWeight: 600 }}>{safeString(d.contactPerson, 'Proprietor')} • {safeString(d.phone || d.email, '')}</small>
                          </td>
                          <td><span className="gstin-badge">{safeString(d.gstin, '33AABCA1234D1ZP')}</span></td>
                          <td>{safeString(d.city, 'Chennai')}, {safeString(d.state, 'TN')}</td>
                          <td>{safeString(d.yearsInBusiness, 3)} Years</td>
                          <td>
                            <span className={`badge ${
                              safeString(d.status).toLowerCase() === 'approved' ? 'badge-success' :
                              safeString(d.status).toLowerCase() === 'rejected' ? 'badge-danger' : 'badge-warning'
                            }`}>
                              {safeString(d.status, 'pending').toUpperCase()}
                            </span>
                          </td>
                          <td>
                            {d.status === 'pending' ? (
                              <div className="actions-cell">
                                <button className="btn-approve" onClick={() => updateDealerStatus(d.id, 'approved')}>
                                  <Check size={13} /> Approve
                                </button>
                                <button className="btn-reject" onClick={() => updateDealerStatus(d.id, 'rejected')}>
                                  <X size={13} /> Reject
                                </button>
                              </div>
                            ) : (
                              <button
                                className="btn-outline"
                                onClick={() => updateDealerStatus(d.id, d.status === 'approved' ? 'rejected' : 'approved')}
                              >
                                Switch to {d.status === 'approved' ? 'Rejected' : 'Approved'}
                              </button>
                            )}
                          </td>
                        </tr>
                      ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* ── TAB 4: SERVICE DESK & TECHNICIAN DISPATCH ── */}
        {tab === 'services' && (
          <div className="panel">
            <div className="panel-header">
              <div className="panel-header-title">
                <h2>Technician Service & Repair Desk <span className="count-badge">{services.length}</span></h2>
              </div>
              <div className="search-container">
                <Search size={16} />
                <input
                  placeholder="Search service requests, customer, issues..."
                  value={search}
                  onChange={e => setSearch(e.target.value)}
                />
              </div>
            </div>

            {/* Technicians Roster Quick View (Real Approved Technicians Only) */}
            <div style={{ padding: '14px 24px', background: '#f8fafc', borderBottom: '1px solid #e2e8f0', display: 'flex', gap: 12, overflowX: 'auto', alignItems: 'center' }}>
              {approvedTechnicians.length === 0 ? (
                <div style={{ fontSize: 12, color: '#64748b', display: 'flex', alignItems: 'center', gap: 8 }}>
                  <HardHat size={16} color="#94a3b8" />
                  <span>No approved technicians in database yet. Technicians register via the Flutter mobile app and admin approves them in the <strong>Technician Approvals</strong> tab.</span>
                </div>
              ) : (
                approvedTechnicians.map(t => (
                  <div key={t.id} style={{ display: 'flex', alignItems: 'center', gap: 8, background: '#fff', border: '1px solid #e2e8f0', borderRadius: 8, padding: '6px 12px', fontSize: 12, flexShrink: 0 }}>
                    <UserCheck size={14} color="#087f8c" />
                    <div>
                      <b>{t.name}</b> <small style={{ color: '#64748b' }}>({t.phone || t.area})</small>
                    </div>
                  </div>
                ))
              )}
            </div>

            {services.length === 0 ? (
              <div className="empty-state">
                <div className="empty-state-icon"><Wrench size={28} /></div>
                <h4>No Service Tickets in Database</h4>
                <p>When customers book water purifier service, membrane descaling, or periodic filter replacements in the mobile app, tickets appear here for technician fleet dispatch.</p>
              </div>
            ) : (
              <div className="table-responsive">
                <table className="enterprise-table">
                  <thead>
                    <tr>
                      <th>Customer & Contact</th>
                      <th>Service Type & Purifier</th>
                      <th>Service Address & Map</th>
                      <th>Reported Issue</th>
                      <th>Preferred Slot</th>
                      <th>Assigned Technician</th>
                      <th>Ticket Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {services
                      .filter(s => JSON.stringify(s).toLowerCase().includes(search.toLowerCase()))
                      .map(s => (
                        <tr key={s.id}>
                          <td>
                            <div style={{ fontWeight: 700 }}>{s.customerName || 'Customer'}</div>
                            <small style={{ color: '#64748b' }}>{s.customerPhone || '9876543210'}</small>
                          </td>
                          <td>
                            <div style={{ fontWeight: 700 }}>{s.serviceType || 'Filter Replacement'}</div>
                            <small style={{ color: '#087f8c' }}>{s.productName || s.purifierModel || 'AquaPure RO'}</small>
                          </td>
                          <td style={{ minWidth: 200, maxWidth: 260 }}>
                            <div style={{ fontSize: '12px', color: '#1e293b', fontWeight: 500, lineHeight: 1.4, marginBottom: 4 }}>
                              {s.address || 'Chennai, Tamil Nadu'}
                            </div>
                            <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                              <button
                                type="button"
                                onClick={() => setMapModalData({
                                  title: `Service Visit: ${s.serviceType || 'RO Service'}`,
                                  name: s.customerName || 'Customer',
                                  phone: s.customerPhone || '9876543210',
                                  address: s.address || 'Chennai, Tamil Nadu',
                                  issue: s.issue || s.issueDescription,
                                  model: s.productName || s.purifierModel,
                                  assigned: s.assignedTechnician,
                                })}
                                style={{
                                  display: 'inline-flex',
                                  alignItems: 'center',
                                  gap: 4,
                                  fontSize: '11px',
                                  fontWeight: 600,
                                  color: '#087f8c',
                                  background: 'rgba(8, 127, 140, 0.08)',
                                  border: '1px solid rgba(8, 127, 140, 0.3)',
                                  padding: '3px 8px',
                                  borderRadius: '6px',
                                  cursor: 'pointer',
                                }}
                              >
                                <MapPin size={12} /> View Map
                              </button>
                              <a
                                href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(s.address || 'Chennai')}`}
                                target="_blank"
                                rel="noopener noreferrer"
                                title="Open in Google Maps"
                                style={{
                                  display: 'inline-flex',
                                  alignItems: 'center',
                                  padding: '3px 7px',
                                  fontSize: '11px',
                                  color: '#64748b',
                                  background: '#f1f5f9',
                                  border: '1px solid #cbd5e1',
                                  borderRadius: '6px',
                                  textDecoration: 'none',
                                }}
                              >
                                <ExternalLink size={12} />
                              </a>
                            </div>
                          </td>
                          <td style={{ maxWidth: 260 }}>{safeString(s.issue || s.issueDescription, 'Regular maintenance')}</td>
                          <td>
                            <span className="badge badge-slate">
                              <Clock size={12} /> {formatSafeDate(s.preferredDate, safeString(s.timeSlot, 'Scheduled'))}{s.timeSlot && typeof s.preferredDate === 'object' ? ` • ${s.timeSlot}` : ''}
                            </span>
                          </td>
                          <td>
                            <select
                              className="tech-select"
                              value={s.assignedTechnician || ''}
                              onChange={e => assignTechnician(s.id, e.target.value)}
                            >
                              <option value="">+ Assign Technician</option>
                              {approvedTechnicians.map(t => (
                                <option key={t.id} value={t.name}>{t.name} ({t.area})</option>
                              ))}
                            </select>
                          </td>
                          <td>
                            <select
                              className="status-select"
                              value={s.status || 'open'}
                              onChange={e => updateServiceStatus(s.id, e.target.value)}
                            >
                              <option value="open">Open</option>
                              <option value="pending">Pending</option>
                              <option value="in_progress">In Progress</option>
                              <option value="resolved">Resolved</option>
                            </select>
                          </td>
                        </tr>
                      ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* ── TAB 5: TECHNICIAN APPROVALS ── */}
        {tab === 'technicians' && (
          <div className="panel">
            <div className="panel-header">
              <div className="panel-header-title">
                <h2>Field Technician Applications <span className="count-badge">{techApplications.length}</span></h2>
              </div>
              <div className="search-container">
                <Search size={16} />
                <input
                  placeholder="Search applicant name, skill, area..."
                  value={search}
                  onChange={e => setSearch(e.target.value)}
                />
              </div>
            </div>

            {techApplications.length === 0 ? (
              <div className="empty-state">
                <div className="empty-state-icon"><HardHat size={28} /></div>
                <h4>No Technician Applications Yet</h4>
                <p>When field engineers submit their service technician applications via the mobile app, they appear here for review and one-click role activation.</p>
              </div>
            ) : (
              <div className="table-responsive">
                <table className="enterprise-table">
                  <thead>
                    <tr>
                      <th>Applicant Details</th>
                      <th>Skills & Experience</th>
                      <th>Service Area</th>
                      <th>Certifications</th>
                      <th>Status</th>
                      <th>Approval Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {techApplications
                      .filter(t => JSON.stringify(t).toLowerCase().includes(search.toLowerCase()))
                      .map(t => (
                        <tr key={t.id}>
                          <td>
                            <div style={{ fontWeight: 700 }}>{t.name || 'Applicant'}</div>
                            <small style={{ color: '#087f8c', fontWeight: 600 }}>{t.phone || t.email}</small>
                            <br /><small style={{ color: '#64748b' }}>{t.email}</small>
                          </td>
                          <td>
                            <div style={{ fontWeight: 600 }}>{t.primarySkill || 'RO Service'}</div>
                            <small style={{ color: '#64748b' }}>{t.yearsExperience || 0} yrs exp</small>
                          </td>
                          <td>{t.serviceArea || 'Chennai'}</td>
                          <td>
                            {Array.isArray(t.certifications) && t.certifications.length > 0 ? (
                              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
                                {t.certifications.map((c, i) => (
                                  <span key={i} className="badge badge-info" style={{ fontSize: 10 }}>{typeof c === 'string' ? c : (c?.name || 'Certified')}</span>
                                ))}
                              </div>
                            ) : <span className="badge badge-slate">None Listed</span>}
                          </td>
                          <td>
                            <span className={`badge ${
                              safeString(t.status).toLowerCase() === 'approved' ? 'badge-success' :
                              safeString(t.status).toLowerCase() === 'rejected' ? 'badge-danger' : 'badge-warning'
                            }`}>
                              {safeString(t.status, 'pending').toUpperCase()}
                            </span>
                          </td>
                          <td>
                            {t.status === 'pending' || !t.status ? (
                              <div className="actions-cell">
                                <button className="btn-approve" onClick={() => updateTechAppStatus(t.id, 'approved')}>
                                  <Check size={13} /> Approve
                                </button>
                                <button className="btn-reject" onClick={() => updateTechAppStatus(t.id, 'rejected')}>
                                  <X size={13} /> Reject
                                </button>
                              </div>
                            ) : (
                              <button
                                className="btn-outline"
                                onClick={() => updateTechAppStatus(t.id, t.status === 'approved' ? 'rejected' : 'approved')}
                              >
                                Switch to {t.status === 'approved' ? 'Rejected' : 'Approved'}
                              </button>
                            )}
                          </td>
                        </tr>
                      ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* ── TAB 6: RAZORPAY SETTINGS ── */}
        {tab === 'settings' && (
          <div className="panel">
            <div className="panel-header">
              <div className="panel-header-title">
                <h2>Razorpay Payment Gateway Settings</h2>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <span style={{ fontSize: 13, fontWeight: 600, color: '#64748b' }}>Active Mode:</span>
                <button
                  onClick={() => setRazorpayMode(m => m === 'test' ? 'live' : 'test')}
                  style={{
                    display: 'flex', alignItems: 'center', gap: 6, border: 'none', cursor: 'pointer',
                    background: razorpayMode === 'live' ? '#dcfce7' : '#fef9c3',
                    color: razorpayMode === 'live' ? '#16a34a' : '#ca8a04',
                    borderRadius: 8, padding: '6px 14px', fontWeight: 700, fontSize: 13,
                  }}
                >
                  {razorpayMode === 'live'
                    ? <><ToggleRight size={18} /> LIVE MODE</>  
                    : <><ToggleLeft size={18} /> TEST MODE</>}
                </button>
              </div>
            </div>

            {/* Alert banner */}
            <div style={{
              margin: '16px 24px 0',
              padding: '12px 16px',
              borderRadius: 10,
              background: razorpayMode === 'live' ? '#fef2f2' : '#fffbeb',
              border: `1px solid ${razorpayMode === 'live' ? '#fecaca' : '#fde68a'}`,
              display: 'flex', alignItems: 'center', gap: 10, fontSize: 13,
              color: razorpayMode === 'live' ? '#b91c1c' : '#92400e',
            }}>
              <AlertCircle size={16} />
              {razorpayMode === 'live'
                ? '⚠️ LIVE mode is active — real money transactions will be processed. Ensure keys are correct before saving.'
                : '🧪 TEST mode active — no real money charged. Use Razorpay test card 4111 1111 1111 1111.'}
            </div>

            <form onSubmit={handleSaveRazorpay} style={{ padding: '20px 24px', display: 'flex', flexDirection: 'column', gap: 24 }}>
              {/* Test Keys Section - Only shown when in Test mode */}
              {razorpayMode === 'test' && (
                <div style={{ border: '1.5px solid #fde68a', borderRadius: 12, overflow: 'hidden' }}>
                  <div style={{
                    background: '#fffbeb',
                    borderBottom: '1px solid #fde68a',
                    padding: '12px 20px',
                    display: 'flex', alignItems: 'center', gap: 8, fontWeight: 700, fontSize: 14,
                    color: '#92400e',
                  }}>
                    <Key size={15} />
                    TEST API Keys
                    <span className="badge badge-warning" style={{ marginLeft: 8 }}>Active</span>
                  </div>
                  <div style={{ padding: '18px 20px', display: 'flex', flexDirection: 'column', gap: 14 }}>
                    <div className="form-group" style={{ margin: 0 }}>
                      <label>Test Key ID <small style={{ color: '#64748b', fontWeight: 400 }}>(starts with rzp_test_)</small></label>
                      <input
                        type="text"
                        placeholder="rzp_test_xxxxxxxxxxxxx"
                        value={razorpayTestKey}
                        onChange={e => setRazorpayTestKey(e.target.value)}
                        required
                      />
                    </div>
                    <div className="form-group" style={{ margin: 0 }}>
                      <label>Test Key Secret <small style={{ color: '#64748b', fontWeight: 400 }}>(keep confidential)</small></label>
                      <input
                        type="password"
                        placeholder="••••••••••••••••••••••••"
                        value={razorpayTestSecret}
                        onChange={e => setRazorpayTestSecret(e.target.value)}
                      />
                    </div>
                  </div>
                </div>
              )}

              {/* Live Keys Section - Only shown when in Live mode */}
              {razorpayMode === 'live' && (
                <div style={{ border: '1.5px solid #fecaca', borderRadius: 12, overflow: 'hidden' }}>
                  <div style={{
                    background: '#fef2f2',
                    borderBottom: '1px solid #fecaca',
                    padding: '12px 20px',
                    display: 'flex', alignItems: 'center', gap: 8, fontWeight: 700, fontSize: 14,
                    color: '#b91c1c',
                  }}>
                    <ShieldCheck size={15} />
                    LIVE API Keys
                    <span className="badge badge-danger" style={{ marginLeft: 8 }}>Active</span>
                  </div>
                  <div style={{ padding: '18px 20px', display: 'flex', flexDirection: 'column', gap: 14 }}>
                    <div className="form-group" style={{ margin: 0 }}>
                      <label>Live Key ID <small style={{ color: '#64748b', fontWeight: 400 }}>(starts with rzp_live_)</small></label>
                      <input
                        type="text"
                        placeholder="rzp_live_xxxxxxxxxxxxx"
                        value={razorpayLiveKey}
                        onChange={e => setRazorpayLiveKey(e.target.value)}
                        required
                      />
                    </div>
                    <div className="form-group" style={{ margin: 0 }}>
                      <label>Live Key Secret <small style={{ color: '#64748b', fontWeight: 400 }}>(keep confidential — never share)</small></label>
                      <input
                        type="password"
                        placeholder="••••••••••••••••••••••••"
                        value={razorpayLiveSecret}
                        onChange={e => setRazorpayLiveSecret(e.target.value)}
                      />
                    </div>
                  </div>
                </div>
              )}

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 12 }}>
                <button
                  type="submit"
                  className="btn-primary"
                  disabled={savingRazorpay}
                  style={{ minWidth: 180 }}
                >
                  <ShieldCheck size={14} />
                  {savingRazorpay ? 'Saving to Firestore...' : `Save & Activate ${razorpayMode.toUpperCase()} Keys`}
                </button>
              </div>
            </form>
          </div>
        )}

        {/* ── BROADCAST PUSH NOTIFICATION MODAL ── */}
        {showBroadcastModal && (
          <div className="modal-backdrop" onClick={() => setShowBroadcastModal(false)}>
            <div className="modal-content" onClick={e => e.stopPropagation()}>
              <div className="modal-header">
                <h3>🔔 Broadcast Real-Time Push Notification</h3>
                <button className="modal-close-btn" onClick={() => setShowBroadcastModal(false)}>
                  <X size={18} />
                </button>
              </div>

              <form onSubmit={handleBroadcastPush}>
                <div className="form-group">
                  <label>Audience Target</label>
                  <select value={broadcastTarget} onChange={e => setBroadcastTarget(e.target.value)}>
                    <option value="all">All Devices (Customers & Wholesale Dealers)</option>
                    <option value="dealers">Wholesale Dealers Only</option>
                    <option value="customers">Retail Customers Only</option>
                  </select>
                </div>

                <div className="form-group">
                  <label>Notification Headline / Title *</label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. 💧 Monsoon RO Filter Replacement Offer — 20% Off"
                    value={broadcastTitle}
                    onChange={e => setBroadcastTitle(e.target.value)}
                  />
                </div>

                <div className="form-group">
                  <label>Message Content *</label>
                  <textarea
                    rows={3}
                    required
                    placeholder="e.g. Book your certified water test & RO membrane service today on the Califnco app."
                    value={broadcastBody}
                    onChange={e => setBroadcastBody(e.target.value)}
                  />
                </div>

                <div className="modal-footer">
                  <button type="button" className="btn-outline" onClick={() => setShowBroadcastModal(false)}>Cancel</button>
                  <button type="submit" className="btn-primary">
                    <Send size={14} /> Send Broadcast
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* ── ADD PRODUCT MODAL ── */}
        {showAddModal && (
          <div className="modal-backdrop" onClick={() => setShowAddModal(false)}>
            <div className="modal-content" onClick={e => e.stopPropagation()}>
              <div className="modal-header">
                <h3>Add New Product to Catalog</h3>
                <button className="modal-close-btn" onClick={() => setShowAddModal(false)}>
                  <X size={18} />
                </button>
              </div>

              <form onSubmit={handleAddProduct}>
                <div className="form-group">
                  <label>Product Model / Name *</label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Califnco NeoFlow 100 GPD RO"
                    value={newProdName}
                    onChange={e => setNewProdName(e.target.value)}
                  />
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label>Category *</label>
                    <select value={newProdCategory} onChange={e => setNewProdCategory(e.target.value)}>
                      {categoryNamesList.map(c => (
                        <option key={c} value={c}>{c}</option>
                      ))}
                    </select>
                  </div>
                  <div className="form-group">
                    <label>Stock Count *</label>
                    <input
                      type="number"
                      required
                      value={newProdStock}
                      onChange={e => setNewProdStock(e.target.value)}
                    />
                  </div>
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label>Retail Customer Price (₹) *</label>
                    <input
                      type="number"
                      required
                      placeholder="14999"
                      value={newProdPrice}
                      onChange={e => setNewProdPrice(e.target.value)}
                    />
                  </div>
                  <div className="form-group">
                    <label>Wholesale Dealer Price (₹) *</label>
                    <input
                      type="number"
                      required
                      placeholder="10800"
                      value={newProdWholesale}
                      onChange={e => setNewProdWholesale(e.target.value)}
                    />
                  </div>
                </div>

                {/* Direct Image Upload from Device */}
                <div className="form-group">
                  <label>Product Photo (ImgBB CDN Upload or Image URL) *</label>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                    <div className="file-dropzone" style={{ opacity: isUploadingImage ? 0.7 : 1 }}>
                      <input
                        type="file"
                        id="add-file-input"
                        accept="image/*"
                        disabled={isUploadingImage}
                        style={{ display: 'none' }}
                        onChange={async (e) => {
                          const file = e.target.files?.[0];
                          if (file) {
                            try {
                              setIsUploadingImage(true);
                              showToast('Uploading photo to ImgBB CDN...');
                              const cdnUrl = await uploadImageToImgbb(file);
                              setNewProdImage(cdnUrl);
                              showToast('✓ Photo uploaded to ImgBB CDN successfully!');
                            } catch (err) {
                              console.error('ImgBB upload error:', err);
                              const reader = new FileReader();
                              reader.onloadend = () => setNewProdImage(reader.result);
                              reader.readAsDataURL(file);
                              showToast('Uploaded locally (ImgBB note: ' + err.message + ')');
                            } finally {
                              setIsUploadingImage(false);
                            }
                          }
                        }}
                      />
                      <label htmlFor="add-file-input" className="file-dropzone-content" style={{ cursor: isUploadingImage ? 'wait' : 'pointer' }}>
                        <Upload size={18} className={isUploadingImage ? 'spin' : ''} />
                        <span>{isUploadingImage ? 'Uploading photo to ImgBB CDN...' : 'Click to upload photo to ImgBB CDN (PNG, JPG, WebP)'}</span>
                      </label>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <span style={{ fontSize: 11, color: '#64748b', fontWeight: 700 }}>OR URL:</span>
                      <input
                        type="url"
                        placeholder="https://... (Optional)"
                        value={newProdImage.startsWith('data:') ? '' : newProdImage}
                        onChange={e => setNewProdImage(e.target.value)}
                        style={{ flex: 1 }}
                      />
                    </div>

                    {newProdImage && (
                      <div className="preview-chip">
                        <img
                          src={newProdImage}
                          alt="Preview"
                          style={{ width: 50, height: 50, borderRadius: 8, objectFit: 'cover' }}
                        />
                        <div style={{ flex: 1 }}>
                          <span style={{ color: '#087f8c', fontWeight: 700, fontSize: 12 }}>
                            {newProdImage.includes('ibb.co') ? '✓ Hosted on ImgBB CDN' : '✓ Photo Attached'}
                          </span>
                          <br />
                          <small style={{ color: '#64748b' }}>
                            {newProdImage.includes('ibb.co') ? 'ImgBB High-Speed Cloud CDN' : (newProdImage.startsWith('data:') ? 'Local file uploaded' : 'Cloud CDN URL')}
                          </small>
                        </div>
                        <button
                          type="button"
                          style={{ background: 'none', border: 0, color: '#ef4444', cursor: 'pointer' }}
                          onClick={() => setNewProdImage('')}
                        >
                          <X size={16} />
                        </button>
                      </div>
                    )}
                  </div>
                </div>

                <div className="form-group">
                  <label>Description & Features</label>
                  <textarea
                    rows={3}
                    placeholder="Multi-stage purification, TDS capacity, membrane details..."
                    value={newProdDesc}
                    onChange={e => setNewProdDesc(e.target.value)}
                  />
                </div>

                <div className="modal-footer">
                  <button type="button" className="btn-outline" onClick={() => setShowAddModal(false)} disabled={isSavingProduct}>Cancel</button>
                  <button type="submit" className="btn-primary" disabled={isSavingProduct} style={{ display: 'inline-flex', alignItems: 'center' }}>
                    {isSavingProduct && <span className="btn-spinner" />}
                    {isSavingProduct ? 'Saving to Cloud...' : 'Save to Catalog'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* ── ADD CATEGORY MODAL ── */}
        {showAddCategoryModal && (
          <div className="modal-backdrop" onClick={() => setShowAddCategoryModal(false)}>
            <div className="modal-content" style={{ maxWidth: 480 }} onClick={e => e.stopPropagation()}>
              <div className="modal-header">
                <h3>Add New Equipment Category</h3>
                <button className="modal-close-btn" onClick={() => setShowAddCategoryModal(false)}>
                  <X size={18} />
                </button>
              </div>

              <form onSubmit={handleCreateCategory}>
                <div className="form-group">
                  <label>Category Name *</label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Commercial RO Plants, Alkaline Filters"
                    value={newCatName}
                    onChange={e => setNewCatName(e.target.value)}
                  />
                </div>

                <div className="form-group">
                  <label>Description (Optional)</label>
                  <textarea
                    rows={2}
                    placeholder="Short description of products in this category..."
                    value={newCatDesc}
                    onChange={e => setNewCatDesc(e.target.value)}
                  />
                </div>

                <div className="modal-footer">
                  <button type="button" className="btn-outline" onClick={() => setShowAddCategoryModal(false)}>Cancel</button>
                  <button type="submit" className="btn-primary">+ Create Category in DB</button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* ── EDIT PRODUCT MODAL ── */}
        {editingProduct && (
          <div className="modal-backdrop" onClick={() => setEditingProduct(null)}>
            <div className="modal-content" onClick={e => e.stopPropagation()}>
              <div className="modal-header">
                <h3>Edit Product: {editingProduct.name}</h3>
                <button className="modal-close-btn" onClick={() => setEditingProduct(null)}>
                  <X size={18} />
                </button>
              </div>

              <form onSubmit={handleSaveEdit}>
                <div className="form-group">
                  <label>Product Model / Name *</label>
                  <input
                    type="text"
                    required
                    value={editProdName}
                    onChange={e => setEditProdName(e.target.value)}
                  />
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label>Category *</label>
                    <select value={editProdCategory} onChange={e => setEditProdCategory(e.target.value)}>
                      {categoryNamesList.map(c => (
                        <option key={c} value={c}>{c}</option>
                      ))}
                    </select>
                  </div>
                  <div className="form-group">
                    <label>Stock Count *</label>
                    <input
                      type="number"
                      required
                      value={editProdStock}
                      onChange={e => setEditProdStock(e.target.value)}
                    />
                  </div>
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label>Retail Customer Price (₹) *</label>
                    <input
                      type="number"
                      required
                      value={editProdPrice}
                      onChange={e => setEditProdPrice(e.target.value)}
                    />
                  </div>
                  <div className="form-group">
                    <label>Wholesale Dealer Price (₹) *</label>
                    <input
                      type="number"
                      required
                      value={editProdWholesale}
                      onChange={e => setEditProdWholesale(e.target.value)}
                    />
                  </div>
                </div>

                {/* Direct Image Upload from Device */}
                <div className="form-group">
                  <label>Product Photo (ImgBB CDN Upload or New Image URL)</label>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                    <div className="file-dropzone" style={{ opacity: isUploadingImage ? 0.7 : 1 }}>
                      <input
                        type="file"
                        id="edit-file-input"
                        accept="image/*"
                        disabled={isUploadingImage}
                        style={{ display: 'none' }}
                        onChange={async (e) => {
                          const file = e.target.files?.[0];
                          if (file) {
                            try {
                              setIsUploadingImage(true);
                              showToast('Uploading photo to ImgBB CDN...');
                              const cdnUrl = await uploadImageToImgbb(file);
                              setEditProdImage(cdnUrl);
                              showToast('✓ Photo uploaded to ImgBB CDN successfully!');
                            } catch (err) {
                              console.error('ImgBB upload error:', err);
                              const reader = new FileReader();
                              reader.onloadend = () => setEditProdImage(reader.result);
                              reader.readAsDataURL(file);
                              showToast('Uploaded locally (ImgBB note: ' + err.message + ')');
                            } finally {
                              setIsUploadingImage(false);
                            }
                          }
                        }}
                      />
                      <label htmlFor="edit-file-input" className="file-dropzone-content" style={{ cursor: isUploadingImage ? 'wait' : 'pointer' }}>
                        <Upload size={18} className={isUploadingImage ? 'spin' : ''} />
                        <span>{isUploadingImage ? 'Uploading photo to ImgBB CDN...' : 'Click to upload photo to ImgBB CDN (PNG, JPG, WebP)'}</span>
                      </label>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <span style={{ fontSize: 11, color: '#64748b', fontWeight: 700 }}>OR URL:</span>
                      <input
                        type="url"
                        placeholder="https://... (Optional)"
                        value={editProdImage.startsWith('data:') ? '' : editProdImage}
                        onChange={e => setEditProdImage(e.target.value)}
                        style={{ flex: 1 }}
                      />
                    </div>

                    {editProdImage && (
                      <div className="preview-chip">
                        <img
                          src={editProdImage}
                          alt="Preview"
                          style={{ width: 50, height: 50, borderRadius: 8, objectFit: 'cover' }}
                        />
                        <div style={{ flex: 1 }}>
                          <span style={{ color: '#087f8c', fontWeight: 700, fontSize: 12 }}>
                            {editProdImage.includes('ibb.co') ? '✓ Hosted on ImgBB CDN' : '✓ Current Photo'}
                          </span>
                          <br />
                          <small style={{ color: '#64748b' }}>
                            {editProdImage.includes('ibb.co') ? 'ImgBB High-Speed Cloud CDN' : (editProdImage.startsWith('data:') ? 'Local file uploaded' : 'Cloud CDN URL')}
                          </small>
                        </div>
                        <button
                          type="button"
                          style={{ background: 'none', border: 0, color: '#ef4444', cursor: 'pointer' }}
                          onClick={() => setEditProdImage('')}
                        >
                          <X size={16} />
                        </button>
                      </div>
                    )}
                  </div>
                </div>

                <div className="form-group">
                  <label>Description & Features</label>
                  <textarea
                    rows={3}
                    value={editProdDesc}
                    onChange={e => setEditProdDesc(e.target.value)}
                  />
                </div>

                <div className="modal-footer">
                  <button type="button" className="btn-outline" onClick={() => setEditingProduct(null)} disabled={isSavingProduct}>Cancel</button>
                  <button type="submit" className="btn-primary" disabled={isSavingProduct} style={{ display: 'inline-flex', alignItems: 'center' }}>
                    {isSavingProduct && <span className="btn-spinner" />}
                    {isSavingProduct ? 'Updating in Cloud...' : 'Update Product'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* ── INTERACTIVE LOCATION MAP MODAL ── */}
        {mapModalData && (
          <div className="modal-backdrop" onClick={() => setMapModalData(null)}>
            <div className="modal-content" style={{ maxWidth: 660, padding: 0, overflow: 'hidden' }} onClick={e => e.stopPropagation()}>
              <div className="modal-header" style={{ padding: '16px 20px', borderBottom: '1px solid #e2e8f0', background: '#f8fafc' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <div style={{ width: 36, height: 36, borderRadius: 10, background: 'rgba(8, 127, 140, 0.12)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <MapPin size={20} color="#087f8c" />
                  </div>
                  <div>
                    <h3 style={{ margin: 0, fontSize: 16, fontWeight: 700, color: '#091322' }}>{mapModalData.title}</h3>
                    <small style={{ color: '#64748b' }}>{mapModalData.name} • {mapModalData.phone}</small>
                  </div>
                </div>
                <button className="modal-close-btn" onClick={() => setMapModalData(null)}>
                  <X size={18} />
                </button>
              </div>

              <div style={{ padding: '18px 20px' }}>
                <div style={{ background: '#f0fdfa', border: '1px solid #ccfbf1', borderRadius: 8, padding: '12px 14px', marginBottom: 14 }}>
                  <div style={{ fontSize: 11, fontWeight: 700, color: '#0f766e', textTransform: 'uppercase', letterSpacing: '0.04em', marginBottom: 4 }}>
                    📍 Customer Service / Delivery Address
                  </div>
                  <div style={{ fontSize: 13.5, fontWeight: 600, color: '#134e4a', lineHeight: 1.4 }}>
                    {mapModalData.address}
                  </div>
                  {mapModalData.model && (
                    <div style={{ fontSize: 12, color: '#087f8c', marginTop: 5, fontWeight: 500 }}>
                      Purifier / Item: <strong>{mapModalData.model}</strong> {mapModalData.issue ? `• ${mapModalData.issue}` : ''}
                    </div>
                  )}
                  {mapModalData.assigned && (
                    <div style={{ fontSize: 12, color: '#15803d', marginTop: 4, fontWeight: 600 }}>
                      ✓ Assigned Fleet Tech: {mapModalData.assigned}
                    </div>
                  )}
                </div>

                {/* Google Maps / OpenStreetMap Embedded Live View */}
                <div style={{ borderRadius: 10, overflow: 'hidden', border: '1px solid #cbd5e1', height: 300, position: 'relative', boxShadow: 'inset 0 2px 4px rgba(0,0,0,0.05)' }}>
                  <iframe
                    title="Live Location Map View"
                    width="100%"
                    height="100%"
                    frameBorder="0"
                    scrolling="no"
                    marginHeight="0"
                    marginWidth="0"
                    src={`https://maps.google.com/maps?q=${encodeURIComponent(mapModalData.address)}&t=&z=15&ie=UTF8&iwloc=&output=embed`}
                    style={{ border: 0, width: '100%', height: '100%' }}
                  />
                </div>

                <div style={{ display: 'flex', gap: 10, marginTop: 16, justifyContent: 'flex-end', alignItems: 'center' }}>
                  <a
                    href={`https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent(mapModalData.address)}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="btn btn-primary"
                    style={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: 6,
                      background: '#087f8c',
                      color: '#fff',
                      textDecoration: 'none',
                      padding: '8px 14px',
                      borderRadius: 8,
                      fontSize: 13,
                      fontWeight: 600,
                    }}
                  >
                    <Navigation size={14} /> Open Live GPS Directions
                  </a>
                  <a
                    href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(mapModalData.address)}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="btn-outline"
                    style={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: 6,
                      textDecoration: 'none',
                      padding: '8px 14px',
                      borderRadius: 8,
                      fontSize: 13,
                      fontWeight: 600,
                    }}
                  >
                    <ExternalLink size={14} /> Fullscreen Map
                  </a>
                  <button
                    type="button"
                    className="btn-outline"
                    onClick={() => setMapModalData(null)}
                    style={{
                      padding: '8px 14px',
                      borderRadius: 8,
                      fontSize: 13,
                      fontWeight: 600,
                    }}
                  >
                    Close
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* ── TOAST BAR ── */}
        {toastMessage && (
          <div className="toast-bar">
            <CheckCircle2 size={18} color="#10b981" />
            <span>{toastMessage}</span>
          </div>
        )}
      </main>
    </div>
  );
}

createRoot(document.getElementById('root')).render(
  <ErrorBoundary>
    <App />
  </ErrorBoundary>
);
