// Normalizes ?page/?limit so callers cannot ask for page 0, negative pages,
// NaN limits or unbounded result sets.

function parsePagination(query = {}, { defaultLimit = 20, maxLimit = 100 } = {}) {
  const parsedPage = parseInt(query.page, 10);
  const page = Number.isFinite(parsedPage) && parsedPage > 0 ? parsedPage : 1;

  const parsedLimit = parseInt(query.limit, 10);
  const limit = Number.isFinite(parsedLimit) && parsedLimit > 0
    ? Math.min(parsedLimit, maxLimit)
    : defaultLimit;

  return { page, limit, skip: (page - 1) * limit };
}

module.exports = { parsePagination };
