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
      clickhouse_url = Application.fetch_env!(@app, :clickhouse_url)
      queries_dir = Application.app_dir(@app, "priv/queries")

      db_state_options = %{
        clickhouse_url: clickhouse_url,
        queries_dir: queries_dir
      }

      agent_sup_options = %{
        queries_dir: queries_dir
      }

      spec = [
        {DbState, db_state_options},
        {LoadAgentSup, agent_sup_options}
      ]

      Supervisor.init(spec, strategy: :rest_for_one)
    end
  end
end
