const jwt = require('jsonwebtoken');
const crypto = require('crypto');

const JWT_SECRET = process.env.JWT_SECRET || (process.env.NODE_ENV === 'production' ? null : 'elevate-hr-dev-secret-key-2026');
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || (process.env.NODE_ENV === 'production' ? null : 'elevate-hr-dev-refresh-secret-2026');

if (process.env.NODE_ENV === 'production' && (!process.env.JWT_SECRET || !process.env.JWT_REFRESH_SECRET)) {
  console.error('FATAL: JWT_SECRET and JWT_REFRESH_SECRET must be set in production');
  process.exit(1);
}

function generateBiometricSecret() {
  return crypto.randomBytes(32).toString('hex');
}

function safeEqual(a, b) {
  if (typeof a !== 'string' || typeof b !== 'string') return false;
  const bufA = Buffer.from(a);
  const bufB = Buffer.from(b);
  if (bufA.length !== bufB.length) return false;
  return crypto.timingSafeEqual(bufA, bufB);
}

function generateTokens(userId) {
  const accessToken = jwt.sign({ userId }, JWT_SECRET, { expiresIn: '1h' });
  const refreshToken = jwt.sign({ userId }, JWT_REFRESH_SECRET, { expiresIn: '7d' });
  return { accessToken, refreshToken };
}

function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, message: 'No token provided' });
  }
  try {
    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, JWT_SECRET);
    // Tokens for deleted users must stop working immediately, not in an hour.
    const { findOne } = require('../db');
    const user = findOne('users', u => u.id === decoded.userId);
    if (!user) return res.status(401).json({ success: false, message: 'User no longer exists' });
    req.userId = decoded.userId;
    req.userRole = user.role;
    next();
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Invalid token' });
  }
}

function authorize(...roles) {
  return (req, res, next) => {
    const { findOne } = require('../db');
    const user = findOne('users', u => u.id === req.userId);
    if (!user) return res.status(401).json({ success: false, message: 'User not found' });
    if (roles.length > 0 && !roles.includes(user.role)) {
      return res.status(403).json({ success: false, message: 'Insufficient permissions' });
    }
    req.userRole = user.role;
    next();
  };
}

function refreshAccessToken(refreshToken) {
  try {
    const decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
    const { findOne } = require('../db');
    if (!findOne('users', u => u.id === decoded.userId)) return null;
    return generateTokens(decoded.userId);
  } catch {
    return null;
  }
}

// Simple in-memory brute-force guard: 10 attempts per IP+email per 15 minutes.
const LOGIN_WINDOW_MS = 15 * 60 * 1000;
const LOGIN_MAX_ATTEMPTS = 10;
const loginAttempts = new Map();

function loginRateKey(req) {
  return `${req.ip}:${String(req.body && req.body.email || '').trim().toLowerCase()}`;
}

function loginRateLimit(req, res, next) {
  const now = Date.now();
  if (loginAttempts.size > 1000) {
    for (const [key, entry] of loginAttempts) {
      if (entry.resetAt <= now) loginAttempts.delete(key);
    }
  }
  const key = loginRateKey(req);
  const entry = loginAttempts.get(key);
  if (!entry || entry.resetAt <= now) {
    loginAttempts.set(key, { count: 1, resetAt: now + LOGIN_WINDOW_MS });
    return next();
  }
  if (entry.count >= LOGIN_MAX_ATTEMPTS) {
    const retryAfter = Math.ceil((entry.resetAt - now) / 1000);
    res.set('Retry-After', String(retryAfter));
    return res.status(429).json({ success: false, message: 'Too many login attempts. Please try again later.' });
  }
  entry.count += 1;
  next();
}

function clearLoginAttempts(req) {
  loginAttempts.delete(loginRateKey(req));
}

module.exports = { generateTokens, authenticate, authorize, refreshAccessToken, generateBiometricSecret, safeEqual, loginRateLimit, clearLoginAttempts, JWT_SECRET, JWT_REFRESH_SECRET };
