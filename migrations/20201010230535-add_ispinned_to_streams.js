'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    return queryInterface.sequelize.transaction(t => {
      return Promise.all([
        queryInterface.addColumn('Streams', 'isPinned', {
          type: Sequelize.DataTypes.BOOLEAN,
        }, { transaction: t }),
        queryInterface.addIndex('Streams', ['isPinned'], {
          fields: 'isPinned',
          transaction: t,
        }),
      ]);
    });
  },

  down: async (queryInterface, Sequelize) => {
    return queryInterface.sequelize.transaction(t => {
      return Promise.all([
        queryInterface.removeColumn('Streams', 'isPinned', { transaction: t }),
      ]);
    });
  }
};
