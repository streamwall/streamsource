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
      type: DataTypes.TEXT,
    },
    platform:  {
      type: DataTypes.TEXT,
    },
    link:      {
      type:      DataTypes.TEXT,
      allowNull: false,
      validate:  {
        isUrl: true,
      },
    },
    status:    {
      type:         DataTypes.TEXT,
      defaultValue: 'Unknown',
    },
    title:     {
      type: DataTypes.TEXT,
    },
    isExpired: {
      type:         DataTypes.BOOLEAN,
      defaultValue: false,
    },
    checkedAt: DataTypes.DATE,
    liveAt:    DataTypes.DATE,
    embedLink: {
      type:     DataTypes.TEXT,
      validate: {
        isUrl: true,
      }
    },
    postedBy:  DataTypes.TEXT,
    city:      DataTypes.TEXT,
    region:    DataTypes.TEXT,
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