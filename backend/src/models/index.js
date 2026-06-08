// Association setups between models
const User = require('./User');
const Service = require('./Service');
const Booking = require('./Booking');
const Transaction = require('./Transaction');

// A Service belongs to a Provider (User)
Service.belongsTo(User, { foreignKey: 'provider_id', as: 'provider' });
User.hasMany(Service, { foreignKey: 'provider_id', as: 'services' });

// A Booking belongs to a Client (User)
Booking.belongsTo(User, { foreignKey: 'client_id', as: 'client' });
User.hasMany(Booking, { foreignKey: 'client_id', as: 'clientBookings' });

// A Booking belongs to a Provider (User)
Booking.belongsTo(User, { foreignKey: 'provider_id', as: 'provider' });
User.hasMany(Booking, { foreignKey: 'provider_id', as: 'providerBookings' });

// A Booking belongs to a Service
Booking.belongsTo(Service, { foreignKey: 'service_id', as: 'service' });
Service.hasMany(Booking, { foreignKey: 'service_id', as: 'bookings' });

// A Transaction belongs to a Booking
Transaction.belongsTo(Booking, { foreignKey: 'booking_id', as: 'booking' });
Booking.hasOne(Transaction, { foreignKey: 'booking_id', as: 'transaction' });

module.exports = {
  User,
  Service,
  Booking,
  Transaction
};
