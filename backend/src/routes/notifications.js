const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { query, findOne, update, formatNotification } = require('../db');
const { success, error } = require('../utils/responses');

router.use(authenticate);

router.get('/', (req, res) => {
  const { unreadOnly } = req.query;
  let list = query('notifications', n => n.userId === req.userId);
  if (unreadOnly === 'true') list = list.filter(n => !n.isRead);
  list.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  success(res, list.map(formatNotification));
});

router.get('/unread-count', (req, res) => {
  const count = query('notifications', n => n.userId === req.userId && !n.isRead).length;
  success(res, count);
});

router.patch('/:id/read', (req, res) => {
  const existing = findOne('notifications', n => n.id === req.params.id && n.userId === req.userId);
  if (!existing) return error(res, 'Notification not found', 404);
  update('notifications', n => n.id === req.params.id && n.userId === req.userId, { isRead: true });
  const notif = findOne('notifications', n => n.id === req.params.id && n.userId === req.userId);
  if (!notif) return error(res, 'Notification not found', 404);
  success(res, formatNotification(notif));
});

router.patch('/read-all', (req, res) => {
  const notifs = query('notifications', n => n.userId === req.userId && !n.isRead);
  for (const n of notifs) update('notifications', x => x.id === n.id, { isRead: true });
  success(res);
});

module.exports = router;
