const express = require('express');
const router = express.Router();
const { authenticate, authorize } = require('../middleware/auth');
const { query, formatPerformance } = require('../db');
const { success } = require('../utils/responses');

router.use(authenticate);

router.get('/my-score', (req, res) => {
  const now = new Date();
  const perf = query('performance', p => p.userId === req.userId && p.month === now.getMonth() + 1 && p.year === now.getFullYear())[0];
  success(res, perf ? formatPerformance(perf) : null);
});

router.get('/my-history', (req, res) => {
  const { months = 12 } = req.query;
  const limit = Math.max(1, Number(months) || 12);
  const records = query('performance', p => p.userId === req.userId).sort((a, b) => (b.year - a.year) || (b.month - a.month)).slice(0, limit);
  success(res, records.map(r => ({ month: r.month, year: r.year, overallScore: r.overallScore })));
});

router.get('/team', authorize('ADMIN', 'MANAGER', 'CEO'), (req, res) => {
  const now = new Date();
  const employees = query('users', u => u.role === 'EMPLOYEE' || u.role === 'MANAGER');
  const records = query('performance', p => p.month === now.getMonth() + 1 && p.year === now.getFullYear());
  const result = employees.map(u => {
    const p = records.find(r => r.userId === u.id);
    if (!p) return null;
    return { userId: u.id, userName: `${u.firstName} ${u.lastName}`, department: u.department, position: u.position, overallScore: p.overallScore, attendanceScore: p.attendanceScore, punctualityScore: p.punctualityScore, productivityScore: p.productivityScore, complianceScore: p.complianceScore };
  }).filter(Boolean).sort((a, b) => b.overallScore - a.overallScore);
  success(res, result);
});

router.get('/department/:department', authorize('ADMIN', 'MANAGER', 'CEO'), (req, res) => {
  const now = new Date();
  const employees = query('users', u => u.department === req.params.department);
  const records = query('performance', p => p.month === now.getMonth() + 1 && p.year === now.getFullYear() && employees.some(e => e.id === p.userId));
  const avgScore = records.length > 0 ? records.reduce((s, r) => s + r.overallScore, 0) / records.length : 0;
  success(res, { department: req.params.department, averageScore: Math.round(avgScore), employeeCount: employees.length });
});

router.get('/company', authorize('ADMIN', 'MANAGER', 'CEO'), (req, res) => {
  const now = new Date();
  const records = query('performance', p => p.month === now.getMonth() + 1 && p.year === now.getFullYear());
  const avgScore = records.length > 0 ? records.reduce((s, r) => s + r.overallScore, 0) / records.length : 0;
  const avgAtt = records.length > 0 ? records.reduce((s, r) => s + r.attendanceScore, 0) / records.length : 0;
  const avgProd = records.length > 0 ? records.reduce((s, r) => s + r.productivityScore, 0) / records.length : 0;
  success(res, { averageScore: Math.round(avgScore), totalEmployees: records.length, averageAttendance: Math.round(avgAtt), averageProductivity: Math.round(avgProd) });
});

module.exports = router;
