import Config

config :perf_test_agent,
  clickhouse_url: "http://pta_user:pta@localhost:8123/pta_db",
  session_duration: {10, :min},
  ramp_up: {2, :min}
