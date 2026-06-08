// Association setups between models
const User = require('./User');
const Service = require('./Service');
const Booking = require('./Booking');

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

module.exports = {
  User,
  Service,
  Booking
};
