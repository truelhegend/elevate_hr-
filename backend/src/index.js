const express = require('express');
const cors = require('cors');
const { initDatabase } = require('./db');

const authRoutes = require('./routes/auth');
const employeeRoutes = require('./routes/employees');
const attendanceRoutes = require('./routes/attendance');
const leaveRoutes = require('./routes/leave');
const notificationRoutes = require('./routes/notifications');
const performanceRoutes = require('./routes/performance');
const analyticsRoutes = require('./routes/analytics');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '10mb' }));

app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/employees', employeeRoutes);
app.use('/api/v1/attendance', attendanceRoutes);
app.use('/api/v1/leave', leaveRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/performance', performanceRoutes);
app.use('/api/v1/analytics', analyticsRoutes);

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ success: false, message: 'Internal server error' });
});

initDatabase();

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Elevate HR API running on http://0.0.0.0:${PORT}`);
});
