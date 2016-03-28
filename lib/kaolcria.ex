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
    case File.ls(path) do
      {:ok, fs} -> {:ok,
        fs
        |> Enum.filter(fn f -> Regex.match?(~r/\.json$/, f) end)
        |> Enum.map(fn f -> path <> "/" <> f end)
        |> Enum.sort}
      {:error, _} = ev -> ev
    end
  end


  @doc """
  Returns a sorted list (possibly empty) of 2-tuples where the first element is
  the purchase type and the second element is the purchase price respectively.
  All the prices in the returned list will be unique.
  """
  def extract_purchases(path) do
    case File.read(path) do
      {:error, _} = err -> err
      {:ok, body} -> {:ok,
        body
        |> Poison.Parser.parse!
        |> Access.get("purchases")
        |> Enum.map(fn d -> {d["type"], d["amount"]} end)
        |> Enum.sort
        |> Enum.dedup}
    end
  end


  @doc """
  Merges a list of lists with item/price tuples and returns the counts
  in a map (aka "aggregate").
  Assumption: all item/price tuples are unique with respect to the list that
  contains them.
  """
  def merge_purchase_counts(prices) do
    merge_purchase_lists(%{}, prices)
  end


  defp merge_purchase_lists(result, []) do
    result
  end
  defp merge_purchase_lists(result, [pcm | pcms]) do
    result = pcm
    |> Enum.map_reduce(result, fn(price, acc) ->
      Map.get_and_update(acc, price, fn(v) ->
        if v == nil do {nil,1} else {v,v+1} end end) end)
    |> elem(1)
    merge_purchase_lists(result, pcms)
  end


  @doc """
  Filters the given map with airline price counts so that only prices with
  counts of 6 or above remain (aka "anonymize").
  """
  def anonymize_purchase_counts(pcm) do
    pcm |> Enum.filter(fn({_, count}) -> count >= 6 end) |> Enum.into(%{})
  end


  @doc """
  Processes, aggregates and anonymizes the data contained in the json files in
  the given directory.
  Returns an aggregated and anonymized map with airline price counts.
  """
  def process_json_files(path) do
    case list_json_files(path) do
      {:ok, files} ->
        me = self

        ### report
        files
        |> Enum.map(fn path ->
          spawn_link fn ->
              case extract_purchases(path) do
                {:ok, prices} -> send me, {:ok, prices}
                {:error, ev} -> send me, {:error, ev, path}
              end
            end
          end)
        |> Enum.map(fn(_pid) -> receive do
              {:ok, result} -> result
              {:error, err, path} ->
                IO.puts(:stderr, "Error: #{err} :: #{path}")
                %{}
            end
          end)
        ### aggregate
        |> merge_purchase_counts
        ### anonymize
        |> anonymize_purchase_counts
      {:error, err} ->
        IO.puts(:stderr, "Error: #{err} :: #{path}")
        %{}
    end
  end


  @doc """
  Return the average of a map with aggregated and anonymized airline
  purchase prices.
  """
  def aaapp_average(maaapp) when maaapp != %{} do
    sum = maaapp
    |> Map.keys
    |> Enum.reduce(0, fn({_pt, pv}, acc) -> pv + acc end)
    sum/Enum.count(maaapp)
  end
  def aaapp_average(_), do: 0


  @doc """
  Return the median of a map with aggregated and anonymized airline
  purchase prices.
  """
  def aaapp_median(maaapp) when maaapp != %{} do
    keys = Map.keys(maaapp) |> Enum.sort
    num_keys = Enum.count(keys)
    if rem(num_keys, 2) == 1 do
      # odd number of keys
      Enum.at(keys, div(num_keys, 2)) |> elem(1)
    else
      {_, m1} = Enum.at(keys, div(num_keys, 2) - 1)
      {_, m2} = Enum.at(keys, div(num_keys, 2))
      (m1 + m2)/2
    end
  end
  def aaapp_median(_), do: 0
end
