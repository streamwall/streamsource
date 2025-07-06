require "rails_helper"

RSpec.describe CollaborativeStreamsChannel, type: :channel do
  let(:user) { create(:user, :admin) }
  let(:stream) { create(:stream) }

  before do
    stub_connection current_user: user
  end

  describe "#subscribed" do
    it "successfully subscribes to collaborative_streams channel" do
      subscribe

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("collaborative_streams")
    end

    it "broadcasts initial presence" do
      expect { subscribe }.to(have_broadcasted_to("collaborative_streams").with do |data|
        expect(data[:action]).to eq("user_joined")
        expect(data[:user_id]).to eq(user.id)
        expect(data[:user_email]).to eq(user.email)
        expect(data[:user_color]).to be_present
      end)
    end
  end

  describe "#unsubscribed" do
    before { subscribe }

    it "broadcasts user departure" do
      expect { unsubscribe }.to(have_broadcasted_to("collaborative_streams").with do |data|
        expect(data[:action]).to eq("user_left")
        expect(data[:user_id]).to eq(user.id)
      end)
    end

    it "releases all locks" do
      # Simulate having a lock
      Redis.current.setex("stream_lock:#{stream.id}:source", 300, user.id)

      unsubscribe

      expect(Redis.current.get("stream_lock:#{stream.id}:source")).to be_nil
    end
  end

  describe "#start_editing" do
    before { subscribe }

    it "acquires lock when field is not locked" do
      perform :start_editing, stream_id: stream.id, field: "source"

      expect(Redis.current.get("stream_lock:#{stream.id}:source")).to eq(user.id.to_s)
    end

    it "broadcasts lock acquired" do
      expect do
        perform :start_editing, stream_id: stream.id, field: "source"
      end.to(have_broadcasted_to("collaborative_streams").with do |data|
        expect(data[:action]).to eq("lock_acquired")
        expect(data[:stream_id]).to eq(stream.id)
        expect(data[:field]).to eq("source")
        expect(data[:user_id]).to eq(user.id)
      end)
    end

    it "rejects lock when field is already locked by another user" do
      other_user = create(:user, :admin)
      Redis.current.setex("stream_lock:#{stream.id}:source", 300, other_user.id)

      expect do
        perform :start_editing, stream_id: stream.id, field: "source"
      end.to(have_broadcasted_to("collaborative_streams").with do |data|
        expect(data[:action]).to eq("lock_denied")
        expect(data[:stream_id]).to eq(stream.id)
        expect(data[:field]).to eq("source")
        expect(data[:locked_by]).to eq(other_user.id)
      end)
    end

    it "allows same user to re-acquire their own lock" do
      Redis.current.setex("stream_lock:#{stream.id}:source", 300, user.id)

      expect do
        perform :start_editing, stream_id: stream.id, field: "source"
      end.to(have_broadcasted_to("collaborative_streams").with do |data|
        expect(data[:action]).to eq("lock_acquired")
      end)
    end
  end

  describe "#stop_editing" do
    before do
      subscribe
      Redis.current.setex("stream_lock:#{stream.id}:source", 300, user.id)
    end

    it "releases lock when user owns it" do
      perform :stop_editing, stream_id: stream.id, field: "source"

      expect(Redis.current.get("stream_lock:#{stream.id}:source")).to be_nil
    end

    it "broadcasts lock released" do
      expect do
        perform :stop_editing, stream_id: stream.id, field: "source"
      end.to(have_broadcasted_to("collaborative_streams").with do |data|
        expect(data[:action]).to eq("lock_released")
        expect(data[:stream_id]).to eq(stream.id)
        expect(data[:field]).to eq("source")
        expect(data[:user_id]).to eq(user.id)
      end)
    end

    it "does not release lock owned by another user" do
      other_user = create(:user, :admin)
      Redis.current.setex("stream_lock:#{stream.id}:source", 300, other_user.id)

      perform :stop_editing, stream_id: stream.id, field: "source"

      expect(Redis.current.get("stream_lock:#{stream.id}:source")).to eq(other_user.id.to_s)
    end
  end

  describe "#update_field" do
    before do
      subscribe
      Redis.current.setex("stream_lock:#{stream.id}:source", 300, user.id)
    end

    it "broadcasts field update when user has lock" do
      expect do
        perform :update_field, stream_id: stream.id, field: "source", value: "New Source"
      end.to(have_broadcasted_to("collaborative_streams").with do |data|
        expect(data[:action]).to eq("field_updated")
        expect(data[:stream_id]).to eq(stream.id)
        expect(data[:field]).to eq("source")
        expect(data[:value]).to eq("New Source")
        expect(data[:user_id]).to eq(user.id)
      end)
    end

    it "does not broadcast when user does not have lock" do
      Redis.current.del("stream_lock:#{stream.id}:source")

      expect do
        perform :update_field, stream_id: stream.id, field: "source", value: "New Source"
      end.not_to have_broadcasted_to("collaborative_streams")
    end
  end

  describe "#cursor_position" do
    before { subscribe }

    it "broadcasts cursor position to other users" do
      expect do
        perform :cursor_position, stream_id: stream.id, field: "source", position: 10
      end.to(have_broadcasted_to("collaborative_streams").with do |data|
        expect(data[:action]).to eq("cursor_moved")
        expect(data[:stream_id]).to eq(stream.id)
        expect(data[:field]).to eq("source")
        expect(data[:position]).to eq(10)
        expect(data[:user_id]).to eq(user.id)
      end)
    end
  end

  describe "#request_presence" do
    before { subscribe }

    it "broadcasts presence list" do
      # Add some presence data
      Redis.current.hset("presence:collaborative_streams", user.id, {
        email: user.email,
        color: "#FF0000",
        joined_at: Time.current.to_i,
      }.to_json)

      expect do
        perform :request_presence
      end.to(have_broadcasted_to("collaborative_streams").with do |data|
        expect(data[:action]).to eq("presence_list")
        expect(data[:users]).to be_an(Array)
        expect(data[:users].first[:id]).to eq(user.id)
      end)
    end
  end

  describe "edge cases" do
    before { subscribe }

    it "handles missing stream_id gracefully" do
      expect do
        perform :start_editing, stream_id: nil, field: "source"
      end.not_to raise_error
    end

    it "handles invalid field names" do
      expect do
        perform :start_editing, stream_id: stream.id, field: "invalid_field"
      end.not_to raise_error
    end

    it "handles Redis connection errors" do
      allow(Redis.current).to receive(:setex).and_raise(Redis::ConnectionError)

      expect do
        perform :start_editing, stream_id: stream.id, field: "source"
      end.not_to raise_error
    end
  end
end
