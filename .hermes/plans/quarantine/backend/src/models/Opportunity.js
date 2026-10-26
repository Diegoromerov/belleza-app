/**
 * Modelo Opportunity para el CRM SaaS.
 * Una oportunidad representa una posible venta derivada de un Lead.
 * Relacionada con Lead, User (owner) y Salon.
 */
module.exports = (sequelize, DataTypes) => {
  const Opportunity = sequelize.define('Opportunity', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true,
    },
    title: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    amount: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: true,
    },
    stage: {
      type: DataTypes.ENUM('new', 'quoted', 'negotiating', 'won', 'lost'),
      defaultValue: 'new',
    },
    probability: {
      type: DataTypes.INTEGER, // percent 0-100
      allowNull: true,
    },
    expectedCloseDate: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    notes: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    leadId: {
      type: DataTypes.INTEGER,
      references: { model: 'Leads', key: 'id' },
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
    tableName: 'Opportunities',
    timestamps: true,
  });

  Opportunity.associate = (models) => {
    Opportunity.belongsTo(models.Lead, { foreignKey: 'leadId', as: 'lead' });
    Opportunity.belongsTo(models.User, { foreignKey: 'userId', as: 'owner' });
    Opportunity.belongsTo(models.Salon, { foreignKey: 'salonId', as: 'salon' });
  };

  return Opportunity;
};
