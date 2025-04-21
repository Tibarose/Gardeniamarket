self.addEventListener('push', (event) => {
  console.log('Push event received:', event);
  const data = event.data.json();
  const title = data.notification.title || 'Default Title';
  const options = {
    body: data.notification.body || 'Default Body',
    icon: '/icons/icon-192x192.png', // Optional: Path to an icon
    badge: '/icons/badge-72x72.png', // Optional: Path to a badge
    data: {
      url: data.webpush?.fcm_options?.link || 'https://tibarose.github.io/Gardeniamarket/', // URL to open on click
    },
  };
  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', (event) => {
  console.log('Notification clicked:', event);
  event.notification.close();
  const urlToOpen = event.notification.data.url || 'https://your-app.com';
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

self.addEventListener('install', (event) => {
  console.log('Service Worker installed');
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  console.log('Service Worker activated');
  event.waitUntil(self.clients.claim());
});