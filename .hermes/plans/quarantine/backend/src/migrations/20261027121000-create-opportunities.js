/**
 * Migración para crear la tabla `Opportunities`.
 */
module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('Opportunities', {
      id: { type: Sequelize.INTEGER, primaryKey: true, autoIncrement: true },
      title: { type: Sequelize.STRING, allowNull: false },
      amount: { type: Sequelize.DECIMAL(10, 2), allowNull: true },
      stage: { type: Sequelize.ENUM('new', 'quoted', 'negotiating', 'won', 'lost'), defaultValue: 'new' },
      probability: { type: Sequelize.INTEGER, allowNull: true },
      expectedCloseDate: { type: Sequelize.DATE, allowNull: true },
      notes: { type: Sequelize.TEXT, allowNull: true },
      leadId: { type: Sequelize.INTEGER, references: { model: 'Leads', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
      userId: { type: Sequelize.INTEGER, references: { model: 'Users', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
      salonId: { type: Sequelize.INTEGER, references: { model: 'Salons', key: 'id' }, onUpdate: 'CASCADE', onDelete: 'SET NULL' },
      createdAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updatedAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });
  },
  down: async (queryInterface, Sequelize) => {
    await queryInterface.dropTable('Opportunities');
  },
};
