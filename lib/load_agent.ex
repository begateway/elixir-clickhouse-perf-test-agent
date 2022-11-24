defmodule LoadAgent do
  use GenServer
  require Logger

  def start_link(options) do
    GenServer.start_link(__MODULE__, options)
  end

  def init(options) do
    state = %{
      query: Map.fetch!(options, :query),
      rate: Map.fetch!(options, :rate)
    }

    Logger.info("Run LoadAgent with state #{inspect(state)}")
    {:ok, state}
  end
end
