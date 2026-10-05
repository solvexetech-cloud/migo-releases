// MIGO — Firebase Cloud Messaging Service Worker
// This file handles push notifications when the app is in background.

importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Firebase config (same as web app)
firebase.initializeApp({
  apiKey: "AIzaSyBRyCun5VvGa2UISPE0nh4XkD-bLw7pyg",
  authDomain: "migo-app-3030e.firebaseapp.com",
  projectId: "migo-app-3030e",
  storageBucket: "migo-app-3030e.firebasestorage.app",
  messagingSenderId: "483248999618",
  appId: "1:483248999618:web:9d6ec925ef062afa92bf5b"
});

const messaging = firebase.messaging();

// Handle background messages (app closed or in background)
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background message:', payload);

  const notificationTitle = payload.notification?.title || 'MIGO';
  const notificationOptions = {
    body: payload.notification?.body || 'You have a new notification',
    icon: '/favicon.png',
    badge: '/favicon.png',
    data: payload.data || {},
    tag: payload.data?.tag || 'migo-notification',
    requireInteraction: false,
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click — open app
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification clicked:', event);
  event.notification.close();

  const urlToOpen = event.notification.data?.url || '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // If app is already open, focus it
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          return client.focus();
        }
      }
      // Otherwise open a new window
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    })
  );
});