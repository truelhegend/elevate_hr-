#!/usr/bin/env node
// One-time, idempotent migration for backend/db.json.
// Fixes seed data that was committed in a state the API could not serve:
//   - plaintext passwords (login always failed against bcrypt.compare)
//   - biometricSecret == user id (anyone knowing an id could log in)
//   - leave dates with time components / calendar-day totalDays
//   - leave type casing ("ANNUAL" vs "Annual") breaking balance lookups
//   - attendance clockIn/clockOut stored as "HH:MM:SS" (unparseable by clients)
//   - missing Emergency leave balances used by the mobile app
// Safe to run repeatedly.

const fs = require('fs');
const path = require('path');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { countWorkingDays, toDateKey } = require('../src/utils/dates');

const DB_PATH = path.join(__dirname, '..', 'db.json');
const LEAVE_TYPES = ['Annual', 'Sick', 'Personal', 'Emergency'];

const isBcrypt = value => typeof value === 'string' && /^\$2[aby]\$/.test(value);
const isLegacySecret = (user) => !user.biometricSecret || user.biometricSecret === user.id;

function main() {
  const db = JSON.parse(fs.readFileSync(DB_PATH, 'utf8'));
  const changes = [];

  for (const user of db.users || []) {
    if (!isBcrypt(user.password)) {
      const plain = String(user.password);
      user.password = bcrypt.hashSync(plain, 10);
      changes.push(`hashed password for ${user.email}`);
    }
    if (isLegacySecret(user)) {
      user.biometricSecret = crypto.randomBytes(32).toString('hex');
      changes.push(`rotated biometric secret for ${user.email}`);
    }
  }

  for (const balance of db.leave_balances || []) {
    const canonical = LEAVE_TYPES.find(t => t.toLowerCase() === String(balance.leaveType).toLowerCase());
    if (canonical && balance.leaveType !== canonical) {
      changes.push(`leave balance type ${balance.leaveType} -> ${canonical}`);
      balance.leaveType = canonical;
    }
  }

  const hasBalance = (userId, type, year) =>
    (db.leave_balances || []).some(b => b.userId === userId && b.leaveType === type && b.year === year);

  for (const user of db.users || []) {
    const hasAny2026 = (db.leave_balances || []).some(b => b.userId === user.id && b.year === 2026);
    const defaults = hasAny2026
      ? [{ type: 'Emergency', total: 5 }]
      : [
        { type: 'Annual', total: 15 },
        { type: 'Sick', total: 10 },
        { type: 'Personal', total: 5 },
        { type: 'Emergency', total: 5 },
      ];
    for (const { type, total } of defaults) {
      if (hasBalance(user.id, type, 2026)) continue;
      db.leave_balances.push({ id: crypto.randomUUID(), userId: user.id, leaveType: type, totalDays: total, usedDays: 0, year: 2026 });
      changes.push(`added ${type} balance for ${user.email}`);
    }
  }

  for (const lr of db.leave_requests || []) {
    const start = toDateKey(lr.startDate);
    const end = toDateKey(lr.endDate);
    const canonical = LEAVE_TYPES.find(t => t.toLowerCase() === String(lr.leaveType).toLowerCase());
    if (canonical && lr.leaveType !== canonical) {
      changes.push(`leave request ${lr.id.slice(0, 8)} type ${lr.leaveType} -> ${canonical}`);
      lr.leaveType = canonical;
    }
    if (start && end) {
      if (lr.startDate !== start) { lr.startDate = start; changes.push(`normalized startDate on ${lr.id.slice(0, 8)}`); }
      if (lr.endDate !== end) { lr.endDate = end; changes.push(`normalized endDate on ${lr.id.slice(0, 8)}`); }
      const workingDays = countWorkingDays(start, end);
      if (lr.totalDays !== workingDays) {
        changes.push(`recounted totalDays ${lr.totalDays} -> ${workingDays} on ${lr.id.slice(0, 8)}`);
        lr.totalDays = workingDays;
      }
    }
  }

  const legacyTime = /^\d{2}:\d{2}:\d{2}$/;
  for (const record of db.attendance || []) {
    for (const field of ['clockIn', 'clockOut']) {
      const value = record[field];
      if (typeof value === 'string' && legacyTime.test(value) && record.date) {
        record[field] = `${record.date}T${value}.000Z`;
        changes.push(`converted ${field} to ISO on attendance ${record.date}/${record.userId.slice(0, 8)}`);
      }
    }
  }

  fs.writeFileSync(`${DB_PATH}.tmp`, JSON.stringify(db, null, 2));
  fs.renameSync(`${DB_PATH}.tmp`, DB_PATH);

  console.log(`Migration complete: ${changes.length} change(s)`);
  for (const change of changes) console.log(`  - ${change}`);
}

main();
