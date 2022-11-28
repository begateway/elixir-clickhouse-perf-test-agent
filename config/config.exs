import Config

config :perf_test_agent,
  clickhouse_url: "http://pta_user:pta@localhost:8123/pta_db",

  # one of: :pillar_0, :pillar_1, :hackney_0, :hackney_1, :postgres, :mysql, :clickhousex
  client: :hackney_0,
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
  # histogram_backets: [50, 100, 300, 500, 750, 1000],
  histogram_backets: [1, 10, 20, 50, 100, 300, 500, 750, 1000],

  # total duration of perf test session
  perf_test_duration: {3, :min},

  # pause between starting load agents
  start_agent_pause: {10, :sec}
