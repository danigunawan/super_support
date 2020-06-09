# frozen_string_literal: true

RSpec.describe 'Users', type: :request do
  describe '#test for valid tickets' do
    it 'tests that an authenticated user can create a ticket' do
      # create a user
      params = { name: 'test_user', email: 'test@test.com', password: 'password', password_confirmation: 'password' }
      headers = { 'Accept': 'application/json', 'Content-Type': 'application/json' }
      post '/api/v1/users', params: params.to_json, headers: headers
      user = JSON.parse(response.body)

      # create a ticket
      ticket_params = { user_id: user['user']['user_id'], title: 'test ticket' }
      headers = { 'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': "Bearer #{user['token']}" }
      post '/api/v1/tickets', params: ticket_params.to_json, headers: headers
      ticket = JSON.parse(response.body)
      expect(response).to have_http_status(200)
    end

    it 'tests that a user can see access created tickets' do
      # create a user
      params = { name: 'test_user', email: 'test@test.com', password: 'password', password_confirmation: 'password' }
      headers = { 'Accept': 'application/json', 'Content-Type': 'application/json' }
      post '/api/v1/users', params: params.to_json, headers: headers
      user = JSON.parse(response.body)

      # create a ticket
      ticket_params = { user_id: user['user']['user_id'], title: 'test ticket' }
      headers = { 'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': "Bearer #{user['token']}" }
      post '/api/v1/tickets', params: ticket_params.to_json, headers: headers

      # create another ticket
      ticket_params = { user_id: user['user']['user_id'], title: 'test ticket' }
      headers = { 'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': "Bearer #{user['token']}" }
      post '/api/v1/tickets', params: ticket_params.to_json, headers: headers
      ticket = JSON.parse(response.body)
      get '/api/v1/tickets', headers: headers
      tickets = JSON.parse(response.body)

      # test that created tickets are successfully returned
      expect(response).to have_http_status(200)
      # test that the second ticket is created
      expect(tickets['tickets'][0]['id']).to eq(2)
    end

    it 'tests that authenticated users can see comments on a ticket' do
      # create a user
      params = { name: 'test_user', email: 'test@test.com', password: 'password', password_confirmation: 'password' }
      headers = { 'Accept': 'application/json', 'Content-Type': 'application/json' }
      post '/api/v1/users', params: params.to_json, headers: headers
      user = JSON.parse(response.body)

      # create a ticket
      ticket_params = { user_id: user['user']['user_id'], title: 'test ticket' }
      headers = { 'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': "Bearer #{user['token']}" }
      post '/api/v1/tickets', params: ticket_params.to_json, headers: headers
      tickets = JSON.parse(response.body)

      # create a comment
      comment_params = { user_id: user['user']['user_id'], user_name: user['user']['name'], ticket_id: tickets['ticket']['id'], comment: 'test comment' }
      headers = { 'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': "Bearer #{user['token']}" }
      post "/api/v1/tickets/#{tickets['ticket']['id']}/comments", params: comment_params.to_json, headers: headers
      comments_response = JSON.parse(response.body)

      expect(response).to have_http_status(200)
      expect(comments_response['comment']['id']).to eq(1)

      # check that created comment belongs to ticket
      get "/api/v1/tickets/#{tickets['ticket']['id']}"
      tickets_response = JSON.parse(response.body)
      expect(tickets_response['comments'][0]).to eq(comments_response['comment'])
    end

    it 'tests that only an admin can destroy tickets' do
      # create a user
      params = { name: 'test_user', email: 'test@test.com', password: 'password', password_confirmation: 'password' }
      headers = { 'Accept': 'application/json', 'Content-Type': 'application/json' }
      post '/api/v1/users', params: params.to_json, headers: headers

      # make user an admin
      user = JSON.parse(response.body)
      user = User.find(user['user']['user_id'])
      user.update(role: 'admin')

      # login the super_user
      login_params = { email: user.email, password: 'password' }
      post '/api/v1/login', params: login_params
      super_user = JSON.parse(response.body)

      # create a ticket
      ticket_params = { user_id: user.id, title: 'test ticket' }

      headers = { 'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': "Bearer #{super_user['token']}" }
      post '/api/v1/tickets', params: ticket_params.to_json, headers: headers
      tickets = JSON.parse(response.body)

      # delete the ticket
      delete "/api/v1/tickets/#{tickets['ticket']['id']}", headers: headers
      expect(response).to have_http_status(204)
    end

    describe '# invalid tickets cannot be created' do
      it 'tests that an unauthorized user cannot create a ticket' do
        # create a user
        params = { name: 'test_user', email: 'test@test.com', password: 'password', password_confirmation: 'password' }
        headers = { 'Accept': 'application/json', 'Content-Type': 'application/json' }
        post '/api/v1/users', params: params.to_json, headers: headers
        user = JSON.parse(response.body)

        # create a ticket
        ticket_params = { user_id: user['user']['user_id'], title: 'test ticket' }
        headers = { 'Accept': 'application/json', 'Content-Type': 'application/json' }
        post '/api/v1/tickets', params: ticket_params.to_json, headers: headers
        tickets = JSON.parse(response.body)
        expect(response).to have_http_status(401)
        expect(response.body).to include('not authorized')
      end
    end
  end
end