import Config

config :perf_test_agent,
  clickhouse_url: "http://pta_user:pta@localhost:8123/pta_db",
  # session duration in minutes
  session_duration: 10,
  # ramp up time in minutes
  ramp_up: 2
