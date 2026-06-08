const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Transaction = sequelize.define('Transaction', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  booking_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    unique: true,
    field: 'booking_id'
  },
  amount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false
  },
  status: {
    type: DataTypes.STRING(20),
    allowNull: false
  },
  payment_method: {
    type: DataTypes.STRING(50),
    allowNull: false,
    field: 'payment_method'
  },
  external_id: {
    type: DataTypes.STRING(255),
    allowNull: true,
    field: 'external_id'
  },
  creado_en: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
    field: 'creado_en'
  }
}, {
  tableName: 'transactions',
  timestamps: false
});

module.exports = Transaction;
