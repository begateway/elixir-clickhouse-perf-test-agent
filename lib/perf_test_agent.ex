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
      queries_settings = Application.fetch_env!(@app, :queries)
      queries_dir = Application.app_dir(@app, queries_settings.queries_dir)
      table_settings = Application.fetch_env!(@app, :table)

      load_manager_args = %{
        perf_test_duration:
          Application.fetch_env!(@app, :perf_test_duration)
          |> Utils.miliseconds_duration(),
        start_agent_pause:
          Application.fetch_env!(@app, :start_agent_pause)
          |> Utils.miliseconds_duration(),
        read_queries_file: Path.join(queries_dir, queries_settings.read_queries_file),
        write_queries_file: Path.join(queries_dir, queries_settings.write_queries_file)
      }

      db_state_args = %{
        clickhouse_url: clickhouse_url,
        create_table_file: Path.join(queries_dir, queries_settings.create_table_file),
        table_name: table_settings.name,
        create_table?: table_settings.create_table?,
        fill_table?: table_settings.fill_table?
      }

      spec = [
        {LoadAgentSup, :no_args},
        {LoadManager, load_manager_args},
        {DbState, db_state_args}
      ]

      Supervisor.init(spec, strategy: :rest_for_one)
    end
  end
end
