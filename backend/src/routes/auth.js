const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const {
  generateTokens,
  authenticate,
  refreshAccessToken,
  generateBiometricSecret,
  safeEqual,
  loginRateLimit,
  clearLoginAttempts,
} = require('../middleware/auth');
const { findOne, update, formatUser } = require('../db');
const { success, error } = require('../utils/responses');

function normalizeEmail(value) {
  return String(value || '').trim().toLowerCase();
}

// Biometric secrets are per-device bearer credentials. Legacy records stored the
// user id as the secret, which made every account trivially takeable-over.
function ensureBiometricSecret(user) {
  const secret = user.biometricSecret;
  const isLegacy = !secret || secret === user.id;
  if (!isLegacy) return secret;
  const fresh = generateBiometricSecret();
  update('users', u => u.id === user.id, { biometricSecret: fresh });
  return fresh;
}

router.post('/login', loginRateLimit, async (req, res) => {
  const { password } = req.body;
  const email = normalizeEmail(req.body.email);
  if (!email || !password) return error(res, 'Email and password are required', 400);

  const user = findOne('users', u => normalizeEmail(u.email) === email);
  if (!user) return error(res, 'Invalid email or password', 401);

  const valid = await bcrypt.compare(String(password), user.password);
  if (!valid) return error(res, 'Invalid email or password', 401);

  clearLoginAttempts(req);
  const tokens = generateTokens(user.id);
  success(res, {
    ...tokens,
    user: formatUser(user),
    // Returned once at password login so the client can enroll biometric login.
    biometricSecret: ensureBiometricSecret(user),
  });
});

router.post('/google', (req, res) => {
  const { idToken } = req.body;
  if (!idToken) return error(res, 'Google ID token is required', 400);

  // TODO: Verify idToken with Google's OAuth2 API using google-auth-library
  return error(res, 'Google OAuth is not yet fully implemented. Please use email/password login.', 501);
});

router.post('/biometric-login', (req, res) => {
  const { userId, biometricSecret } = req.body;
  if (!userId || !biometricSecret) return error(res, 'userId and biometricSecret are required', 400);
  const user = findOne('users', u => u.id === userId);
  if (!user || !user.biometricSecret || user.biometricSecret === user.id) {
    return error(res, 'Invalid biometric credentials', 401);
  }
  if (!safeEqual(biometricSecret, user.biometricSecret)) {
    return error(res, 'Invalid biometric credentials', 401);
  }
  const tokens = generateTokens(user.id);
  success(res, { ...tokens, user: formatUser(user), biometricSecret: user.biometricSecret });
});

router.post('/refresh', (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) return error(res, 'Refresh token is required', 400);
  const tokens = refreshAccessToken(refreshToken);
  if (!tokens) return error(res, 'Invalid refresh token', 401);
  success(res, tokens);
});

router.post('/logout', authenticate, (req, res) => { success(res, { message: 'Logged out successfully' }); });
router.post('/forgot-password', (req, res) => { success(res, { message: 'If an account exists with this email, a reset link has been sent.' }); });

module.exports = router;
