import Config

config :perf_test_agent,
  clickhouse_url: "http://pta_user:pta@localhost:8123/pta_db",

  # total duration of perf test session
  perf_test_duration: {10, :min},

  # pause between starting load agents
  start_agent_pause: {10, :sec}
