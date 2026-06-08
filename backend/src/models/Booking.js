const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Booking = sequelize.define('Booking', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  client_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    field: 'client_id'
  },
  provider_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    field: 'provider_id'
  },
  service_id: {
    type: DataTypes.INTEGER,
    allowNull: false,
    field: 'service_id'
  },
  scheduled_at: {
    type: DataTypes.DATE,
    allowNull: false,
    field: 'scheduled_at'
  },
  valor_bruto: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
    field: 'valor_bruto'
  },
  comision_plataforma: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
    field: 'comision_plataforma'
  },
  impuestos_estado: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
    field: 'impuestos_estado'
  },
  pago_neto_prestador: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
    field: 'pago_neto_prestador'
  },
  service_address: {
    type: DataTypes.TEXT,
    allowNull: true,
    field: 'service_address'
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  estado: {
    type: DataTypes.STRING(30),
    allowNull: false,
    defaultValue: 'PENDIENTE_PAGO',
    field: 'estado'
  },
  payment_status: {
    type: DataTypes.STRING(20),
    allowNull: true,
    field: 'payment_status'
  },
  pin_verificacion: {
    type: DataTypes.STRING(10),
    allowNull: true,
    field: 'pin_verificacion'
  }
}, {
  tableName: 'bookings',
  timestamps: false
});

module.exports = Booking;
