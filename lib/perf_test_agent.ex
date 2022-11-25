defmodule PerfTestAgent do
  use Application
  require Logger

  def start(_start_type, _args) do
    Logger.info("Start PerfTestAgent")
    PerfTestAgent.RootSup.start_link(:no_args)
  end

  defmodule RootSup do
    use Supervisor

    @app :perf_test_agent

    def start_link(:no_args) do
      Supervisor.start_link(__MODULE__, :no_args)
    end

    @impl true
    def init(:no_args) do
      db_state_options = %{
        clickhouse_url: Application.fetch_env!(@app, :clickhouse_url),
        queries_dir: Application.app_dir(@app, "priv/queries")
      }

      start_agent_pause =
        Application.fetch_env!(@app, :start_agent_pause)
        |> Utils.miliseconds_duration()

      spec = [
        {LoadAgentSup, :no_args},
        {LoadManager, %{start_agent_pause: start_agent_pause}},
        {DbState, db_state_options}
      ]

      Supervisor.init(spec, strategy: :rest_for_one)
    end
  end
end
