const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Booking = sequelize.define('Booking', {
  id: {
    type: DataTypes.UUID,
    primaryKey: true,
    defaultValue: DataTypes.UUIDV4
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
    type: DataTypes.UUID,
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
  tarifa_reserva: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: true,
    field: 'tarifa_reserva'
  },
  service_address: {
    type: DataTypes.TEXT,
    allowNull: true,
    field: 'service_address'
  },
  tipo_via: {
    type: DataTypes.TEXT,
    allowNull: true,
    field: 'tipo_via'
  },
  numero_via: {
    type: DataTypes.TEXT,
    allowNull: true,
    field: 'numero_via'
  },
  numero_placa: {
    type: DataTypes.TEXT,
    allowNull: true,
    field: 'numero_placa'
  },
  numero_complemento: {
    type: DataTypes.TEXT,
    allowNull: true,
    field: 'numero_complemento'
  },
  complemento_interior: {
    type: DataTypes.TEXT,
    allowNull: true,
    field: 'complemento_interior'
  },
  barrio: {
    type: DataTypes.TEXT,
    allowNull: true,
    field: 'barrio'
  },
  localidad: {
    type: DataTypes.TEXT,
    allowNull: true,
    field: 'localidad'
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
  },
  productos_adicionales: {
    type: DataTypes.JSONB,
    allowNull: true,
    field: 'productos_adicionales'
  }
}, {
  tableName: 'bookings',
  timestamps: false
});

module.exports = Booking;
