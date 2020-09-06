'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class Stream extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      // define association here
    }
  }
  Stream.init({
    source: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    platform: {
      type: DataTypes.ENUM('Facebook', 'Instagram', 'YouTube', 'Periscope', 'Twitch', 'Pig Observer'),
      allowNull: false,
    },
    link: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    status: {
      type: DataTypes.ENUM('Live', 'Offline', 'Unknown'),
      allowNull: false,
    },
    title: {
      type: DataTypes.STRING,
    },
    checkedAt: DataTypes.DATE,
    liveAt: DataTypes.DATE,
    embedLink: DataTypes.STRING,
    postedBy: DataTypes.STRING,
    city: DataTypes.STRING,
    state: DataTypes.STRING,
    country: DataTypes.STRING
  }, {
    sequelize,
    modelName: 'Stream',
  });
  return Stream;
};