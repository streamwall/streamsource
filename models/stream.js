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

    async useInferredLocation() {
      this.city = await this.getInferredCity()
      this.region = await this.getInferredRegion()
    }

    async getInferredCity() {
      const commonCity = await Stream.findOne({
        where:      {
          [Op.or]: [
            { source: { [Op.iLike]: this.source } },
            { link: { [Op.iLike]: this.link } },
          ],
          city: {
            [Op.not]: null,
          }
        },
        group:      ['city'],
        attributes: ['city', [sequelize.fn('COUNT', 'city'), 'freq']],
        order: [[sequelize.fn('COUNT', 'city'), 'DESC']]
      })
      return commonCity.get('city')
    }

    async getInferredRegion() {
      const commonRegion = await Stream.findOne({
        where:      {
          [Op.or]: [
            { source: { [Op.iLike]: this.source } },
            { link: { [Op.iLike]: this.link } },
          ],
          region: {
            [Op.not]: null,
          }
        },
        group:      ['region'],
        attributes: ['region', [sequelize.fn('COUNT', 'region'), 'freq']],
        order: [[sequelize.fn('COUNT', 'region'), 'DESC']]
      })
      return commonRegion.get('region')
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