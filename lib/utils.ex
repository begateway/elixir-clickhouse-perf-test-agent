defmodule Utils do
  def miliseconds_duration({duration, :min}), do: duration * 60 * 1000
  def miliseconds_duration({duration, :sec}), do: duration * 1000
end
