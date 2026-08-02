function success(res, data = null) {
  return res.json({ success: true, data });
}

function error(res, message = 'Internal server error', status = 500) {
  return res.status(status).json({ success: false, message });
}

function paginated(res, items, total, page, limit) {
  return res.json({
    success: true,
    data: {
      data: items,
      pagination: { total, page, limit, totalPages: Math.ceil(total / limit) },
    },
  });
}

module.exports = { success, error, paginated };
