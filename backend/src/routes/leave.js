const express = require('express');
const router = express.Router();
const { v4: uuid } = require('uuid');
const { authenticate, authorize } = require('../middleware/auth');
const { query, findOne, insert, update, formatLeaveRequest, formatLeaveBalance } = require('../db');
const { success, error, paginated } = require('../utils/responses');

router.use(authenticate);

function paginateList(list, page, limit) {
  const total = list.length;
  const start = (Number(page) - 1) * Number(limit);
  return { items: list.slice(start, start + Number(limit)), total };
}

router.get('/requests', (req, res) => {
  const { page = 1, limit = 20, status, employeeId, leaveType } = req.query;
  let list = query('leave_requests', () => true);
  if (status) list = list.filter(l => l.status === status);
  if (employeeId) list = list.filter(l => l.userId === employeeId);
  if (leaveType) list = list.filter(l => l.leaveType === leaveType);
  list.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  const { items, total } = paginateList(list, page, limit);
  paginated(res, items.map(formatLeaveRequest), total, Number(page), Number(limit));
});

router.get('/my-requests', (req, res) => {
  const { page = 1, limit = 20, status } = req.query;
  let list = query('leave_requests', l => l.userId === req.userId);
  if (status) list = list.filter(l => l.status === status);
  list.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  const { items, total } = paginateList(list, page, limit);
  paginated(res, items.map(formatLeaveRequest), total, Number(page), Number(limit));
});

router.get('/pending-approvals', authorize('ADMIN', 'MANAGER'), (req, res) => {
  const { page = 1, limit = 20 } = req.query;
  const approver = findOne('users', u => u.id === req.userId);
  const pendingApprovals = query('leave_approvals', a => a.approverId === req.userId && a.status === 'PENDING');
  const pendingIds = pendingApprovals.map(a => a.leaveRequestId);
  const list = query('leave_requests', l => pendingIds.includes(l.id)).sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  const { items, total } = paginateList(list, page, limit);
  paginated(res, items.map(formatLeaveRequest), total, Number(page), Number(limit));
});

router.post('/request', (req, res) => {
  const { leaveType, startDate, endDate, reason, documentUrl } = req.body;
  if (!leaveType || !startDate || !endDate || !reason) return error(res, 'leaveType, startDate, endDate, and reason are required', 400);
  const start = new Date(startDate);
  const end = new Date(endDate);
  if (isNaN(start.getTime()) || isNaN(end.getTime())) return error(res, 'Invalid date format', 400);
  if (end < start) return error(res, 'End date must be after start date', 400);
  const totalDays = Math.ceil((end - start) / 86400000) + 1;
  const id = uuid();
  const lr = { id, userId: req.userId, leaveType, startDate, endDate, reason, documentUrl: documentUrl || null, status: 'PENDING', totalDays, createdAt: new Date().toISOString() };
  insert('leave_requests', lr);
  const user = findOne('users', u => u.id === req.userId);
  if (user) {
    const managers = query('users', u => u.role === 'MANAGER' && u.department === user.department);
    for (const m of managers) {
      insert('leave_approvals', { id: uuid(), leaveRequestId: id, approverId: m.id, status: 'PENDING', comment: null, createdAt: new Date().toISOString() });
    }
  }
  success(res, formatLeaveRequest(findOne('leave_requests', l => l.id === id)));
});

router.patch('/:id/approve', authorize('ADMIN', 'MANAGER'), (req, res) => {
  const lr = findOne('leave_requests', l => l.id === req.params.id);
  if (!lr) return error(res, 'Leave request not found', 404);
  const approval = findOne('leave_approvals', a => a.leaveRequestId === req.params.id && a.approverId === req.userId);
  if (!approval) return error(res, 'You are not authorized to approve this request', 403);
  update('leave_requests', l => l.id === req.params.id, { status: 'APPROVED' });
  update('leave_approvals', a => a.id === approval.id, { status: 'APPROVED', comment: req.body.comment || null, createdAt: new Date().toISOString() });
  success(res, formatLeaveRequest(findOne('leave_requests', l => l.id === req.params.id)));
});

router.patch('/:id/reject', authorize('ADMIN', 'MANAGER'), (req, res) => {
  const lr = findOne('leave_requests', l => l.id === req.params.id);
  if (!lr) return error(res, 'Leave request not found', 404);
  const approval = findOne('leave_approvals', a => a.leaveRequestId === req.params.id && a.approverId === req.userId);
  if (!approval) return error(res, 'You are not authorized to reject this request', 403);
  update('leave_requests', l => l.id === req.params.id, { status: 'REJECTED' });
  update('leave_approvals', a => a.id === approval.id, { status: 'REJECTED', comment: req.body.comment || null, createdAt: new Date().toISOString() });
  success(res, formatLeaveRequest(findOne('leave_requests', l => l.id === req.params.id)));
});

router.patch('/:id/cancel', (req, res) => {
  const lr = findOne('leave_requests', l => l.id === req.params.id);
  if (!lr) return error(res, 'Leave request not found', 404);
  if (lr.userId !== req.userId) return error(res, 'You can only cancel your own leave requests', 403);
  if (lr.status !== 'PENDING') return error(res, 'Only pending leave requests can be cancelled', 400);
  update('leave_requests', l => l.id === req.params.id, { status: 'CANCELLED' });
  success(res, formatLeaveRequest(findOne('leave_requests', l => l.id === req.params.id)));
});

router.get('/balance', (req, res) => {
  const { year = 2026 } = req.query;
  const balances = query('leave_balances', b => b.userId === req.userId && b.year === Number(year));
  success(res, balances.map(formatLeaveBalance));
});

module.exports = router;
