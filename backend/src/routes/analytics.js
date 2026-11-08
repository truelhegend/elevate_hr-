const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const { query } = require('../db');
const { success } = require('../utils/responses');

// Company-wide analytics are management data, not employee data.
router.use(authenticate);
router.use(authorize('ADMIN', 'MANAGER', 'CEO'));

router.get('/dashboard', (req, res) => {
  const employees = query('users', u => u.role === 'EMPLOYEE' || u.role === 'MANAGER');
  const today = new Date().toISOString().split('T')[0];
  const todayRecords = query('attendance', a => a.date === today);
  const present = todayRecords.filter(a => a.status === 'PRESENT' || a.status === 'LATE').length;
  const pending = query('leave_requests', l => l.status === 'PENDING').length;
  const now = new Date();
  const perfs = query('performance', p => p.month === now.getMonth() + 1 && p.year === now.getFullYear());
  const avgPerf = perfs.length > 0 ? Math.round(perfs.reduce((s, p) => s + p.overallScore, 0) / perfs.length) : 0;

  success(res, {
    totalEmployees: employees.length,
    presentToday: present,
    pendingLeaveRequests: pending,
    averagePerformance: avgPerf,
    attendanceRate: employees.length > 0 ? Math.round((present / employees.length) * 100) : 0,
  });
});

router.get('/department-rankings', (req, res) => {
  const now = new Date();
  const employees = query('users', u => u.role === 'EMPLOYEE' || u.role === 'MANAGER');
  const perfs = query('performance', p => p.month === now.getMonth() + 1 && p.year === now.getFullYear());
  const depts = {};
  for (const u of employees) {
    if (!depts[u.department]) depts[u.department] = { scores: [], count: 0 };
    const p = perfs.find(r => r.userId === u.id);
    if (p) { depts[u.department].scores.push(p.overallScore); depts[u.department].count++; }
  }
  const rankings = Object.entries(depts).map(([dept, d]) => ({
    department: dept,
    averageScore: d.scores.length > 0 ? Math.round(d.scores.reduce((a, b) => a + b, 0) / d.scores.length) : 0,
    employeeCount: d.count,
  })).sort((a, b) => b.averageScore - a.averageScore).map((r, i) => ({ rank: i + 1, ...r }));
  success(res, rankings);
});

router.get('/leave-trends', (req, res) => {
  const { months = 6 } = req.query;
  const trends = [];
  const now = new Date();
  for (let i = Number(months) - 1; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const m = d.getMonth() + 1;
    const y = d.getFullYear();
    const ms = String(m).padStart(2, '0');
    const approved = query('leave_requests', l => l.status === 'APPROVED' && l.startDate.startsWith(`${y}-${ms}`)).length;
    const rejected = query('leave_requests', l => l.status === 'REJECTED' && l.startDate.startsWith(`${y}-${ms}`)).length;
    trends.push({ month: d.toLocaleString('default', { month: 'short' }), year: y, approved, rejected });
  }
  success(res, trends);
});

router.get('/absenteeism', (req, res) => {
  const thirtyDaysAgo = new Date(Date.now() - 30 * 86400000).toISOString().split('T')[0];
  const all = query('attendance', a => a.date >= thirtyDaysAgo);
  const absent = all.filter(a => a.status === 'ABSENT').length;
  success(res, { period: 'Last 30 days', totalRecords: all.length, absentDays: absent, absenteeismRate: all.length > 0 ? Math.round((absent / all.length) * 100) : 0 });
});

router.get('/insights', (req, res) => {
  const now = new Date();
  const perfs = query('performance', p => p.month === now.getMonth() + 1 && p.year === now.getFullYear());
  const avgPerf = perfs.length > 0 ? Math.round(perfs.reduce((s, p) => s + p.overallScore, 0) / perfs.length) : 0;
  success(res, {
    averagePerformance: avgPerf,
    highPerformers: perfs.filter(p => p.overallScore >= 90).length,
    atRiskEmployees: perfs.filter(p => p.overallScore < 70).length,
    recommendations: [
      'Consider recognition programs for high performers',
      'Schedule check-ins with at-risk employees',
      'Review attendance patterns in Engineering department',
    ],
  });
});

module.exports = router;
