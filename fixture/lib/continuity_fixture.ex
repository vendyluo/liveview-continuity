defmodule ContinuityFixture do
  @moduledoc false

  def start do
    children = [
      {Phoenix.PubSub, name: ContinuityFixture.PubSub},
      ContinuityFixtureWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: ContinuityFixture.Supervisor)
  end
end
