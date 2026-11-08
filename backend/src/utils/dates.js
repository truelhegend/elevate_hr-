// Date helpers for leave calculations. All leave dates are handled as
// YYYY-MM-DD strings (UTC) so comparisons and storage stay timezone-safe.

function toDateKey(value) {
  if (value instanceof Date) return value.toISOString().slice(0, 10);
  const str = String(value || '');
  const match = str.match(/^(\d{4}-\d{2}-\d{2})/);
  if (match) return match[1];
  const parsed = new Date(str);
  return isNaN(parsed.getTime()) ? null : parsed.toISOString().slice(0, 10);
}

function todayKey(now = new Date()) {
  return now.toISOString().slice(0, 10);
}

function eachDay(startKey, endKey) {
  const days = [];
  const cursor = new Date(`${startKey}T00:00:00Z`);
  const end = new Date(`${endKey}T00:00:00Z`);
  while (cursor <= end) {
    days.push(cursor.toISOString().slice(0, 10));
    cursor.setUTCDate(cursor.getUTCDate() + 1);
  }
  return days;
}

// Mon-Fri only. Weekend-only ranges return 0.
function countWorkingDays(startKey, endKey) {
  return eachDay(startKey, endKey).filter(day => {
    const dow = new Date(`${day}T00:00:00Z`).getUTCDay();
    return dow !== 0 && dow !== 6;
  }).length;
}

function rangesOverlap(aStart, aEnd, bStart, bEnd) {
  return aStart <= bEnd && bStart <= aEnd;
}

module.exports = { toDateKey, todayKey, eachDay, countWorkingDays, rangesOverlap };
