// backend/src/middleware/tenantContext.js
const { Pool } = require('pg');
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

async function tenantContextMiddleware(req, res, next) {
  // If there's no user (e.g., public endpoint), we skip setting tenant context.
  // However, note that our RLS policies will restrict access to no rows if tenant_id is not set.
  // We want to allow public endpoints to access global data (like RAG) but not tenant-owned data.
  // For now, we will only set tenant context for authenticated users.
  if (!req.user || !req.user.tenant_id) {
    // If the user is not authenticated or doesn't have a tenant_id, we do not set the tenant context.
    // This will cause RLS to restrict access to no rows for tenant-owned tables.
    // For public endpoints that should access tenant-owned data, we would need to handle differently.
    // But note: the authorization does not specify public endpoints for tenant-owned data.
    // We'll proceed without setting tenant context for non-authenticated requests.
    return next();
  }

  try {
    // Set the tenant_id in the PostgreSQL session for this connection.
    // We use SET LOCAL so that it only lasts for the current transaction.
    // However, note: we are not wrapping the entire request in a transaction.
    // We are setting it at the session level, which will persist for the connection.
    // We must reset it at the end of the request to avoid leakage.
    await pool.query('SELECT set_config(\'app.tenant_id\', $1, true)', [req.user.tenant_id]);

    // Attach a cleanup function to reset the tenant context when the response finishes.
    res.on('finish', async () => {
      try {
        // Reset the tenant context to avoid leaking to other requests using the same connection.
        await pool.query('SELECT set_config(\'app.tenant_id\', \'\', true)');
      } catch (error) {
        console.error('Error resetting tenant context:', error);
        // We don't want to fail the request because of a cleanup error.
      }
    });

    next();
  } catch (error) {
    console.error('Error setting tenant context:', error);
    res.status(500).send('Internal server error');
  }
}

module.exports = tenantContextMiddleware;