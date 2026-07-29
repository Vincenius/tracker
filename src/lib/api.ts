import { parseData } from './storage';
import type { AppData } from './types';

const TOKEN_KEY = 'tracker.token';

/** Der Server hat den Request mit 401 abgelehnt — Token fehlt oder ist falsch. */
export class UnauthorizedError extends Error {}

/** Token von Hand nachtragen — für installierte PWAs, die nie eine ?token=…-URL sehen. */
export function setToken(token: string): void {
  localStorage.setItem(TOKEN_KEY, token.trim());
}

/** Optionales Token: einmal als ?token=… aufrufen, danach merkt es der Browser. */
export function initToken(): string {
  const url = new URL(window.location.href);
  const fromUrl = url.searchParams.get('token');
  if (fromUrl) {
    localStorage.setItem(TOKEN_KEY, fromUrl);
    url.searchParams.delete('token');
    window.history.replaceState(null, '', url.toString());
    return fromUrl;
  }
  return localStorage.getItem(TOKEN_KEY) ?? '';
}

function headers(): Record<string, string> {
  const token = localStorage.getItem(TOKEN_KEY) ?? '';
  return {
    'content-type': 'application/json',
    ...(token ? { 'x-tracker-token': token } : {}),
  };
}

async function request(path: string, init: RequestInit): Promise<AppData> {
  const res = await fetch(path, { ...init, headers: headers(), cache: 'no-store' });
  if (res.status === 401) throw new UnauthorizedError('401');
  if (!res.ok) throw new Error(`${res.status}`);
  return parseData(await res.json());
}

/** Lokalen Stand einmischen und den gemergten Server-Stand zurückbekommen. */
export function syncWithServer(local: AppData): Promise<AppData> {
  return request('/api/sync', { method: 'POST', body: JSON.stringify(local) });
}

/** Server-Stand hart ersetzen (Import, Zurücksetzen). */
export function replaceOnServer(data: AppData): Promise<AppData> {
  return request('/api/data', { method: 'PUT', body: JSON.stringify(data) });
}
