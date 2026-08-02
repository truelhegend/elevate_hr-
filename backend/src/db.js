const { v4: uuid } = require('uuid');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const DB_PATH = path.join(__dirname, '..', 'db.json');

let store = { users: [], attendance: [], leave_requests: [], leave_approvals: [], leave_balances: [], notifications: [], performance: [] };

function save() { fs.writeFileSync(DB_PATH, JSON.stringify(store, null, 2)); }
function load() {
  if (fs.existsSync(DB_PATH)) {
    store = JSON.parse(fs.readFileSync(DB_PATH, 'utf8'));
    return true;
  }
  return false;
}

function query(table, filter = () => true) { return (store[table] || []).filter(filter); }
function findOne(table, filter) { return (store[table] || []).find(filter); }
function insert(table, record) { store[table].push(record); save(); return record; }
function update(table, filter, updates) {
  const idx = store[table].findIndex(filter);
  if (idx >= 0) { store[table][idx] = { ...store[table][idx], ...updates }; save(); return store[table][idx]; }
  return null;
}
function count(table, filter = () => true) { return (store[table] || []).filter(filter).length; }

function initDatabase() {
  if (load()) return;

  const hashedPassword = bcrypt.hashSync('password123', 10);

  const users = [
    { id: uuid(), firstName: 'Sarah', lastName: 'Johnson', email: 'sarah@elevatehr.com', password: hashedPassword, employeeId: 'EMP001', department: 'Human Resources', position: 'HR Director', role: 'ADMIN', performanceScore: 92, phone: '+1-555-0101' },
    { id: uuid(), firstName: 'James', lastName: 'Anderson', email: 'james@elevatehr.com', password: hashedPassword, employeeId: 'EMP002', department: 'Engineering', position: 'Engineering Manager', role: 'MANAGER', performanceScore: 88, phone: '+1-555-0102' },
    { id: uuid(), firstName: 'Emily', lastName: 'Chen', email: 'emily@elevatehr.com', password: hashedPassword, employeeId: 'EMP003', department: 'Marketing', position: 'Marketing Manager', role: 'MANAGER', performanceScore: 85, phone: '+1-555-0103' },
    { id: uuid(), firstName: 'Michael', lastName: 'Brown', email: 'michael@elevatehr.com', password: hashedPassword, employeeId: 'EMP004', department: 'Executive', position: 'CEO', role: 'CEO', performanceScore: 95, phone: '+1-555-0104' },
    { id: uuid(), firstName: 'Jessica', lastName: 'Williams', email: 'jessica@elevatehr.com', password: hashedPassword, employeeId: 'EMP005', department: 'Engineering', position: 'Frontend Developer', role: 'EMPLOYEE', performanceScore: 82, phone: '+1-555-0105' },
    { id: uuid(), firstName: 'David', lastName: 'Martinez', email: 'david@elevatehr.com', password: hashedPassword, employeeId: 'EMP006', department: 'Engineering', position: 'Backend Developer', role: 'EMPLOYEE', performanceScore: 79, phone: '+1-555-0106' },
    { id: uuid(), firstName: 'Ashley', lastName: 'Garcia', email: 'ashley@elevatehr.com', password: hashedPassword, employeeId: 'EMP007', department: 'Marketing', position: 'Content Specialist', role: 'EMPLOYEE', performanceScore: 88, phone: '+1-555-0107' },
    { id: uuid(), firstName: 'Robert', lastName: 'Taylor', email: 'robert@elevatehr.com', password: hashedPassword, employeeId: 'EMP008', department: 'Finance', position: 'Financial Analyst', role: 'EMPLOYEE', performanceScore: 91, phone: '+1-555-0108' },
    { id: uuid(), firstName: 'Amanda', lastName: 'Lee', email: 'amanda@elevatehr.com', password: hashedPassword, employeeId: 'EMP009', department: 'Human Resources', position: 'HR Specialist', role: 'EMPLOYEE', performanceScore: 86, phone: '+1-555-0109' },
    { id: uuid(), firstName: 'Daniel', lastName: 'Wilson', email: 'daniel@elevatehr.com', password: hashedPassword, employeeId: 'EMP010', department: 'Engineering', position: 'DevOps Engineer', role: 'EMPLOYEE', performanceScore: 90, phone: '+1-555-0110' },
  ];

  const now = new Date();

  for (const u of users) {
    insert('users', { ...u, biometricSecret: u.id, avatarUrl: null });

    for (const lt of [{ type: 'Annual', total: 15, used: Math.floor(Math.random() * 5) }, { type: 'Sick', total: 10, used: Math.floor(Math.random() * 3) }, { type: 'Personal', total: 5, used: Math.floor(Math.random() * 2) }]) {
      insert('leave_balances', { id: uuid(), userId: u.id, leaveType: lt.type, totalDays: lt.total, usedDays: lt.used, year: 2026 });
    }

    for (let d = -29; d <= 0; d++) {
      const date = new Date(now); date.setDate(date.getDate() + d);
      if (date.getDay() === 0 || date.getDay() === 6) continue;
      const status = ['PRESENT', 'PRESENT', 'PRESENT', 'PRESENT', 'LATE'][Math.floor(Math.random() * 5)];
      insert('attendance', {
        id: uuid(), userId: u.id, date: date.toISOString().split('T')[0],
        clockIn: `0${8 + Math.floor(Math.random() * 2)}:${String(Math.floor(Math.random() * 60)).padStart(2, '0')}:00`,
        clockOut: `${17 + Math.floor(Math.random() * 2)}:${String(Math.floor(Math.random() * 60)).padStart(2, '0')}:00`,
        status, location: null, workHours: 8 + Math.random(), notes: null,
      });
    }

    const perf = Math.max(60, Math.min(100, u.performanceScore + (Math.random() * 10 - 5)));
    insert('performance', { id: uuid(), userId: u.id, overallScore: perf, attendanceScore: perf + 3, punctualityScore: perf - 2, productivityScore: perf + 1, complianceScore: perf - 1, month: now.getMonth() + 1, year: now.getFullYear(), calculatedAt: now.toISOString() });
    insert('performance', { id: uuid(), userId: u.id, overallScore: perf - 5, attendanceScore: perf - 2, punctualityScore: perf - 7, productivityScore: perf - 4, complianceScore: perf - 6, month: now.getMonth() === 1 ? 12 : now.getMonth() - 1, year: now.getMonth() === 1 ? now.getFullYear() - 1 : now.getFullYear(), calculatedAt: now.toISOString() });

    insert('notifications', { id: uuid(), userId: u.id, title: 'Welcome to Elevate HR', message: 'Your account has been created successfully. Welcome aboard!', type: 'SYSTEM', isRead: true, actionRoute: null, data: {}, createdAt: new Date(now - 86400000 * 5).toISOString() });
    insert('notifications', { id: uuid(), userId: u.id, title: 'Leave Request Approved', message: 'Your annual leave request has been approved by your manager.', type: 'LEAVE', isRead: false, actionRoute: '/leave', data: {}, createdAt: new Date(now - 86400000 * 2).toISOString() });
    insert('notifications', { id: uuid(), userId: u.id, title: 'Performance Review Ready', message: 'Your monthly performance review is ready. Check your scorecard.', type: 'PERFORMANCE', isRead: false, actionRoute: '/performance', data: {}, createdAt: new Date(now - 86400000).toISOString() });
  }

  const managerId = users[1].id;
  const emp5 = users[4].id;
  const emp6 = users[5].id;
  const emp7 = users[6].id;

  const lr1 = { id: uuid(), userId: emp5, leaveType: 'Annual', startDate: '2026-07-25', endDate: '2026-07-27', reason: 'Family vacation', documentUrl: null, status: 'PENDING', totalDays: 3, createdAt: now.toISOString() };
  insert('leave_requests', lr1);
  insert('leave_approvals', { id: uuid(), leaveRequestId: lr1.id, approverId: managerId, status: 'PENDING', comment: null, createdAt: now.toISOString() });

  const lr2 = { id: uuid(), userId: emp6, leaveType: 'Sick', startDate: '2026-07-20', endDate: '2026-07-21', reason: 'Feeling unwell', documentUrl: null, status: 'APPROVED', totalDays: 2, createdAt: new Date(now - 86400000 * 3).toISOString() };
  insert('leave_requests', lr2);
  insert('leave_approvals', { id: uuid(), leaveRequestId: lr2.id, approverId: managerId, status: 'APPROVED', comment: 'Get well soon', createdAt: new Date(now - 86400000 * 2).toISOString() });

  const lr3 = { id: uuid(), userId: emp7, leaveType: 'Personal', startDate: '2026-08-01', endDate: '2026-08-01', reason: 'Personal appointment', documentUrl: null, status: 'PENDING', totalDays: 1, createdAt: now.toISOString() };
  insert('leave_requests', lr3);
  insert('leave_approvals', { id: uuid(), leaveRequestId: lr3.id, approverId: users[2].id, status: 'PENDING', comment: null, createdAt: now.toISOString() });

  save();
}

function formatUser(u) {
  if (!u) return null;
  return { id: u.id, firstName: u.firstName, lastName: u.lastName, email: u.email, employeeId: u.employeeId, avatarUrl: u.avatarUrl, department: u.department, position: u.position, role: u.role, performanceScore: u.performanceScore, phone: u.phone };
}

function formatLeaveRequest(lr) {
  if (!lr) return null;
  const emp = findOne('users', u => u.id === lr.userId);
  const approvals = query('leave_approvals', a => a.leaveRequestId === lr.id).map(a => {
    const approver = findOne('users', u => u.id === a.approverId);
    return { id: a.id, approverId: a.approverId, approver: approver ? { firstName: approver.firstName, lastName: approver.lastName } : null, status: a.status, comment: a.comment, createdAt: a.createdAt };
  });
  const last = approvals.length > 0 ? approvals[approvals.length - 1] : null;
  return { id: lr.id, employeeId: lr.userId, employee: emp ? { firstName: emp.firstName, lastName: emp.lastName } : null, leaveType: lr.leaveType, startDate: lr.startDate, endDate: lr.endDate, reason: lr.reason, documentUrl: lr.documentUrl, status: lr.status, createdAt: lr.createdAt, totalDays: lr.totalDays, reviewerComment: last?.comment || null, reviewedAt: last?.createdAt || null, approvals };
}

function formatAttendance(a) {
  if (!a) return null;
  const user = findOne('users', u => u.id === a.userId);
  return { id: a.id, userId: a.userId, userName: user ? `${user.firstName} ${user.lastName}` : null, date: a.date, clockIn: a.clockIn, clockOut: a.clockOut, status: a.status, location: a.location, workHours: a.workHours, notes: a.notes };
}

function formatNotification(n) {
  if (!n) return null;
  return { id: n.id, title: n.title, message: n.message, type: n.type, isRead: n.isRead, actionRoute: n.actionRoute, data: n.data || {}, createdAt: n.createdAt };
}

function formatPerformance(p) {
  if (!p) return null;
  return { employeeId: p.userId, overallScore: p.overallScore, attendanceScore: p.attendanceScore, punctualityScore: p.punctualityScore, productivityScore: p.productivityScore, complianceScore: p.complianceScore, calculatedAt: p.calculatedAt, month: p.month, year: p.year };
}

function formatLeaveBalance(lb) {
  if (!lb) return null;
  return { type: lb.leaveType, totalDays: lb.totalDays, usedDays: lb.usedDays, remainingDays: lb.totalDays - lb.usedDays };
}

module.exports = { initDatabase, query, findOne, insert, update, count, formatUser, formatLeaveRequest, formatAttendance, formatNotification, formatPerformance, formatLeaveBalance };
