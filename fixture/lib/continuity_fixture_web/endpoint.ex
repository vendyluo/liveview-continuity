defmodule ContinuityFixtureWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :liveview_continuity

  @session_options [store: :cookie, key: "_continuity", signing_salt: "fixture"]

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])
  plug(Plug.Static, at: "/", from: Path.expand("../../priv/static", __DIR__))
  plug(Plug.Session, @session_options)
  plug(ContinuityFixtureWeb.Router)
end
