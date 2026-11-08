const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const { authenticate, authorize } = require('../middleware/auth');
const { query, findOne, update, formatUser } = require('../db');
const { success, error, paginated } = require('../utils/responses');
const { parsePagination } = require('../utils/pagination');

const PRIVILEGED = ['ADMIN', 'MANAGER', 'CEO'];

router.use(authenticate);

router.get('/me', (req, res) => {
  const user = findOne('users', u => u.id === req.userId);
  if (!user) return error(res, 'User not found', 404);
  success(res, formatUser(user));
});

router.get('/manager/team', authorize(...PRIVILEGED), (req, res) => {
  const manager = findOne('users', u => u.id === req.userId);
  if (!manager) return error(res, 'User not found', 404);
  const team = query('users', u => u.department === manager.department && u.id !== req.userId).map(formatUser);
  success(res, team);
});

router.get('/:id', (req, res) => {
  const requester = findOne('users', u => u.id === req.userId);
  const isSelf = req.userId === req.params.id;
  if (!isSelf && (!requester || !PRIVILEGED.includes(requester.role))) {
    return error(res, 'You can only view your own profile', 403);
  }
  const user = findOne('users', u => u.id === req.params.id);
  if (!user) return error(res, 'User not found', 404);
  success(res, formatUser(user));
});

router.get('/', authorize(...PRIVILEGED), (req, res) => {
  const { role, search } = req.query;
  const { page, limit, skip } = parsePagination(req.query);

  let filter = () => true;
  if (role && search) {
    const s = String(search).toLowerCase();
    filter = u => u.role === role && (u.firstName.toLowerCase().includes(s) || u.lastName.toLowerCase().includes(s) || u.email.toLowerCase().includes(s));
  } else if (role) {
    filter = u => u.role === role;
  } else if (search) {
    const s = String(search).toLowerCase();
    filter = u => u.firstName.toLowerCase().includes(s) || u.lastName.toLowerCase().includes(s) || u.email.toLowerCase().includes(s);
  }

  const all = query('users', filter);
  const items = all.slice(skip, skip + limit);
  paginated(res, items.map(formatUser), all.length, page, limit);
});

router.patch('/:id', (req, res) => {
  const requester = findOne('users', u => u.id === req.userId);
  const isSelf = req.userId === req.params.id;
  // Managers may edit only their own profile; admins may edit anyone.
  if (!isSelf && (!requester || requester.role !== 'ADMIN')) {
    return error(res, 'You can only edit your own profile', 403);
  }

  const { firstName, lastName, phone, position, avatarUrl } = req.body;
  const existing = findOne('users', u => u.id === req.params.id);
  if (!existing) return error(res, 'User not found', 404);
  update('users', u => u.id === req.params.id, {
    firstName: firstName || existing.firstName,
    lastName: lastName || existing.lastName,
    phone: phone === undefined ? existing.phone : phone,
    position: position || existing.position,
    avatarUrl: avatarUrl === undefined ? existing.avatarUrl : avatarUrl,
  });
  success(res, formatUser(findOne('users', u => u.id === req.params.id)));
});

router.post('/change-password', async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  if (!currentPassword || !newPassword) return error(res, 'Current password and new password are required', 400);
  if (String(newPassword).length < 8) return error(res, 'New password must be at least 8 characters', 400);
  const user = findOne('users', u => u.id === req.userId);
  if (!user) return error(res, 'User not found', 404);
  const valid = await bcrypt.compare(String(currentPassword), user.password);
  if (!valid) return error(res, 'Current password is incorrect', 401);
  const hashedPassword = await bcrypt.hash(String(newPassword), 10);
  update('users', u => u.id === req.userId, { password: hashedPassword });
  success(res, { message: 'Password changed successfully' });
});

module.exports = router;
