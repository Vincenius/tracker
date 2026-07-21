/**
 * Winziges Backend: liefert die gebaute App aus und speichert die Daten
 * in einer einzigen JSON-Datei. Keine Datenbank, keine Dependencies.
 *
 *   GET  /api/data     -> aktueller Stand
 *   POST /api/sync     -> Stand des Clients einmischen, gemergten Stand zurückgeben
 *   PUT  /api/data     -> Stand hart ersetzen (Import / Zurücksetzen)
 *
 * Optionaler Schutz: Wenn TRACKER_TOKEN gesetzt ist, muss jeder Request den
 * Header `x-tracker-token` mitschicken.
 */
import { createServer } from 'node:http';
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

  if (!url.pathname.startsWith('/api/')) {
    if (req.method !== 'GET' && req.method !== 'HEAD') {
      res.writeHead(405);
      return res.end();
    }
    return serveStatic(req, res, url.pathname);
  }

  if (TOKEN && req.headers['x-tracker-token'] !== TOKEN) {
    return send(res, 401, { error: 'token' });
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
      ? 'Zugriffsschutz: aktiv (TRACKER_TOKEN) — neue Geräte einmal mit ?token=… öffnen'
      : 'Zugriffsschutz: aus — setze TRACKER_TOKEN in .env, wenn der Port öffentlich erreichbar ist',
  );
});
