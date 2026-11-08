const express = require('express');
const router = express.Router();
const { v4: uuid } = require('uuid');
const { authenticate, authorize } = require('../middleware/auth');
const { query, findOne, insert, update, formatLeaveRequest, formatLeaveBalance } = require('../db');
const { success, error, paginated } = require('../utils/responses');
const { parsePagination } = require('../utils/pagination');
const { toDateKey, todayKey, countWorkingDays, rangesOverlap } = require('../utils/dates');

const PRIVILEGED = ['ADMIN', 'MANAGER', 'CEO'];
const APPROVER_ROLES = ['ADMIN', 'CEO'];
const LEAVE_TYPES = ['Annual', 'Sick', 'Personal', 'Emergency'];

router.use(authenticate);

function normalizeLeaveType(value) {
  const match = LEAVE_TYPES.find(t => t.toLowerCase() === String(value || '').trim().toLowerCase());
  return match || null;
}

function paginate(list, req) {
  const { page, limit, skip } = parsePagination(req.query);
  return { items: list.slice(skip, skip + limit), total: list.length, page, limit };
}

function notify(userId, title, message, actionRoute = '/leave') {
  insert('notifications', {
    id: uuid(), userId, title, message, type: 'LEAVE', isRead: false,
    actionRoute, data: {}, createdAt: new Date().toISOString(),
  });
}

function balanceFor(userId, leaveType, year) {
  return findOne('leave_balances', b => b.userId === userId && b.leaveType === leaveType && b.year === year);
}

// Picks approvers: department managers first, then company admins, then the CEO.
// The requester is always excluded so nobody can approve their own leave.
function resolveApprovers(requester) {
  const candidates = [
    () => query('users', u => u.role === 'MANAGER' && u.department === requester.department && u.id !== requester.id),
    () => query('users', u => u.role === 'ADMIN' && u.id !== requester.id),
    () => query('users', u => u.role === 'CEO' && u.id !== requester.id),
  ];
  for (const pick of candidates) {
    const found = pick();
    if (found.length > 0) return found;
  }
  return [];
}

router.get('/requests', authorize(...PRIVILEGED), (req, res) => {
  const { status, employeeId, leaveType } = req.query;
  let list = query('leave_requests', () => true);
  if (status) list = list.filter(l => l.status === status);
  if (employeeId) list = list.filter(l => l.userId === employeeId);
  if (leaveType) list = list.filter(l => l.leaveType === leaveType);
  list.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  const { items, total, page, limit } = paginate(list, req);
  paginated(res, items.map(formatLeaveRequest), total, page, limit);
});

router.get('/my-requests', (req, res) => {
  const { status } = req.query;
  let list = query('leave_requests', l => l.userId === req.userId);
  if (status) list = list.filter(l => l.status === status);
  list.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  const { items, total, page, limit } = paginate(list, req);
  paginated(res, items.map(formatLeaveRequest), total, page, limit);
});

router.get('/pending-approvals', authorize(...PRIVILEGED), (req, res) => {
  const pendingApprovals = query('leave_approvals', a => a.approverId === req.userId && a.status === 'PENDING');
  const pendingIds = pendingApprovals.map(a => a.leaveRequestId);
  const list = query('leave_requests', l => pendingIds.includes(l.id) && l.status === 'PENDING')
    .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  const { items, total, page, limit } = paginate(list, req);
  paginated(res, items.map(formatLeaveRequest), total, page, limit);
});

router.post('/request', (req, res) => {
  const { leaveType, startDate, endDate, reason, documentUrl } = req.body;
  if (!leaveType || !startDate || !endDate || !reason) {
    return error(res, 'leaveType, startDate, endDate, and reason are required', 400);
  }

  const type = normalizeLeaveType(leaveType);
  if (!type) return error(res, `leaveType must be one of: ${LEAVE_TYPES.join(', ')}`, 400);

  const startKey = toDateKey(startDate);
  const endKey = toDateKey(endDate);
  if (!startKey || !endKey) return error(res, 'Invalid date format', 400);
  if (endKey < startKey) return error(res, 'End date must be after start date', 400);
  if (startKey < todayKey()) return error(res, 'Leave cannot start in the past', 400);

  const totalDays = countWorkingDays(startKey, endKey);
  if (totalDays === 0) return error(res, 'Selected dates contain no working days (Mon-Fri)', 400);

  const overlapping = query('leave_requests', l =>
    l.userId === req.userId &&
    (l.status === 'PENDING' || l.status === 'APPROVED') &&
    rangesOverlap(startKey, endKey, l.startDate, l.endDate));
  if (overlapping.length > 0) {
    return error(res, 'You already have a pending or approved leave request covering these dates', 409);
  }

  const year = Number(startKey.slice(0, 4));
  const balance = balanceFor(req.userId, type, year);
  if (balance) {
    const remaining = balance.totalDays - balance.usedDays;
    if (remaining < totalDays) {
      return error(res, `Insufficient ${type} leave balance: ${remaining} day(s) remaining, ${totalDays} requested`, 400);
    }
  }

  const requester = findOne('users', u => u.id === req.userId);
  if (!requester) return error(res, 'User not found', 404);

  const id = uuid();
  const createdAt = new Date().toISOString();
  insert('leave_requests', {
    id, userId: req.userId, leaveType: type, startDate: startKey, endDate: endKey,
    reason: String(reason), documentUrl: documentUrl || null, status: 'PENDING',
    totalDays, createdAt,
  });

  for (const approver of resolveApprovers(requester)) {
    insert('leave_approvals', {
      id: uuid(), leaveRequestId: id, approverId: approver.id,
      status: 'PENDING', comment: null, createdAt,
    });
  }

  success(res, formatLeaveRequest(findOne('leave_requests', l => l.id === id)));
});

function decide(req, res, decision) {
  const lr = findOne('leave_requests', l => l.id === req.params.id);
  if (!lr) return error(res, 'Leave request not found', 404);
  if (lr.userId === req.userId) return error(res, 'You cannot review your own leave request', 403);
  if (lr.status !== 'PENDING') {
    return error(res, `Only pending requests can be ${decision === 'APPROVED' ? 'approved' : 'rejected'} (current status: ${lr.status})`, 400);
  }

  const comment = req.body.comment || null;
  let approval = findOne('leave_approvals', a => a.leaveRequestId === lr.id && a.approverId === req.userId);

  if (!approval) {
    // Admin/CEO override lets orphaned requests (no manager in department) be actioned.
    if (!APPROVER_ROLES.includes(req.userRole)) {
      return error(res, 'You are not authorized to review this request', 403);
    }
    approval = insert('leave_approvals', {
      id: uuid(), leaveRequestId: lr.id, approverId: req.userId,
      status: decision, comment, createdAt: new Date().toISOString(),
    });
  } else if (approval.status !== 'PENDING') {
    return error(res, 'You have already reviewed this request', 400);
  } else {
    update('leave_approvals', a => a.id === approval.id, { status: decision, comment, createdAt: new Date().toISOString() });
  }

  update('leave_requests', l => l.id === lr.id, { status: decision });

  // One decision closes the request, so other pending approvals must not linger.
  for (const other of query('leave_approvals', a => a.leaveRequestId === lr.id && a.status === 'PENDING' && a.id !== approval.id)) {
    update('leave_approvals', a => a.id === other.id, { status: 'CANCELLED' });
  }

  if (decision === 'APPROVED') {
    const year = Number(lr.startDate.slice(0, 4));
    const balance = balanceFor(lr.userId, lr.leaveType, year);
    if (balance) {
      update('leave_balances', b => b.id === balance.id, { usedDays: balance.usedDays + lr.totalDays });
    }
    notify(lr.userId, 'Leave Request Approved', `Your ${lr.totalDays}-day ${lr.leaveType} leave request has been approved.`);
  } else {
    notify(lr.userId, 'Leave Request Rejected', `Your ${lr.leaveType} leave request was rejected.${comment ? ` Reason: ${comment}` : ''}`);
  }

  success(res, formatLeaveRequest(findOne('leave_requests', l => l.id === lr.id)));
}

router.patch('/:id/approve', authorize(...PRIVILEGED), (req, res) => decide(req, res, 'APPROVED'));
router.patch('/:id/reject', authorize(...PRIVILEGED), (req, res) => decide(req, res, 'REJECTED'));

router.patch('/:id/cancel', (req, res) => {
  const lr = findOne('leave_requests', l => l.id === req.params.id);
  if (!lr) return error(res, 'Leave request not found', 404);
  if (lr.userId !== req.userId) return error(res, 'You can only cancel your own leave requests', 403);
  if (lr.status !== 'PENDING') return error(res, 'Only pending leave requests can be cancelled', 400);

  update('leave_requests', l => l.id === req.params.id, { status: 'CANCELLED' });
  // Clear approver queues too, otherwise cancelled requests still show as pending.
  for (const approval of query('leave_approvals', a => a.leaveRequestId === req.params.id && a.status === 'PENDING')) {
    update('leave_approvals', a => a.id === approval.id, { status: 'CANCELLED' });
  }
  success(res, formatLeaveRequest(findOne('leave_requests', l => l.id === req.params.id)));
});

router.get('/balance', (req, res) => {
  const year = Number(req.query.year) || new Date().getUTCFullYear();
  const balances = query('leave_balances', b => b.userId === req.userId && b.year === year);
  success(res, balances.map(formatLeaveBalance));
});

module.exports = router;
