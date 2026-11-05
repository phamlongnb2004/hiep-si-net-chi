// Service worker tối giản: lưu sẵn trang game để mở nhanh, vẫn lấy bản mới khi có mạng.
const C = 'hsnc-v1';
self.addEventListener('install', e => { self.skipWaiting(); e.waitUntil(caches.open(C).then(c => c.addAll(['/']))); });
self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));
self.addEventListener('fetch', e => {
  const u = new URL(e.request.url);
  if (e.request.method !== 'GET' || u.pathname.startsWith('/api/') || u.pathname === '/ws') return;
  e.respondWith(fetch(e.request).then(r => { if (r.ok && u.origin === location.origin) caches.open(C).then(c => c.put(e.request, r.clone())); return r; }).catch(() => caches.match(e.request)));
});
