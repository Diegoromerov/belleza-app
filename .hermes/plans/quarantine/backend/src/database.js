// Minimal Sequelize instance for tests
// Using an in-memory SQLite database to avoid external DB dependencies.

const { Sequelize } = require('sequelize');

const sequelize = new Sequelize('sqlite::memory:', {
  logging: false,
});

module.exports = sequelize;
