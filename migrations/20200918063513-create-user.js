'use strict';
module.exports = {
  up:   async (queryInterface, Sequelize) => {
    await queryInterface.createTable('Users', {
      id:        {
        allowNull:     false,
        autoIncrement: true,
        primaryKey:    true,
        type:          Sequelize.INTEGER
      },
      email:     {
        type:      Sequelize.STRING,
        allowNull: false,
      },
      password:  {
        type:      Sequelize.STRING,
        allowNull: false,
      },
      createdAt: {
        allowNull: false,
        type:      Sequelize.DATE
      },
      updatedAt: {
        allowNull: false,
        type:      Sequelize.DATE
      },
      role: {
        allowNull: false,
        type: Sequelize.STRING,
        defaultValue: 'default'
      }
    });
    await queryInterface.addIndex(
      'Users',
      {
        fields: ['email'],
        unique: true,
      })
  },
  down: async (queryInterface, Sequelize) => {
    await queryInterface.dropTable('Users');
  }
};