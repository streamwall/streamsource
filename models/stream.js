'use strict';
const { Op } = require("sequelize");

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

    // Assign self.city and self.location "automatically."
    // Does nothing if either city or region are already set
    // Assumes that the last entered location for a streamer is correct.
    // Does not automatically save to the database
    // Does nothing if no past streams exist that match self.source or self.link
    async inferLocation() {
      if (this.city || this.region) {
        return
      }

      // Assumes that the pastStream.source is "unique-enough";
      // However, we know that multiple streamers sometimes
      // use the same name to stream, e.g., Bear Gang, Concrete Reporting, Unicorn Riot, Boop Troop, etc.
      const pastStream = await Stream.findOne({
        where: {
          [Op.and]: [
            {
              [Op.or]: [
                { source: this.source },
                { link: this.link },
              ]
            },
            {
              [Op.or]: [
                {
                  city: {
                    [Op.not]: null,
                    [Op.not]: ''
                  }
                },
                {
                  region: {
                    [Op.not]: null,
                    [Op.not]: ''
                  }
                },
              ]
            }
          ]
        },
        order: [['createdAt', 'DESC']]
      })
      this.city = (pastStream && pastStream.city) || ''
      this.region = (pastStream && pastStream.region) || ''
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
    hooks:     {
      beforeSave: async (stream, options) => {
        await stream.inferLocation()
      },
    },
    sequelize,
    modelName: 'Stream',
  });
  return Stream;
};