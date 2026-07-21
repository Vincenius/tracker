/**
 * Service Worker ohne Build-Schritt: rein zur Laufzeit gecacht, weil die
 * Asset-Namen von Vite gehasht werden und hier nicht bekannt sind.
 *
 *   /assets/*   unveränderlich (Hash im Namen) -> cache-first
 *   Navigation  network-first, offline aus dem Cache
 *   /api/*      niemals cachen
 *
 * Wichtig für den Token: Requests laufen mit `credentials: 'same-origin'`,
 * damit der Cookie mitgeht. Antworten mit 401 landen nie im Cache, sonst
 * würde sich die Sperrseite festsetzen.
 */
const VERSION = 'v1';
const SHELL = `tracker-shell-${VERSION}`;
const ASSETS = `tracker-assets-${VERSION}`;
const FALLBACK = '/index.html';

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches
      .open(SHELL)
      .then((cache) => cache.add(new Request(FALLBACK, { credentials: 'same-origin' })))
      .catch(() => {}) // z.B. abgelaufener Token: Installation trotzdem durchlassen
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(keys.filter((k) => !k.endsWith(VERSION)).map((k) => caches.delete(k))),
      )
      .then(() => self.clients.claim()),
  );
});

async function cacheFirst(request) {
  const hit = await caches.match(request);
  if (hit) return hit;
  const res = await fetch(request);
  if (res.ok) (await caches.open(ASSETS)).put(request, res.clone());
  return res;
}

async function navigate(request) {
  try {
    const res = await fetch(request);
    if (res.ok) (await caches.open(SHELL)).put(FALLBACK, res.clone());
    return res; // auch 401 durchreichen: die Sperrseite muss sichtbar sein
  } catch {
    return (await caches.match(FALLBACK)) ?? Response.error();
  }
}

self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;
  if (url.pathname.startsWith('/api/')) return; // immer direkt ans Netz

  // Der Token-Link muss den Server erreichen, sonst wird der Cookie in dieser
  // Installation nie gesetzt und jeder Sync bliebe bei 401 hängen.
  if (url.searchParams.has('token')) return;

  if (request.mode === 'navigate') return event.respondWith(navigate(request));
  if (url.pathname.startsWith('/assets/')) return event.respondWith(cacheFirst(request));
});
