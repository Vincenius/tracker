/**
 * Konfetti ohne Dependency: ein Canvas über allem, ein paar Dutzend
 * Papierschnipsel mit Schwerkraft, danach räumt es sich selbst wieder ab.
 *
 * Bewusst klein gehalten — die App hat außer React keine Abhängigkeiten, und
 * dafür lohnt keine Bibliothek. Wer `prefers-reduced-motion` gesetzt hat,
 * bekommt gar nichts: die Feier ist Zugabe, nie Information.
 */

/** Standardfarben: Tape, Kreide und die Grade-Skala. */
const DEFAULT_VARS = [
  '--color-tape',
  '--color-grade-yellow',
  '--color-grade-green',
  '--color-chalk',
  '--color-grade-purple',
];

export interface BurstOptions {
  /** Ursprung in Viewport-Anteilen (0..1). Ohne Angabe: Mitte, etwas erhöht. */
  x?: number;
  y?: number;
  /** Anzahl Schnipsel. */
  count?: number;
  /** Farben als CSS-Werte; ohne Angabe die Palette der App. */
  colors?: string[];
  /** Anfangsgeschwindigkeit — größer heißt weiter. */
  power?: number;
  /** Öffnungswinkel nach oben, in Radiant. */
  spread?: number;
}

interface Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  w: number;
  h: number;
  color: string;
  spin: number;
  angle: number;
  life: number;
  age: number;
}

const GRAVITY = 0.32;
const DRAG = 0.987;

let canvas: HTMLCanvasElement | null = null;
let ctx: CanvasRenderingContext2D | null = null;
let particles: Particle[] = [];
let frame = 0;

function reducedMotion(): boolean {
  return window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ?? false;
}

/** `var(--color-tape)` → `#e4572e`; Canvas kennt keine CSS-Variablen. */
function resolve(color: string): string {
  const name = /^var\((--[\w-]+)\)$/.exec(color.trim())?.[1];
  if (!name) return color;
  return getComputedStyle(document.documentElement).getPropertyValue(name).trim() || '#e4572e';
}

function palette(): string[] {
  return DEFAULT_VARS.map((v) => resolve(`var(${v})`));
}

function ensureCanvas(): CanvasRenderingContext2D | null {
  if (!canvas) {
    canvas = document.createElement('canvas');
    canvas.setAttribute('aria-hidden', 'true');
    // Über allem, auch über dem Feier-Dialog: dessen abgedunkelter, weich
    // gezeichneter Hintergrund schluckt sonst genau das Konfetti, das zur
    // Feier gehört. Klicks gehen weiter durch (pointer-events:none).
    canvas.style.cssText =
      'position:fixed;inset:0;pointer-events:none;z-index:60;width:100%;height:100%';
    document.body.appendChild(canvas);
    ctx = canvas.getContext('2d');
  }
  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  const w = window.innerWidth;
  const h = window.innerHeight;
  if (canvas.width !== w * dpr || canvas.height !== h * dpr) {
    canvas.width = w * dpr;
    canvas.height = h * dpr;
    ctx?.setTransform(dpr, 0, 0, dpr, 0, 0);
  }
  return ctx;
}

function teardown(): void {
  if (frame) cancelAnimationFrame(frame);
  frame = 0;
  particles = [];
  canvas?.remove();
  canvas = null;
  ctx = null;
}

function tick(): void {
  const c = ctx;
  if (!c || !canvas) return teardown();
  c.clearRect(0, 0, window.innerWidth, window.innerHeight);

  for (const p of particles) {
    p.age++;
    p.vy += GRAVITY;
    p.vx *= DRAG;
    p.vy *= DRAG;
    p.x += p.vx;
    p.y += p.vy;
    p.angle += p.spin;

    // Am Ende ausblenden, statt die Schnipsel hart verschwinden zu lassen.
    const fade = Math.max(0, Math.min(1, (p.life - p.age) / 24));
    c.save();
    c.globalAlpha = fade;
    c.translate(p.x, p.y);
    c.rotate(p.angle);
    // Der schmaler werdende Streifen lässt das Papier flattern.
    c.scale(Math.cos(p.angle * 1.6), 1);
    c.fillStyle = p.color;
    c.fillRect(-p.w / 2, -p.h / 2, p.w, p.h);
    c.restore();
  }

  particles = particles.filter((p) => p.age < p.life && p.y < window.innerHeight + 40);
  if (particles.length) frame = requestAnimationFrame(tick);
  else teardown();
}

/** Fliegt gerade noch Papier? Verhindert, dass sich Salven stapeln. */
export function confettiActive(): boolean {
  return particles.length > 0;
}

/** Ein Schwung Konfetti. Mehrere Aufrufe kurz nacheinander addieren sich. */
export function confetti(opts: BurstOptions = {}): void {
  if (reducedMotion()) return;
  const c = ensureCanvas();
  if (!c) return;

  const {
    x = 0.5,
    y = 0.55,
    count = 70,
    colors = palette(),
    power = 13,
    spread = Math.PI * 0.75,
  } = opts;

  // Leere Farbliste (z.B. ein Abzeichen ohne Farbe) fällt auf die Palette zurück.
  const paper = (colors.length ? colors : DEFAULT_VARS.map((v) => `var(${v})`)).map(resolve);
  const originX = x * window.innerWidth;
  const originY = y * window.innerHeight;

  for (let i = 0; i < count; i++) {
    // Nach oben streuen: -90° ± spread/2.
    const angle = -Math.PI / 2 + (Math.random() - 0.5) * spread;
    const speed = power * (0.55 + Math.random() * 0.75);
    particles.push({
      x: originX + (Math.random() - 0.5) * 24,
      y: originY + (Math.random() - 0.5) * 12,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      w: 5 + Math.random() * 6,
      h: 8 + Math.random() * 6,
      color: paper[Math.floor(Math.random() * paper.length)],
      spin: (Math.random() - 0.5) * 0.34,
      angle: Math.random() * Math.PI,
      life: 90 + Math.random() * 60,
      age: 0,
    });
  }

  if (!frame) frame = requestAnimationFrame(tick);
}

/** Konfetti aus der Mitte eines Elements — z.B. dem gerade gedrückten Knopf. */
export function confettiFrom(el: Element | null, opts: BurstOptions = {}): void {
  if (!el) return confetti(opts);
  const r = el.getBoundingClientRect();
  confetti({
    ...opts,
    x: (r.left + r.width / 2) / window.innerWidth,
    y: (r.top + r.height / 2) / window.innerHeight,
  });
}

/**
 * Der große Auftritt: zwei Salven von links und rechts, dazu eine aus der
 * Mitte. Für Level-Ups und erreichte Wochenziele.
 */
export function confettiCheer(colors?: string[]): void {
  if (reducedMotion()) return;
  confetti({ x: 0.5, y: 0.42, count: 90, colors, power: 15 });
  window.setTimeout(() => confetti({ x: 0.08, y: 0.75, count: 45, colors, power: 17, spread: Math.PI / 2.4 }), 130);
  window.setTimeout(() => confetti({ x: 0.92, y: 0.75, count: 45, colors, power: 17, spread: Math.PI / 2.4 }), 230);
}
