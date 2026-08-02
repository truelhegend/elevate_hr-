const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const { generateTokens, authenticate, refreshAccessToken } = require('../middleware/auth');
const { findOne, formatUser } = require('../db');
const { success, error } = require('../utils/responses');

router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return error(res, 'Email and password are required', 400);
  const user = findOne('users', u => u.email === email);
  if (!user) return error(res, 'Invalid email or password', 401);
  const valid = await bcrypt.compare(password, user.password);
  if (!valid) return error(res, 'Invalid email or password', 401);
  const tokens = generateTokens(user.id);
  success(res, { ...tokens, user: formatUser(user) });
});

router.post('/google', (req, res) => {
  const { idToken } = req.body;
  if (!idToken) return error(res, 'Google ID token is required', 400);

  // TODO: Verify idToken with Google's OAuth2 API using google-auth-library
  // For now, return an error indicating this endpoint requires proper implementation
  return error(res, 'Google OAuth is not yet fully implemented. Please use email/password login.', 501);
});

router.post('/biometric-login', (req, res) => {
  const { biometricSecret, userId } = req.body;
  if (!biometricSecret || !userId) return error(res, 'Biometric secret and userId are required', 400);
  const user = findOne('users', u => u.id === userId && u.biometricSecret === biometricSecret);
  if (!user) return error(res, 'Invalid biometric credentials', 401);
  const tokens = generateTokens(user.id);
  success(res, { ...tokens, user: formatUser(user) });
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
