import Config

config :liveview_continuity, ContinuityFixtureWeb.Endpoint,
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  http: [ip: {127, 0, 0, 1}, port: 4140],
  server: true,
  secret_key_base: String.duplicate("continuity", 8),
  live_view: [signing_salt: "continuity-salt"],
  pubsub_server: ContinuityFixture.PubSub,
  check_origin: false

config :phoenix, :json_library, Jason
config :logger, level: :warning
