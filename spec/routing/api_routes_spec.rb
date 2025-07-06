require "rails_helper"

RSpec.describe "API Routes", type: :routing do
  describe "Users routes" do
    it "routes POST /api/v1/users/signup to users#signup" do
      expect(post: "/api/v1/users/signup").to route_to(
        controller: "api/v1/users",
        action: "signup",
      )
    end

    it "routes POST /api/v1/users/login to users#login" do
      expect(post: "/api/v1/users/login").to route_to(
        controller: "api/v1/users",
        action: "login",
      )
    end
  end

  describe "Streams routes" do
    it "routes GET /api/v1/streams to streams#index" do
      expect(get: "/api/v1/streams").to route_to(
        controller: "api/v1/streams",
        action: "index",
      )
    end

    it "routes GET /api/v1/streams/:id to streams#show" do
      expect(get: "/api/v1/streams/1").to route_to(
        controller: "api/v1/streams",
        action: "show",
        id: "1",
      )
    end

    it "routes POST /api/v1/streams to streams#create" do
      expect(post: "/api/v1/streams").to route_to(
        controller: "api/v1/streams",
        action: "create",
      )
    end

    it "routes PATCH /api/v1/streams/:id to streams#update" do
      expect(patch: "/api/v1/streams/1").to route_to(
        controller: "api/v1/streams",
        action: "update",
        id: "1",
      )
    end

    it "routes PUT /api/v1/streams/:id to streams#update" do
      expect(put: "/api/v1/streams/1").to route_to(
        controller: "api/v1/streams",
        action: "update",
        id: "1",
      )
    end

    it "routes DELETE /api/v1/streams/:id to streams#destroy" do
      expect(delete: "/api/v1/streams/1").to route_to(
        controller: "api/v1/streams",
        action: "destroy",
        id: "1",
      )
    end

    it "routes PUT /api/v1/streams/:id/pin to streams#pin" do
      expect(put: "/api/v1/streams/1/pin").to route_to(
        controller: "api/v1/streams",
        action: "pin",
        id: "1",
      )
    end

    it "routes DELETE /api/v1/streams/:id/pin to streams#unpin" do
      expect(delete: "/api/v1/streams/1/pin").to route_to(
        controller: "api/v1/streams",
        action: "unpin",
        id: "1",
      )
    end
  end

  describe "Health check routes" do
    it "routes GET /health to health#index" do
      expect(get: "/health").to route_to(
        controller: "health",
        action: "index",
      )
    end

    it "routes GET /health/live to health#live" do
      expect(get: "/health/live").to route_to(
        controller: "health",
        action: "live",
      )
    end

    it "routes GET /health/ready to health#ready" do
      expect(get: "/health/ready").to route_to(
        controller: "health",
        action: "ready",
      )
    end
  end

  describe "Unmatched routes" do
    it "does not route undefined paths" do
      expect(get: "/api/v1/undefined").not_to be_routable
      expect(post: "/api/v2/streams").not_to be_routable
      expect(get: "/api/streams").not_to be_routable
    end
  end
end
