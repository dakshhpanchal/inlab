const { Pool } = require('pg');

// Create the connection pool using our environment variables
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  // Alternatively, you could use a connection string later:
  // connectionString: process.env.DATABASE_URL
});

// Export a method to query the database
module.exports = {
  query: (text, params) => pool.query(text, params),
};