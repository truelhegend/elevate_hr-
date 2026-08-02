const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const { query, findOne, update, count, formatUser } = require('../db');
const { success, error, paginated } = require('../utils/responses');

router.use(authenticate);

router.get('/me', (req, res) => {
  const user = findOne('users', u => u.id === req.userId);
  if (!user) return error(res, 'User not found', 404);
  success(res, formatUser(user));
});

router.get('/manager/team', (req, res) => {
  const manager = findOne('users', u => u.id === req.userId);
  if (!manager) return error(res, 'User not found', 404);
  const team = query('users', u => u.department === manager.department && u.id !== req.userId).map(formatUser);
  success(res, team);
});

router.get('/:id', (req, res) => {
  const user = findOne('users', u => u.id === req.params.id);
  if (!user) return error(res, 'User not found', 404);
  success(res, formatUser(user));
});

router.get('/', (req, res) => {
  const { page = 1, limit = 20, role, search } = req.query;
  let filter = () => true;
  if (role && search) {
    const s = search.toLowerCase();
    filter = u => u.role === role && (u.firstName.toLowerCase().includes(s) || u.lastName.toLowerCase().includes(s) || u.email.toLowerCase().includes(s));
  } else if (role) {
    filter = u => u.role === role;
  } else if (search) {
    const s = search.toLowerCase();
    filter = u => u.firstName.toLowerCase().includes(s) || u.lastName.toLowerCase().includes(s) || u.email.toLowerCase().includes(s);
  }
  const all = query('users', filter);
  const total = all.length;
  const start = (Number(page) - 1) * Number(limit);
  const items = all.slice(start, start + Number(limit));
  paginated(res, items.map(formatUser), total, Number(page), Number(limit));
});

router.patch('/:id', (req, res) => {
  if (req.userId !== req.params.id) {
    const user = findOne('users', u => u.id === req.userId);
    if (!user || (user.role !== 'ADMIN' && user.role !== 'MANAGER')) {
      return error(res, 'You can only edit your own profile', 403);
    }
  }
  const { firstName, lastName, phone, position, avatarUrl } = req.body;
  const existing = findOne('users', u => u.id === req.params.id);
  if (!existing) return error(res, 'User not found', 404);
  update('users', u => u.id === req.params.id, {
    firstName: firstName || existing.firstName,
    lastName: lastName || existing.lastName,
    phone: phone ?? existing.phone,
    position: position || existing.position,
    avatarUrl: avatarUrl ?? existing.avatarUrl,
  });
  success(res, formatUser(findOne('users', u => u.id === req.params.id)));
});

router.post('/change-password', async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  if (!currentPassword || !newPassword) return error(res, 'Current password and new password are required', 400);
  if (newPassword.length < 8) return error(res, 'New password must be at least 8 characters', 400);
  const bcrypt = require('bcryptjs');
  const user = findOne('users', u => u.id === req.userId);
  if (!user) return error(res, 'User not found', 404);
  const valid = await bcrypt.compare(currentPassword, user.password);
  if (!valid) return error(res, 'Current password is incorrect', 401);
  const hashedPassword = await bcrypt.hash(newPassword, 10);
  update('users', u => u.id === req.userId, { password: hashedPassword });
  success(res, { message: 'Password changed successfully' });
});

module.exports = router;
