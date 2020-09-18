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
    source:    {
      type: DataTypes.STRING,
    },
    platform:  {
      type: DataTypes.ENUM('Facebook', 'Instagram', 'YouTube', 'Periscope', 'Twitch', 'Pig Observer'),
    },
    link:      {
      type:      DataTypes.STRING,
      allowNull: false,
      validate:  {
        isUrl: true,
      },
    },
    status:    {
      type:         DataTypes.ENUM('Live', 'Offline', 'Unknown'),
      defaultValue: 'Unknown',
    },
    title:     {
      type: DataTypes.STRING,
    },
    isExpired: {
      type:         DataTypes.BOOLEAN,
      defaultValue: false,
    },
    checkedAt: DataTypes.DATE,
    liveAt:    DataTypes.DATE,
    embedLink: {
      type:     DataTypes.STRING,
      validate: {
        isUrl: true,
      }
    },
    postedBy:  DataTypes.STRING,
    city:      DataTypes.STRING,
    region:    DataTypes.STRING,
    state:     {
      type: DataTypes.VIRTUAL,
      get() {
        return this.region
      },
      set(_value) {
        throw new Error('Stream.state is deprecated and read-only. Use Stream.region instead.')
      }
    }
  }, {
    sequelize,
    modelName: 'Stream',
  });
  return Stream;
};