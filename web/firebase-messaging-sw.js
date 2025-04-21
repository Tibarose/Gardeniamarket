importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

// Initialize Firebase in the service worker
firebase.initializeApp({
  apiKey: "AIzaSyAP8Jq96CySgpAEcYU13vMiw95vTlKYAEA",
  authDomain: "gardeniatoday-82e68.firebaseapp.com",
  projectId: "gardeniatoday-82e68",
  storageBucket: "gardeniatoday-82e68.firebasestorage.app",
  messagingSenderId: "79911467145",
  appId: "1:79911467145:web:34adee95f50ac65e4eae58",
  measurementId: "G-0KWN75E378"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('Background Message received:', payload);
  const title = payload.notification?.title || 'Default Title';
  const options = {
    body: payload.notification?.body || 'Default Body',
    icon: '/Gardeniamarket/icons/icon-192x192.png', // Adjust path based on your repository structure
    badge: '/Gardeniamarket/icons/badge-72x72.png',
    data: {
      url: payload.webpush?.fcm_options?.link || 'https://tibarose.github.io/Gardeniamarket/',
    },
  };
  return self.registration.showNotification(title, options);
});

// Handle push events (for cases where onBackgroundMessage isn't triggered)
self.addEventListener('push', (event) => {
  console.log('Push event received:', event);
  let data;
  try {
    data = event.data.json();
  } catch (e) {
    console.error('Error parsing push event data:', e);
    return;
  }
  const title = data.notification?.title || 'Default Title';
  const options = {
    body: data.notification?.body || 'Default Body',
    icon: '/Gardeniamarket/icons/icon-192x192.png',
    badge: '/Gardeniamarket/icons/badge-72x72.png',
    data: {
      url: data.webpush?.fcm_options?.link || 'https://tibarose.github.io/Gardeniamarket/',
    },
  };
  event.waitUntil(self.registration.showNotification(title, options));
});

// Handle notification clicks
self.addEventListener('notificationclick', (event) => {
  console.log('Notification clicked:', event);
  event.notification.close();
  const urlToOpen = event.notification.data.url || 'https://tibarose.github.io/Gardeniamarket/';
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url === urlToOpen && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    })
  );
});

// Handle service worker installation
self.addEventListener('install', (event) => {
  console.log('Service Worker installed');
  self.skipWaiting();
});

// Handle service worker activation
self.addEventListener('activate', (event) => {
  console.log('Service Worker activated');
  event.waitUntil(self.clients.claim());
});