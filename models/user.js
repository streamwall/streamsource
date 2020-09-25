'use strict';
const { compareSync, hashSync } = require("bcrypt");

const {
  Model
} = require('sequelize');

module.exports = (sequelize, DataTypes) => {
  class User extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      // define association here
    }

    isValidPassword(value) {
      const compare = compareSync(value, this.password)
      return compare
    }
  };
  User.init({
    email:    {
      allowNull: false,
      type:      DataTypes.STRING,
      validate:  {
        isEmail: true
      }
    },
    password: {
      allowNull: false,
      type:      DataTypes.STRING,
      set(value) {
        const hsh = hashSync(value, 10)
        this.setDataValue('password', hsh)
      }
    },
    role: {
      allowNull: false,
      type: DataTypes.STRING,
      defaultValue: 'default'
    }
  }, {
    sequelize,
    modelName: 'User',
    indexes:   [
      {
        unique: true,
        fields: ['email'],
      }
    ]
  });
  return User;
};