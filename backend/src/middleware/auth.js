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
    req.userId = decoded.userId;
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
    return generateTokens(decoded.userId);
  } catch {
    return null;
  }
}

module.exports = { generateTokens, authenticate, authorize, refreshAccessToken, generateBiometricSecret, JWT_SECRET, JWT_REFRESH_SECRET };
