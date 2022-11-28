import Config

config :perf_test_agent,
  clickhouse_url: "http://pta_user:pta@localhost:8123/pta_db",
  table: %{
    name: "cats",
    create_table?: true,
    fill_table?: true
  },
  queries: %{
    queries_dir: "priv/queries",
    create_table_file: "create_table.sql",
    read_queries_file: "read.sql",
    write_queries_file: "write.sql"
  },

  # total duration of perf test session
  perf_test_duration: {3, :min},

  # pause between starting load agents
  start_agent_pause: {10, :sec}
