import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: "AIzaSyBRyCunSVyGa2UISPEOhn4xdKd-bUw7pyg",
  authDomain: "migo-app-3030e.firebaseapp.com",
  projectId: "migo-app-3030e",
  storageBucket: "migo-app-3030e.firebasestorage.app",
  messagingSenderId: "483248999618",
  appId: "1:483248999618:web:9d6ec925ef062afa92bf5b"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
export default app;