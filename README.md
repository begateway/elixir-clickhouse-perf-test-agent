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

There are enough configuration to adapt the perf test for different data schemas and usage scenarious.


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

I belive any of those libraries could be forked and adapt to work with Clickhouse. Maybe I will do it. Btw writing a client library which supports a native Clickhouse protocol is not a bad idea.


## Test Results

I only did perf tests for Pillar with `db_side_batch_insertions` true and false. However I did it on several databases with different amount of data and different loads. The results were the similar.

For example, this is the results on my local computer:


### Agent Metrics

60 columns table, 500 rows inserted before test.
Load for 3 minutes, 100 RPS inserts, 7 RPS selects.


#### No batching 

Total read queries: 1,202
Total write queries: 28,571

Query Latency:

| millisecond buckets | 1 |     10 |    20 |  50 | 100 | 300 | 500 | 750 | 1000 | >1000 |
|:--------------------|--:|-------:|------:|----:|----:|----:|----:|----:|-----:|------:|
| read                | 0 |     12 |   659 | 528 |   3 |   0 |   0 |   0 |    0 |     0 |
| write               | 0 | 27,007 | 1,426 | 138 |   0 |   0 |   0 |   0 |    0 |     0 |

 
#### With batching

total_read_queries: 1,202 no errors
total_write_queries: 28,565 no errors

Query Latency:

| millisecond buckets | 1 | 10 |  20 |    50 |   100 |    300 | 500 | 750 | 1000 | >1000 |
|:--------------------|--:|---:|----:|------:|------:|-------:|----:|----:|-----:|------:|
| read                | 0 |  5 | 525 |   670 |     2 |      0 |   0 |   0 |    0 |     0 |
| write               | 0 |  0 |  43 | 3,949 | 6,863 | 17,710 |   0 |   0 |    0 |     0 |


### Clickhouse Metrics

| Metric                      | no batching | with batching |
|:----------------------------|------------:|--------------:|
| Query                       |      29,894 |         1,323 |
| AsyncInsertQuery            |           0 |        28,569 |
| FailedQuery                 |           0 |             0 |
| SelectQuery                 |       1,220 |         1,221 |
| SelectQueryTimeMicroseconds |  19,555,295 |    21,166,457 |
| InsertQuery                 |      28,672 |           100 |
| InsertQueryTimeMicroseconds | 121,836,505 | 3,504,147,597 |
| InsertedRows                |     338,906 |       244,254 |
| Merge                       |      87,746 |        45,632 |
| MergedRows                  |  91,174,606 |    76,613,087 |
| CPUFrequencyMHz\_0          |    1507.776 |           400 |
| CPUFrequencyMHz\_1          |    1573.985 |           400 |
| CPUFrequencyMHz\_2          |         400 |           400 |
| CPUFrequencyMHz\_3          |         400 |      1773.592 |
| CPUFrequencyMHz\_4          |         400 |           400 |
| CPUFrequencyMHz\_5          |         400 |           400 |
| CPUFrequencyMHz\_6          |         400 |           400 |
| CPUFrequencyMHz\_7          |         400 |           400 |
| CPUFrequencyMHz\_8          |    1127.613 |           400 |
| CPUFrequencyMHz\_9          |         400 |           400 |
| CPUFrequencyMHz\_10         |         400 |           400 |
| CPUFrequencyMHz\_11         |         400 |           400 |
| MemoryCode                  |        291M |          291M |
| MemoryDataAndStack          |     31,332M |       31,450M |
| MemoryResident              |      3,861M |        2,427M |
| MemoryShared                |        399M |          404M |
| MemoryTracking              |      3,891M |        2,466M |
| MemoryVirtual               |     32,265M |       32,383M |


### Conclusion

It is a classical tradeoff: latency vs throughput. 

Batching increases throughput with costs of increased latency. However 300ms is good enough for us.

One more thing: sometimes we had timeout errors in our production:
```
{:error, %Pillar.HttpClient.TransportError{reason: :timeout}})
```
We haven't had them since we enabled batching.
