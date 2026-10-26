/**
 * Modelo Lead para el CRM SaaS.
 * Un lead representa un cliente potencial que aún no ha concretado una reserva.
 * Relacionado con User (creador) y Salon (destino).
 */
module.exports = (sequelize, DataTypes) => {
  const Lead = sequelize.define('Lead', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    email: {
      type: DataTypes.STRING,
      allowNull: false,
      validate: { isEmail: true },
    },
    phone: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    status: {
      type: DataTypes.ENUM('new', 'contacted', 'qualified', 'lost'),
      defaultValue: 'new',
    },
    notes: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    userId: {
      type: DataTypes.INTEGER,
      references: { model: 'Users', key: 'id' },
    },
    salonId: {
      type: DataTypes.INTEGER,
      references: { model: 'Salons', key: 'id' },
    },
  }, {
    tableName: 'Leads',
    timestamps: true,
  });

  Lead.associate = (models) => {
    Lead.belongsTo(models.User, { foreignKey: 'userId', as: 'creator' });
    Lead.belongsTo(models.Salon, { foreignKey: 'salonId', as: 'salon' });
    Lead.hasMany(models.Opportunity, { foreignKey: 'leadId', as: 'opportunities' });
  };

  return Lead;
};
