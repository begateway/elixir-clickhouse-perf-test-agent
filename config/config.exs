import Config

config :perf_test_agent,
  clickhouse_url: "http://pta_user:pta@localhost:8123/pta_db",

  # Choose client one of:
  # :pillar_0 -- Pillar with db_side_batch_insertions: false
  # :pillar_1 -- Pillar with db_side_batch_insertions: true
  # :hackney
  client: :pillar_1,

  # Table for queries
  table: %{
    name: "cats",
    create_table?: true,
    fill_table?: true
  },
  queries: %{
    queries_dir: "priv/queries",
    create_table_file: "create_table.sql",
    read_queries_file: "read.sql",
    write_queries_file: "write.sql",
    insert_data_file: "data.json"
  },

  # Histogram backets in milliseconds
  histogram_backets: [1, 10, 20, 50, 100, 300, 500, 750, 1000],

  # Total duration of perf test session
  perf_test_duration: {5, :min},

  # Pause between starting load agents
  start_agent_pause: {10, :sec},

  # Clickhouse metrics
  clickhouse_metrics: %{
    "system.events" => [
      "Query",
      "SelectQuery",
      "InsertQuery",
      "AsyncInsertQuery",
      "FailedQuery",
      "SelectQueryTimeMicroseconds",
      "InsertQueryTimeMicroseconds",
      "InsertedRows",
      "Merge",
      "MergedRows"
    ],
    "system.metrics" => %{
      "name_equal" => [
        "Query",
        "Merge",
        "TCPConnection",
        "Read",
        "Write",
        "QueryThread",
        "MemoryTracking",
        "DelayedInserts",
        "StorageBufferRows",
        "StorageBufferBytes",
        "KeeperAliveConnections"
      ],
      "name_like" => []
    },
    "system.asynchronous_metrics" => %{
      "name_equal" => [],
      "name_like" => ["CPUFrequency%", "Memory%"]
    }
  }
