/**
 * Erzeugt die PWA-Icons aus dem Signature-Griff (vgl. src/components/HoldIcon.tsx).
 * Ohne Dependencies: PNG wird von Hand kodiert, gezeichnet wird per Distanzfeld.
 *
 *   node scripts/make-icons.mjs
 */
import { deflateSync } from 'node:zlib';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const OUT = resolve(dirname(fileURLToPath(import.meta.url)), '..', 'public');

const ROCK = [0x0d, 0x0c, 0x0b]; // --color-rock-950
const TAPE = [0xe4, 0x57, 0x2e]; // --color-tape

// --- PNG ------------------------------------------------------------------

const CRC_TABLE = Array.from({ length: 256 }, (_, n) => {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});

function crc32(buf) {
  let c = 0xffffffff;
  for (const byte of buf) c = CRC_TABLE[(c ^ byte) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
}

/** rgb: Buffer mit size*size*3 Bytes, ohne Alpha (iOS mag opake Icons). */
function encodePng(size, rgb) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(size, 0);
  ihdr.writeUInt32BE(size, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 2; // color type: truecolor
  const stride = size * 3;
  const raw = Buffer.alloc((stride + 1) * size);
  for (let y = 0; y < size; y++) {
    raw[y * (stride + 1)] = 0; // Filter: none
    rgb.copy(raw, y * (stride + 1) + 1, y * stride, (y + 1) * stride);
  }
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

// --- Zeichnen -------------------------------------------------------------

const clamp = (v, lo = 0, hi = 1) => (v < lo ? lo : v > hi ? hi : v);
const mix = (a, b, t) => a.map((v, i) => v + (b[i] - v) * t);

/**
 * Der Griff: eine organisch modulierte Scheibe mit außermittigem Loch.
 * `glyph` ist der Durchmesser der Scheibe als Anteil der Kantenlänge.
 */
function drawIcon(size, glyph) {
  const rgb = Buffer.alloc(size * size * 3);
  const cx = size / 2;
  const cy = size * 0.505;
  const outerR = (size * glyph) / 2;
  const holeR = outerR * 0.38;
  const holeX = cx - outerR * 0.04;
  const holeY = cy + outerR * 0.03;
  const aa = Math.max(size / 220, 0.8); // Kantenglättung, mind. ~1px

  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const px = x + 0.5;
      const py = y + 0.5;

      // Hintergrund: Fels + warmer Schimmer von oben, wie body in index.css
      const gx = (px - size / 2) / (size * 0.62);
      const gy = (py + size * 0.06) / (size * 0.78);
      const glow = clamp(1 - Math.hypot(gx, gy)) ** 2;
      let color = mix(ROCK, TAPE, glow * 0.16);

      // Scheibe mit welliger Kante
      const dx = px - cx;
      const dy = py - cy;
      const d = Math.hypot(dx, dy);
      const a = Math.atan2(dy, dx);
      const wobble = 1 + 0.055 * Math.sin(3 * a + 0.6) + 0.032 * Math.cos(2 * a - 0.4);
      const outer = clamp(0.5 - (d - outerR * wobble) / aa);

      // Loch, minimal gegenläufig moduliert
      const hd = Math.hypot(px - holeX, py - holeY);
      const hw = 1 + 0.05 * Math.sin(2 * a - 1.1);
      const hole = clamp(0.5 - (hd - holeR * hw) / aa);

      const cover = outer * (1 - hole);
      if (cover > 0) color = mix(color, TAPE, cover);

      const i = (y * size + x) * 3;
      rgb[i] = Math.round(color[0]);
      rgb[i + 1] = Math.round(color[1]);
      rgb[i + 2] = Math.round(color[2]);
    }
  }
  return encodePng(size, rgb);
}

// --- Ausgabe --------------------------------------------------------------

mkdirSync(OUT, { recursive: true });

const ICONS = [
  ['icon-192.png', 192, 0.64],
  ['icon-512.png', 512, 0.64],
  // Maskable: der Griff muss in den sicheren Kreis (innere 80 %) passen.
  ['icon-maskable-512.png', 512, 0.46],
  ['apple-touch-icon.png', 180, 0.62],
];

for (const [name, size, glyph] of ICONS) {
  const png = drawIcon(size, glyph);
  writeFileSync(join(OUT, name), png);
  console.log(`${name.padEnd(24)} ${size}×${size}  ${(png.length / 1024).toFixed(1)} kB`);
}
