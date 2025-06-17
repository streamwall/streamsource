require 'swagger_helper'

RSpec.describe 'api/v1/streams', type: :request do
  let(:user) { create(:user) }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:Authorization) { "Bearer #{token}" }

  path '/api/v1/streams' do
    get('list streams') do
      tags 'Streams'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true, description: 'JWT Bearer token'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page (max 100)'

      response(200, 'successful') do
        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :integer },
                       name: { type: :string },
                       description: { type: :string },
                       source_url: { type: :string },
                       is_pinned: { type: :boolean },
                       created_at: { type: :string, format: 'date-time' },
                       updated_at: { type: :string, format: 'date-time' }
                     }
                   }
                 },
                 meta: {
                   type: :object,
                   properties: {
                     current_page: { type: :integer },
                     total_pages: { type: :integer },
                     total_count: { type: :integer },
                     per_page: { type: :integer }
                   }
                 }
               }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(401, 'unauthorized') do
        let(:Authorization) { 'Bearer invalid' }
        run_test!
      end
    end

    post('create stream') do
      tags 'Streams'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true, description: 'JWT Bearer token'
      parameter name: :stream, in: :body, schema: {
        type: :object,
        properties: {
          stream: {
            type: :object,
            properties: {
              name: { type: :string },
              description: { type: :string },
              source_url: { type: :string },
              is_pinned: { type: :boolean }
            },
            required: ['name', 'source_url']
          }
        }
      }

      response(201, 'created') do
        let(:stream) { { stream: { name: 'Test Stream', source_url: 'https://example.com/stream', description: 'Test description' } } }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'unprocessable entity') do
        let(:stream) { { stream: { name: '' } } }
        run_test!
      end
    end
  end

  path '/api/v1/streams/{id}' do
    parameter name: 'id', in: :path, type: :string, description: 'Stream ID'

    get('show stream') do
      tags 'Streams'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true, description: 'JWT Bearer token'

      response(200, 'successful') do
        let(:id) { create(:stream, user: user).id }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(404, 'not found') do
        let(:id) { 'invalid' }
        run_test!
      end
    end

    put('update stream') do
      tags 'Streams'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true, description: 'JWT Bearer token'
      parameter name: :stream, in: :body, schema: {
        type: :object,
        properties: {
          stream: {
            type: :object,
            properties: {
              name: { type: :string },
              description: { type: :string },
              source_url: { type: :string },
              is_pinned: { type: :boolean }
            }
          }
        }
      }

      response(200, 'successful') do
        let(:id) { create(:stream, user: user).id }
        let(:stream) { { stream: { name: 'Updated Stream' } } }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end

    delete('delete stream') do
      tags 'Streams'
      produces 'application/json'
      parameter name: :Authorization, in: :header, type: :string, required: true, description: 'JWT Bearer token'

      response(204, 'no content') do
        let(:id) { create(:stream, user: user).id }
        run_test!
      end
    end
  end
end