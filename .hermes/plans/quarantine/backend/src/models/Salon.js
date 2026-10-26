// Stub Sequelize model for Salon used in tests
// This minimal definition satisfies imports without requiring full DB schema.

const { DataTypes } = require('sequelize');
const sequelize = require('../database');

const Salon = sequelize.define('Salon', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  name: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  address: {
    type: DataTypes.STRING,
    allowNull: true,
  },
});

module.exports = Salon;
