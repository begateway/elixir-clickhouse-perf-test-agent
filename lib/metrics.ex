defmodule PTA.Metrics do
  use Prometheus.Metric
  require Logger

  def setup(histogram_backets) do
    Counter.declare(
      name: :total_read_queries,
      labels: [],
      help: "Total read queries count"
    )

    Counter.declare(
      name: :successful_read_queries,
      labels: [],
      help: "Successful read queries count"
    )

    Counter.declare(
      name: :failed_read_queries,
      labels: [],
      help: "Failed read queries count"
    )

    Counter.declare(
      name: :total_write_queries,
      labels: [],
      help: "Total write queries count"
    )

    Counter.declare(
      name: :successful_write_queries,
      labels: [],
      help: "Successful write queries count"
    )

    Counter.declare(
      name: :failed_write_queries,
      labels: [],
      help: "Failed write queries count"
    )

    Histogram.new(
      name: :read_query_duration_milliseconds,
      labels: [],
      buckets: histogram_backets,
      help: "Read query execution time"
    )

    Histogram.new(
      name: :write_query_duration_milliseconds,
      labels: [],
      buckets: histogram_backets,
      help: "Write query execution time"
    )
  end

  @spec query_result(type :: PTA.LoadAgent.query_type(), successful :: boolean()) :: :ok
  def query_result(:read, true) do
    Counter.inc(name: :total_read_queries)
    Counter.inc(name: :successful_read_queries)
  end

  def query_result(:read, false) do
    Counter.inc(name: :total_read_queries)
    Counter.inc(name: :failed_read_queries)
  end

  def query_result(:write, true) do
    Counter.inc(name: :total_write_queries)
    Counter.inc(name: :successful_write_queries)
  end

  def query_result(:write, false) do
    Counter.inc(name: :total_write_queries)
    Counter.inc(name: :failed_write_queries)
  end

  @spec query_time(type :: PTA.LoadAgent.query_type(), time :: pos_integer()) :: :ok
  def query_time(:read, time) do
    Histogram.observe([name: :read_query_duration_milliseconds], time)
  end

  def query_time(:write, time) do
    Histogram.observe([name: :write_query_duration_milliseconds], time)
  end

  def report do
    counters_report =
      [
        :total_read_queries,
        :successful_read_queries,
        :failed_read_queries,
        :total_write_queries,
        :successful_write_queries,
        :failed_write_queries
      ]
      |> Enum.map(fn name -> {name, Counter.value(name: name)} end)
      |> Enum.map(fn {name, value} -> " #{name}: #{value}" end)

    histograms_report =
      [
        :read_query_duration_milliseconds,
        :write_query_duration_milliseconds
      ]
      |> Enum.map(fn name ->
        {buckets, _total_time} = Histogram.value(name: name)
        {name, buckets}
      end)
      |> Enum.map(fn {name, buckets} -> " #{name}: #{inspect(buckets)}" end)

    report = (counters_report ++ histograms_report) |> Enum.join("\n")
    Logger.info("Metrics:\n#{report}")
  end
end
