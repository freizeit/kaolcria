defmodule Kaolcria do
  @moduledoc """
  Let's assume we have a dataset of users, and the city in which they live. We
  want to discover how many users live in each city. The process would be the
  following:

  | User id | City      |
  |---------|-----------|
  | 1       | Berlin    |
  | 2       | Berlin    |
  | 3       | Berlin    |
  | 4       | Berlin    |
  | 5       | Berlin    |
  | 6       | Berlin    |
  | 7       | Zagreb    |
  | 8       | Bucharest |
  | 9       | Bonn      |
  | 10      | K-town    |
  | 11      | K-town    |

  For each user you would report the tuple `(city, <CITY-NAME>)`, for example
  `(city, Berlin)`, `(city, Zagreb)`, etc.

  After the aggregation step, you would end up with:

  | key  | value     | count |
  |------|-----------|-------|
  | city | Berlin    | 6     |
  | city | Zagreb    | 1     |
  | city | Bucharest | 1     |
  | city | Bonn      | 1     |
  | city | K-town    | 2     |

  Which after the anonymization step ends up as

  | key  | value     | count |
  |------|-----------|-------|
  | city | Berlin    | 6     |

  In this case, the only information we could actually report to and end-user
  would be that 6 people live in Berlin, and that there might, or might not, be
  people living in other cities, but that we cannot really say whether that is
  the case or not.
  """


  @doc """
  Returns a sorted list with all the *.json files in the given `path`.
  """
  def list_json_files(path) do
    File.ls!(path)
    |> Enum.filter(fn f -> Regex.match?(~r/\.json$/, f) end)
    |> Enum.map(fn f -> path <> "/" <> f end)
    |> Enum.sort
  end


  @doc """
  Returns a sorted list (possibly empty) with all the airline purchase prices
  for the given `path`.
  """
  def extract_airline_purchases(path) do
    File.read!(path)
    |> Poison.Parser.parse!
    |> Access.get("purchases")
    |> Enum.filter(fn d -> d["type"] == "airline" end)
    |> Enum.map(fn d -> d["amount"] end)
    |> Enum.sort
  end


  @doc """
  Returns a (per-user) map (possibly empty) with airline purchase price counts
  for a given list with purchase prices (aka "report")
  """
  def get_airline_purchase_counts(prices) do
    prices
    |> Enum.map_reduce(%{}, fn(x, acc) ->
      Map.get_and_update(acc, x, fn(v) ->
        if v == nil do {nil,1} else {v,v+1} end end) end)
    |> elem(1)
  end


  @doc """
  Merges multiple airline purchase price counts maps and returns the results in
  a map (aka "aggregate").
  """
  def merge_airline_purchase_counts(prices) do
    merge_price_count_maps(%{}, prices)
  end

  defp merge_price_count_maps(result, []) do
    result
  end
  defp merge_price_count_maps(result, [pcm | pcms]) do
    result = pcm
    |> Enum.map_reduce(result, fn({price, count}, acc) ->
      Map.get_and_update(acc, price, fn(v) ->
        if v == nil do {nil,count} else {v,v+count} end end) end)
    |> elem(1)
    merge_price_count_maps(result, pcms)
  end


  @doc """
  Filters the given map with airline price counts so that only prices with
  counts of 6 or above remain (aka "anonymize").
  """
  def anonymize_airline_purchase_counts(pcm) do
    pcm |> Enum.filter(fn({_, count}) -> count >= 6 end) |> Enum.into(%{})
  end


  @doc """
  Processes, aggregates and anonymizes the data contained in the json files in
  the given directory.
  Returns an aggregated and anonymized map with airline price counts.
  """
  def process_json_files(path) do
    me = self
    list_json_files(path)
    |> Enum.map(fn path ->
        spawn_link fn ->
          result = extract_airline_purchases(path)
          |> get_airline_purchase_counts
          send me, result
        end
      end)
    |> Enum.map(fn(_) -> receive do result -> result end end)
    |> merge_airline_purchase_counts
    |> anonymize_airline_purchase_counts
  end
end
