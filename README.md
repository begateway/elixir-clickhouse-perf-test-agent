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
