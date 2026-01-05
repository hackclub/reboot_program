import http from 'http';
import { promises as fs } from 'fs';
import path from 'path';
import url from 'url';
import crypto from 'crypto';

const hostname = process.env.HOST || '0.0.0.0';
const port = parseInt(process.env.PORT || '3000', 10);

const projectRoot = process.cwd();
const publicDirectory = path.join(projectRoot, 'frontend');

// Load environment variables //testfrom .env if present (no external deps)
async function loadEnvFromDotfile() {
	try {
		const envPath = path.join(projectRoot, '.env');
		const raw = await fs.readFile(envPath, 'utf8');
		raw.split('\n').forEach((line) => {
			const trimmed = line.trim();
			if (!trimmed || trimmed.startsWith('#')) return;
			const eq = trimmed.indexOf('=');
			if (eq === -1) return;
			const key = trimmed.slice(0, eq).trim();
			let value = trimmed.slice(eq + 1).trim();
			if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
				value = value.slice(1, -1);
			}
			if (!(key in process.env)) {
				process.env[key] = value;
			}
		});
	} catch {
		// .env is optional
	}
}
await loadEnvFromDotfile();

// Admin credentials and session settings (override via env variables)
const BASIC_AUTH_USER = process.env.BASIC_AUTH_USER || 'admin';
const BASIC_AUTH_PASS = process.env.BASIC_AUTH_PASS || 'admin';
const SESSION_SECRET = process.env.SESSION_SECRET || 'dev-session-secret';
const SESSION_MAX_AGE_SECONDS = 7 * 24 * 60 * 60; // 7 days
const SESSION_COOKIE_NAME = 'reboot_session';

const contentTypeByExtension = {
	'.html': 'text/html; charset=utf-8',
	'.js': 'text/javascript; charset=utf-8',
	'.mjs': 'text/javascript; charset=utf-8',
	'.css': 'text/css; charset=utf-8',
	'.json': 'application/json; charset=utf-8',
	'.svg': 'image/svg+xml',
	'.png': 'image/png',
	'.jpg': 'image/jpeg',
	'.jpeg': 'image/jpeg',
	'.gif': 'image/gif',
	'.ico': 'image/x-icon',
	'.webp': 'image/webp',
	'.ttf': 'font/ttf',
	'.otf': 'font/otf',
	'.woff': 'font/woff',
	'.woff2': 'font/woff2',
	'.txt': 'text/plain; charset=utf-8',
};

function resolveFilePath(requestUrl) {
	const { pathname } = url.parse(requestUrl);
	const rawPath = pathname === '/' ? '/index.html' : pathname;
	const normalizedPath = path.normalize(rawPath).replace(/^(\.\.[/\\])+/, '');
	const absolutePath = path.join(publicDirectory, normalizedPath);
	return absolutePath;
}

async function fileExists(filePath) {
	try {
		const stats = await fs.stat(filePath);
		return stats.isFile();
	} catch {
		return false;
	}
}

function parseCookies(cookieHeader) {
	if (!cookieHeader) return {};
	return cookieHeader.split(';').reduce((acc, part) => {
		const [k, v] = part.split('=');
		if (!k) return acc;
		acc[k.trim()] = decodeURIComponent((v || '').trim());
		return acc;
	}, {});
}

function sign(value) {
	return crypto.createHmac('sha256', SESSION_SECRET).update(value).digest('hex');
}

function createSessionCookie(username) {
	const expiresAt = Math.floor(Date.now() / 1000) + SESSION_MAX_AGE_SECONDS;
	const payload = `${username}|${expiresAt}`;
	const signature = sign(payload);
	return `${payload}|${signature}`;
}

function verifySessionCookie(cookieValue) {
	if (!cookieValue) return null;
	const parts = cookieValue.split('|');
	if (parts.length !== 3) return null;
	const [username, expStr, signature] = parts;
	const payload = `${username}|${expStr}`;
	if (sign(payload) !== signature) return null;
	const exp = parseInt(expStr, 10);
	if (!Number.isFinite(exp) || exp < Math.floor(Date.now() / 1000)) return null;
	return { username };
}

function setCookieHeader(name, value, options = {}) {
	const attrs = [`${name}=${encodeURIComponent(value)}`];
	attrs.push(`Path=${options.path || '/'}`);
	if (options.httpOnly !== false) attrs.push('HttpOnly');
	attrs.push(`SameSite=${options.sameSite || 'Lax'}`);
	if (options.maxAge != null) attrs.push(`Max-Age=${options.maxAge}`);
	if (options.secure) attrs.push('Secure');
	return attrs.join('; ');
}

function renderLoginPage(message, redirectTo) {
	const notice = message ? `<p style="color:#b00020;font-weight:700">${message}</p>` : '';
	const redirectField = redirectTo ? `<input type="hidden" name="redirect" value="${encodeURIComponent(redirectTo)}" />` : '';
	return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Sign in</title>
</head>
<body style="margin:0;display:flex;min-height:100vh;align-items:center;justify-content:center;background:#7d88a5;font-family:-apple-system,Segoe UI,Roboto,Ubuntu,Arial,sans-serif;color:#1f2430">
  <form method="POST" action="/__login" style="background:#d8ccb4;border-radius:16px;padding:24px;box-shadow:0 6px 14px rgba(0,0,0,0.12);width:min(420px,92vw)">
    <h2 style="margin:0 0 10px">Admin Login</h2>
    ${notice}
    <label style="display:block;margin:10px 0 4px;font-weight:700">Username</label>
    <input name="username" type="text" style="width:100%;padding:10px;border-radius:10px;border:1px solid #b8b6b1;background:#fffdf9" required />
    <label style="display:block;margin:12px 0 4px;font-weight:700">Password</label>
    <input name="password" type="password" style="width:100%;padding:10px;border-radius:10px;border:1px solid #b8b6b1;background:#fffdf9" required />
    ${redirectField}
    <button type="submit" style="margin-top:14px;width:100%;appearance:none;border:0;background:#d6a161;color:#2a2118;font-weight:800;padding:10px 14px;border-radius:14px;cursor:pointer;box-shadow:0 3px 0 rgba(0,0,0,0.15)">Sign in</button>
  </form>
</body>
</html>`;
}

function parseFormUrlEncoded(body) {
	const params = {};
	for (const pair of body.split('&')) {
		if (!pair) continue;
		const [k, v] = pair.split('=');
		if (!k) continue;
		params[decodeURIComponent(k.replace(/\+/g, ' '))] = decodeURIComponent((v || '').replace(/\+/g, ' '));
	}
	return params;
}

const server = http.createServer(async (req, res) => {
	try {
		const parsed = url.parse(req.url || '/', true);
		const pathname = parsed.pathname || '/';
		const cookies = parseCookies(req.headers['cookie']);
		const session = verifySessionCookie(cookies[SESSION_COOKIE_NAME]);

		// Public health endpoint (no auth) for platforms
		if (pathname === '/healthz') {
			res.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8', 'Cache-Control': 'no-store' });
			res.end('ok');
			return;
		}

		// Logout route
		if (pathname === '/__logout') {
			res.statusCode = 302;
			res.setHeader('Set-Cookie', setCookieHeader(SESSION_COOKIE_NAME, '', { maxAge: 0, httpOnly: true, sameSite: 'Lax', path: '/' }));
			res.setHeader('Location', '/signin.html');
			res.end();
			return;
		}

		// Serve a tiny built-in placeholder image at /img/placeholder.png
		if (pathname === '/img/placeholder.png') {
			// 1x1 opaque beige PNG (base64)
			const base64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=';
			const buf = Buffer.from(base64, 'base64');
			res.writeHead(200, { 'Content-Type': 'image/png', 'Cache-Control': 'no-store' });
			res.end(buf);
			return;
		}

		// Serve signin hero assets from repository root: /img/signin/*
		if (pathname && pathname.startsWith('/img/signin/')) {
			// Decode URL-encoded path segments (e.g., spaces as %20)
			const requestedRaw = pathname.slice('/img/signin/'.length);
			const requested = decodeURIComponent(requestedRaw);
			const safe = requested.replace(/^(\.\.[/\\])+/, '');
			const imgPath = path.join(projectRoot, 'img', 'signin', safe);
			try {
				const buf = await fs.readFile(imgPath);
				const ext = path.extname(imgPath).toLowerCase();
				const type = contentTypeByExtension[ext] || 'application/octet-stream';
				res.writeHead(200, { 'Content-Type': type, 'Cache-Control': 'no-store' });
				res.end(buf);
			} catch {
				res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
				res.end('Not Found');
			}
			return;
		}

		// Serve fonts from repository root: /Jolly_Lodger/*
		if (pathname && pathname.startsWith('/Jolly_Lodger/')) {
			const requestedRaw = pathname.slice('/Jolly_Lodger/'.length);
			const requested = decodeURIComponent(requestedRaw);
			const safe = requested.replace(/^(\.\.[/\\])+/, '');
			const fontPath = path.join(projectRoot, 'Jolly_Lodger', safe);
			try {
				const buf = await fs.readFile(fontPath);
				const ext = path.extname(fontPath).toLowerCase();
				const type = contentTypeByExtension[ext] || 'application/octet-stream';
				res.writeHead(200, { 'Content-Type': type, 'Cache-Control': 'no-store' });
				res.end(buf);
			} catch {
				res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
				res.end('Not Found');
			}
		 return;
		}

		// Serve fonts from repository root: /Jim_Nightshade/*
		if (pathname && pathname.startsWith('/Jim_Nightshade/')) {
			const requestedRaw = pathname.slice('/Jim_Nightshade/'.length);
			const requested = decodeURIComponent(requestedRaw);
			const safe = requested.replace(/^(\.\.[/\\])+/, '');
			const fontPath = path.join(projectRoot, 'Jim_Nightshade', safe);
			try {
				const buf = await fs.readFile(fontPath);
				const ext = path.extname(fontPath).toLowerCase();
				const type = contentTypeByExtension[ext] || 'application/octet-stream';
				res.writeHead(200, { 'Content-Type': type, 'Cache-Control': 'no-store' });
				res.end(buf);
			} catch {
				res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
				res.end('Not Found');
			}
			return;
		}

		// If no valid session, fall back to Basic Auth popup; on success, set a session cookie
		if (!session) {
			const auth = req.headers['authorization'] || '';
			const expected = 'Basic ' + Buffer.from(`${BASIC_AUTH_USER}:${BASIC_AUTH_PASS}`).toString('base64');
			if (auth !== expected) {
				res.writeHead(401, {
					'WWW-Authenticate': 'Basic realm="Reboot", charset="UTF-8"',
					'Content-Type': 'text/plain; charset=utf-8',
				});
				res.end('Authentication required.');
				return;
			}
			// Set a session cookie so subsequent requests don't prompt again
			const cookieVal = createSessionCookie(BASIC_AUTH_USER);
			res.setHeader('Set-Cookie', setCookieHeader(SESSION_COOKIE_NAME, cookieVal, { httpOnly: true, sameSite: 'Lax', path: '/', maxAge: SESSION_MAX_AGE_SECONDS }));
		}

		const absolutePath = resolveFilePath(req.url || '/');
		if (!absolutePath.startsWith(publicDirectory)) {
			res.writeHead(403, { 'Content-Type': 'text/plain; charset=utf-8' });
			res.end('Forbidden');
			return;
		}

		const exists = await fileExists(absolutePath);
		if (!exists) {
			res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
			res.end('Not Found');
			return;
		}

		const ext = path.extname(absolutePath).toLowerCase();
		const contentType = contentTypeByExtension[ext] || 'application/octet-stream';

		const data = await fs.readFile(absolutePath);
		res.writeHead(200, {
			'Content-Type': contentType,
			'Cache-Control': 'no-store',
		});
		res.end(data);
	} catch (error) {
		res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
		res.end('Internal Server Error');
	}
});

server.listen(port, hostname, () => {
	console.log(`Dev server running at http://${hostname}:${port}`);
	console.log(`Serving static files from: ${publicDirectory}`);
});


