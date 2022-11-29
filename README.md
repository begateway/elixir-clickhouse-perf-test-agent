# Elixir-to-Clickhouse Performance Testing Agent

Find optional way to work with ClickHouse from Elixir.

The idea is to try different clients for Clickhouse 
https://clickhouse.com/docs/en/interfaces

- Pillar
- Just a http client (Hackney)
- Postgres driver
- MySQL driver
- Clickhousex

Use them to create load (insert and select) queries. Then gather client-side and server-side metrics. And finally choose the optinal client.


## Setup environment

It is recommended to create a separate database instead of using `default` of one of existing databases.

By default `clickhouse_url` is "http://pta_user:pta@localhost/pta_db". If you need to redefine it do it in `config/dev.exs`.


## Clients

Clickhouse supports many ways to connect it:
https://clickhouse.com/docs/en/interfaces

Clients we have tryed:
- [:pillar_0](https://hex.pm/packages/pillar) (HTTP) -- Pillar with `db_side_batch_insertions: false`
- [:pillar_1](https://hex.pm/packages/pillar) (HTTP) -- Pillar with `db_side_batch_insertions: true`
- [:hackney](https://hex.pm/packages/hackney) (HTTP) -- works but we have a lot of `checkout_timeout` errors
- [:postgrex](https://hex.pm/packages/postgrex) (PostgreSQL) -- connected, but crashed after that
- [:epgsql](https://hex.pm/packages/epgsql) (PostgreSQL) -- not connected
- [:myxql](https://hex.pm/packages/myxql) (MySQL) -- not connected
- [:mysql](https://hex.pm/packages/mysql) (MySQL) -- not connected

In fact we failed to use postgresql or mysql procotol with Clickhouse. So the HTTP procotol is the only option.
