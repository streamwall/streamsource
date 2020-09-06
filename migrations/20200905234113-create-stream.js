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
        type: Sequelize.STRING,
        allowNull: false,
      },
      platform: {
        type: Sequelize.ENUM('Facebook', 'Instagram', 'YouTube', 'Periscope', 'Twitch', 'Pig Observer'),
        allowNull: false,
      },
      link: {
        type: Sequelize.STRING,
        allowNull: false,
      },
      status: {
        type: Sequelize.ENUM('Live', 'Offline', 'Unknown'),
        allowNull: false,
      },
      title: {
        type: Sequelize.STRING
      },
      checkedAt: {
        type: Sequelize.DATE
      },
      liveAt: {
        type: Sequelize.DATE
      },
      embedLink: {
        type: Sequelize.STRING
      },
      postedBy: {
        type: Sequelize.STRING
      },
      city: {
        type: Sequelize.STRING
      },
      state: {
        type: Sequelize.STRING
      },
      country: {
        type: Sequelize.STRING
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