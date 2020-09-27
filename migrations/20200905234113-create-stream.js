'use strict';
module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('Streams', {
      id: {
        allowNull: false,
        autoIncrement: true,
        primaryKey: true,
        type: Sequelize.INTEGER
      },
      source: {
        type: Sequelize.TEXT,
      },
      platform: {
        type: Sequelize.TEXT,
      },
      link: {
        type: Sequelize.TEXT,
        allowNull: false,
      },
      status: {
        type: Sequelize.TEXT,
        defaultValue: 'Unknown',
      },
      isExpired: {
        type: Sequelize.BOOLEAN,
        defaultValue: false,
      },
      title: {
        type: Sequelize.TEXT,
      },
      embedLink: {
        type: Sequelize.TEXT,
      },
      postedBy: {
        type: Sequelize.TEXT,
      },
      city: {
        type: Sequelize.TEXT,
      },
      region: {
        type: Sequelize.TEXT,
      },
      checkedAt: {
        type: Sequelize.DATE
      },
      liveAt: {
        type: Sequelize.DATE
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },
  down: async (queryInterface, Sequelize) => {
    await queryInterface.dropTable('Streams');
  }
};