/**
 * Winziges Backend: liefert die gebaute App aus und speichert die Daten
 * in einer einzigen JSON-Datei. Keine Datenbank, keine Dependencies.
 *
 *   GET  /api/data     -> aktueller Stand
 *   POST /api/sync     -> Stand des Clients einmischen, gemergten Stand zurückgeben
 *   PUT  /api/data     -> Stand hart ersetzen (Import / Zurücksetzen)
 *
 * Optionaler Schutz: Wenn TRACKER_TOKEN gesetzt ist, ist *alles* gesperrt —
 * auch die App selbst, nicht nur /api/. Ein Request gilt als berechtigt, wenn
 * er den Header `x-tracker-token`, den Cookie `tracker_token` oder `?token=…`
 * mitbringt. Beim Treffer über `?token=…` wird der Cookie gesetzt und der
 * Parameter aus der URL entfernt; damit muss jedes Gerät nur einmal den Link
 * mit Token öffnen.
 */
import { createServer } from 'node:http';
import { timingSafeEqual } from 'node:crypto';
import { createReadStream } from 'node:fs';
import { mkdir, readFile, rename, stat, writeFile } from 'node:fs/promises';
import { dirname, extname, join, normalize, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const PORT = Number(process.env.PORT ?? 3025);
const DATA_FILE = process.env.DATA_FILE ?? join(ROOT, 'data', 'tracker.json');
const STATIC_DIR = process.env.STATIC_DIR ?? join(ROOT, 'dist');
const TOKEN = process.env.TRACKER_TOKEN ?? '';

const EMPTY = { version: 1, sessions: [], seenBadges: [], seenLevel: 1, deleted: [] };

const COOKIE_NAME = 'tracker_token';
const COOKIE_MAX_AGE = 60 * 60 * 24 * 365;

const DENIED_PAGE = `<!doctype html>
<html lang="de"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>401 — Zugriff gesperrt</title>
<style>
  body{margin:0;min-height:100vh;display:grid;place-items:center;background:#111;color:#eee;
       font:16px/1.5 system-ui,sans-serif}
  div{text-align:center;padding:2rem}
  h1{margin:0 0 .5rem;font-size:1.25rem}
  p{margin:0;opacity:.6;font-size:.875rem}
</style>
<div><h1>Zugriff gesperrt</h1><p>Diese Seite braucht ein gültiges Token.</p></div>
</html>`;

/**
 * Icons bleiben ohne Token erreichbar. Sie enthalten keine Daten, und der
 * Browser holt Manifest-Icons je nach Plattform ohne Cookie — sonst schlägt
 * die Installation fehl. Das Manifest selbst ist *nicht* frei: darin steht
 * der Token.
 */
const PUBLIC_FILES = new Set([
  '/favicon.svg',
  '/icon-192.png',
  '/icon-512.png',
  '/icon-maskable-512.png',
  '/apple-touch-icon.png',
]);

/** start_url trägt den Token, weil iOS der installierten App einen eigenen
 *  Cookie-Speicher gibt — der Cookie aus Safari zählt dort nicht. */
function manifest() {
  return {
    id: '/',
    name: 'TRACKER — Sportroutine',
    short_name: 'Tracker',
    description: 'Boulder- und Heimtraining festhalten.',
    start_url: TOKEN ? `/?token=${encodeURIComponent(TOKEN)}` : '/',
    scope: '/',
    display: 'standalone',
    orientation: 'portrait',
    background_color: '#0d0c0b',
    theme_color: '#0d0c0b',
    lang: 'de',
    icons: [
      { src: '/icon-192.png', sizes: '192x192', type: 'image/png' },
      { src: '/icon-512.png', sizes: '512x512', type: 'image/png' },
      { src: '/icon-maskable-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
    ],
  };
}

/** Konstante Laufzeit, damit der Token nicht zeichenweise erraten werden kann. */
function tokenMatches(value) {
  if (typeof value !== 'string' || value.length === 0) return false;
  const given = Buffer.from(value);
  const want = Buffer.from(TOKEN);
  return given.length === want.length && timingSafeEqual(given, want);
}

function cookieToken(req) {
  for (const part of (req.headers.cookie ?? '').split(';')) {
    const eq = part.indexOf('=');
    if (eq < 0) continue;
    if (part.slice(0, eq).trim() !== COOKIE_NAME) continue;
    try {
      return decodeURIComponent(part.slice(eq + 1).trim());
    } catch {
      return '';
    }
  }
  return '';
}

function setCookieHeader(req) {
  // Secure nur hinter HTTPS setzen, sonst verwirft der Browser den Cookie
  // beim direkten Aufruf über http://<server>:3025.
  const proto = String(req.headers['x-forwarded-proto'] ?? '').split(',')[0].trim();
  const secure = proto === 'https' ? '; Secure' : '';
  return `${COOKIE_NAME}=${encodeURIComponent(TOKEN)}; Path=/; Max-Age=${COOKIE_MAX_AGE}; HttpOnly; SameSite=Lax${secure}`;
}

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.png': 'image/png',
  '.ico': 'image/x-icon',
};

function sanitize(raw) {
  const d = raw && typeof raw === 'object' ? raw : {};
  const sessions = Array.isArray(d.sessions)
    ? d.sessions.filter(
        (s) =>
          s &&
          typeof s.id === 'string' &&
          ['boulder', 'home', 'fallback'].includes(s.type) &&
          ['full', 'min'].includes(s.intensity) &&
          typeof s.date === 'string' &&
          typeof s.ts === 'number',
      )
    : [];
  const strings = (v) => (Array.isArray(v) ? v.filter((x) => typeof x === 'string') : []);
  return {
    version: 1,
    sessions,
    seenBadges: strings(d.seenBadges),
    seenLevel: typeof d.seenLevel === 'number' ? d.seenLevel : 1,
    deleted: strings(d.deleted),
  };
}

/** Union der Einheiten, Tombstones gewinnen. Muss zu src/lib/merge.ts passen. */
function merge(a, b) {
  const deleted = new Set([...a.deleted, ...b.deleted]);
  const byId = new Map();
  for (const s of [...a.sessions, ...b.sessions]) {
    if (!deleted.has(s.id)) byId.set(s.id, s);
  }
  return {
    version: 1,
    sessions: [...byId.values()].sort((x, y) => x.ts - y.ts),
    seenBadges: [...new Set([...a.seenBadges, ...b.seenBadges])],
    seenLevel: Math.max(a.seenLevel, b.seenLevel),
    deleted: [...deleted],
  };
}

let writeQueue = Promise.resolve();

async function readData() {
  try {
    return sanitize(JSON.parse(await readFile(DATA_FILE, 'utf8')));
  } catch {
    return { ...EMPTY };
  }
}

/** Serialisiertes Schreiben: read-modify-write kann sich nicht überholen. */
function updateData(fn) {
  const next = writeQueue.then(async () => {
    const current = await readData();
    const result = sanitize(await fn(current));
    await mkdir(dirname(DATA_FILE), { recursive: true });
    const tmp = `${DATA_FILE}.tmp`;
    await writeFile(tmp, JSON.stringify(result, null, 2), 'utf8');
    await rename(tmp, DATA_FILE); // atomar, kein halb geschriebenes Backup
    return result;
  });
  writeQueue = next.catch(() => {});
  return next;
}

function send(res, status, body, headers = {}) {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
    ...headers,
  });
  res.end(payload);
}

async function readBody(req, limit = 2_000_000) {
  const chunks = [];
  let size = 0;
  for await (const chunk of req) {
    size += chunk.length;
    if (size > limit) throw new Error('too large');
    chunks.push(chunk);
  }
  return chunks.length ? JSON.parse(Buffer.concat(chunks).toString('utf8')) : {};
}

async function serveStatic(req, res, pathname) {
  const rel = normalize(decodeURIComponent(pathname)).replace(/^(\.\.[/\\])+/, '');
  let file = join(STATIC_DIR, rel);
  if (!file.startsWith(STATIC_DIR)) file = join(STATIC_DIR, 'index.html');

  try {
    const info = await stat(file);
    if (info.isDirectory()) throw new Error('dir');
  } catch {
    file = join(STATIC_DIR, 'index.html'); // SPA-Fallback
  }

  const ext = extname(file);
  const immutable = rel.startsWith('/assets/');
  res.writeHead(200, {
    'content-type': MIME[ext] ?? 'application/octet-stream',
    'cache-control': immutable ? 'public, max-age=31536000, immutable' : 'no-cache',
  });
  createReadStream(file)
    .on('error', () => {
      res.writeHead(404);
      res.end();
    })
    .pipe(res);
}

const server = createServer(async (req, res) => {
  const url = new URL(req.url ?? '/', `http://${req.headers.host ?? 'localhost'}`);
  const isApi = url.pathname.startsWith('/api/');

  if (PUBLIC_FILES.has(url.pathname) && (req.method === 'GET' || req.method === 'HEAD')) {
    return serveStatic(req, res, url.pathname);
  }

  if (TOKEN) {
    const fromQuery = url.searchParams.get('token');
    const ok =
      tokenMatches(req.headers['x-tracker-token']) ||
      tokenMatches(cookieToken(req)) ||
      tokenMatches(fromQuery);

    if (!ok) {
      if (isApi) return send(res, 401, { error: 'token' });
      res.writeHead(401, {
        'content-type': 'text/html; charset=utf-8',
        'cache-control': 'no-store',
      });
      return res.end(req.method === 'HEAD' ? undefined : DENIED_PAGE);
    }

    // Frisch per Link berechtigt: Cookie setzen und den Token aus der URL werfen,
    // damit er nicht in History, Lesezeichen oder Referrern hängen bleibt.
    if (fromQuery !== null && !isApi) {
      url.searchParams.delete('token');
      res.writeHead(302, {
        location: `${url.pathname}${url.search}`,
        'set-cookie': setCookieHeader(req),
        'cache-control': 'no-store',
      });
      return res.end();
    }
  }

  if (url.pathname === '/manifest.webmanifest') {
    // no-store: enthält den Token, gehört in keinen Proxy-Cache.
    res.writeHead(200, {
      'content-type': 'application/manifest+json; charset=utf-8',
      'cache-control': 'no-store',
    });
    return res.end(req.method === 'HEAD' ? undefined : JSON.stringify(manifest()));
  }

  if (!isApi) {
    if (req.method !== 'GET' && req.method !== 'HEAD') {
      res.writeHead(405);
      return res.end();
    }
    return serveStatic(req, res, url.pathname);
  }

  try {
    if (url.pathname === '/api/data' && req.method === 'GET') {
      return send(res, 200, await readData());
    }
    if (url.pathname === '/api/sync' && req.method === 'POST') {
      const incoming = sanitize(await readBody(req));
      return send(res, 200, await updateData((current) => merge(current, incoming)));
    }
    if (url.pathname === '/api/data' && req.method === 'PUT') {
      const incoming = sanitize(await readBody(req));
      return send(res, 200, await updateData(() => incoming));
    }
    return send(res, 404, { error: 'not found' });
  } catch (err) {
    return send(res, 400, { error: String(err instanceof Error ? err.message : err) });
  }
});

server.listen(PORT, () => {
  console.log(`Tracker läuft auf http://localhost:${PORT}`);
  console.log(`Daten: ${DATA_FILE}`);
  console.log(
    TOKEN
      ? 'Zugriffsschutz: aktiv (TRACKER_TOKEN) — App und API gesperrt, neue Geräte einmal mit ?token=… öffnen'
      : 'Zugriffsschutz: aus — setze TRACKER_TOKEN in .env, wenn der Port öffentlich erreichbar ist',
  );
});
