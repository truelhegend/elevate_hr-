const express = require('express');
const router = express.Router();
const { v4: uuid } = require('uuid');
const { authenticate } = require('../middleware/auth');
const { query, findOne, insert, update, formatAttendance } = require('../db');
const { success, error, paginated } = require('../utils/responses');

router.use(authenticate);

router.post('/clock-in', (req, res) => {
  const today = new Date().toISOString().split('T')[0];
  const existing = findOne('attendance', a => a.userId === req.userId && a.date === today);
  if (existing && existing.clockIn) return error(res, 'Already clocked in today', 400);
  const now = new Date().toISOString();
  if (existing) {
    update('attendance', a => a.id === existing.id, { clockIn: now, status: 'PRESENT' });
    return success(res, formatAttendance(findOne('attendance', a => a.id === existing.id)));
  }
  const record = { id: uuid(), userId: req.userId, date: today, clockIn: now, clockOut: null, status: 'PRESENT', location: null, workHours: 0, notes: null };
  insert('attendance', record);
  success(res, formatAttendance(record));
});

router.post('/clock-out', (req, res) => {
  const today = new Date().toISOString().split('T')[0];
  const record = findOne('attendance', a => a.userId === req.userId && a.date === today);
  if (!record || !record.clockIn) return error(res, 'No clock-in found for today', 400);
  if (record.clockOut) return error(res, 'Already clocked out today', 400);
  const clockOutTime = new Date();
  let workHours = 0;
  if (record.clockIn) {
    const clockInTime = new Date(record.clockIn);
    if (!isNaN(clockInTime.getTime())) {
      workHours = Math.round(((clockOutTime - clockInTime) / 3600000) * 100) / 100;
    } else {
      workHours = 8;
    }
  }
  update('attendance', a => a.id === record.id, { clockOut: clockOutTime.toISOString(), workHours });
  success(res, formatAttendance(findOne('attendance', a => a.id === record.id)));
});

router.post('/mark-remote', (req, res) => {
  const today = new Date().toISOString().split('T')[0];
  const existing = findOne('attendance', a => a.userId === req.userId && a.date === today);
  if (existing) {
    update('attendance', a => a.id === existing.id, { status: 'REMOTE', clockIn: new Date().toISOString() });
    return success(res, formatAttendance(findOne('attendance', a => a.id === existing.id)));
  }
  const record = { id: uuid(), userId: req.userId, date: today, clockIn: new Date().toISOString(), clockOut: null, status: 'REMOTE', location: null, workHours: 0, notes: null };
  insert('attendance', record);
  success(res, formatAttendance(record));
});

router.get('/my-records', (req, res) => {
  const { page = 1, limit = 20 } = req.query;
  const all = query('attendance', a => a.userId === req.userId).sort((a, b) => b.date.localeCompare(a.date));
  const total = all.length;
  const start = (Number(page) - 1) * Number(limit);
  paginated(res, all.slice(start, start + Number(limit)).map(formatAttendance), total, Number(page), Number(limit));
});

router.get('/today', (req, res) => {
  const today = new Date().toISOString().split('T')[0];
  const records = query('attendance', a => a.date === today);
  success(res, records.map(formatAttendance));
});

router.get('/stats', (req, res) => {
  const { startDate, endDate } = req.query;
  const start = startDate || new Date(Date.now() - 30 * 86400000).toISOString().split('T')[0];
  const end = endDate || new Date().toISOString().split('T')[0];
  const all = query('attendance', a => a.userId === req.userId && a.date >= start && a.date <= end);
  const total = all.length;
  const present = all.filter(a => a.status === 'PRESENT').length;
  const late = all.filter(a => a.status === 'LATE').length;
  const absent = all.filter(a => a.status === 'ABSENT').length;
  success(res, { totalDays: total, presentDays: present, lateDays: late, absentDays: absent, attendanceRate: total > 0 ? Math.round((present / total) * 100) : 0 });
});

router.get('/team-availability', (req, res) => {
  const today = new Date().toISOString().split('T')[0];
  const employees = query('users', u => u.role === 'EMPLOYEE' || u.role === 'MANAGER');
  const todayRecords = query('attendance', a => a.date === today);
  const result = employees.map(u => {
    const rec = todayRecords.find(r => r.userId === u.id);
    return { userId: u.id, firstName: u.firstName, lastName: u.lastName, department: u.department, position: u.position, status: rec ? rec.status : 'ABSENT', clockIn: rec?.clockIn || null, clockOut: rec?.clockOut || null };
  });
  success(res, result);
});

module.exports = router;
