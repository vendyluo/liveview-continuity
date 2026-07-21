defmodule ContinuityFixtureWeb.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:put_root_layout, html: {ContinuityFixtureWeb.Layout, :root})
  end

  scope "/" do
    pipe_through(:browser)
    live("/", ContinuityFixtureWeb.MenuLive)
  end
end
