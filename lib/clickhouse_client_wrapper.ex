defmodule PTA.ClickhouseClientWrapper do
  alias Pillar.Connection
  alias Pillar.QueryBuilder

  require Logger

  def check_connection() do
    connection()
    |> Pillar.query("SELECT 1")
    |> case do
      {:ok, 1} -> :ok
      other -> other
    end
  end

  def insert_to_table(table, rows) do
    connection()
    |> Pillar.insert_to_table(table, rows)
  end

  defp connection() do
    Application.fetch_env!(:perf_test_agent, :clickhouse_url)
    |> Connection.new()
  end

  def query(client, query, params \\ %{})

  def query(:pillar_0, query, params) do
    connection()
    |> Pillar.query(query, params)
  end

  def query(:pillar_1, query, params) do
    connection()
    |> Pillar.query(query, params, %{db_side_batch_insertions: true})
  end

  def query(:hackney_0, query, params) do
    # NOTE: hackney is not usable
    # A lot of 'checkout_timeout' errors with 20 RPS inserts.
    # Increasing pool size to 100 connection doesn't help it.
 
    url = connection() |> Connection.url_from_connection()
    headers = []
    payload = QueryBuilder.query(query, params)
    options = [{:pool, :clickhouse}]

    case :hackney.post(url, headers, payload, options) do
      {:ok, 200, _, _} -> {:ok, ""}
      {:ok, status_code, _, _} -> {:error, status_code}
      {:error, error} -> {:error, error}
    end
  end

  def try_postgrex do
    Logger.info("try postgrex")

    {:ok, pid} = Postgrex.start_link(
      hostname: "localhost",
      port: 9005,
      username: "pta_user",
      password: "pta",
      database: "pta_db"
    )
    Logger.info("connected to DB #{inspect pid}")

    # NOTE: it doesn't work.
    # Postgrex does query to pg_attribute which is not supported by Clickhouse
    # ClickHouse server version 22.8.5 revision 54460.
    # Postgrex version 0.16.5
    
    # 13:48:51.129 [info]  try postgrex
    # 13:48:51.130 [info]  connected to DB #PID<0.472.0>
    # 13:48:51.132 [error] Postgrex.Protocol (#PID<0.474.0>) failed to connect: ** (Postgrex.Error) ERROR 2F000 (sql_routine_exception) Query execution failed.
    # DB::Exception: Syntax error: failed at position 159 ('a') (line 3, col 10): a.atttypid
    #   FROM pg_attribute AS a
    #   WHERE a.attrelid = t.typrelid AND a.attnum > 0 AND NOT a.attisdropped
    #   ORDER BY a.attnum
    # )
    # FROM pg_type AS t
    # LEFT JOIN pg. Expected one of: token, Comma, Arrow, Dot, UUID, DoubleColon, MOD, DIV, NOT, BETWEEN, LIKE, ILIKE, NOT LIKE, NOT ILIKE, IN, NOT IN, GLOBAL IN, GLOBAL NOT IN, IS, AND, OR, QuestionMark, alias, AS, end of query

    res = Postgrex.query!(pid, "SELECT uid, name FROM cats LIMIT 5", [])
    Logger.info(res)

    now = NaiveDateTime.utc_now()
    res = Postgrex.query!(pid,
      """
      INSERT INTO cats (uid, name, created_at, updated_at, 
      number_of_paws, number_of_tails, age) 
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      """,
      [Ecto.UUID.generate(), "Tihon", now, now, 4, 1, 12]
    )
    Logger.info(res)
  end

  def try_epgsql do
  end

end
