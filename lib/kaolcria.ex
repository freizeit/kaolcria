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
  the purchase type and the second element is the purchase price respectively
  (aka "report").
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
  def merge_purchases(prices) do
    merge_purchase_lists(%{}, prices)
  end


  defp merge_purchase_lists(result, []), do: result
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
  def anonymize_purchases(pcm, anonymize \\ true) do
    case anonymize do
      true -> pcm |> Enum.filter(fn({_, count}) -> count >= 6 end) |> Enum.into(%{})
      false -> pcm
    end
  end


  @doc """
  Processes, aggregates and anonymizes the data contained in the json files in
  the given directory.
  Returns an aggregated and anonymized map with airline price counts.
  """
  def process_json_files(path, anonymize \\ true) do
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
        |> merge_purchases
        ### anonymize
        |> anonymize_purchases(anonymize)
      {:error, err} ->
        IO.puts(:stderr, "Error: #{err} :: #{path}")
        %{}
    end
  end


  @doc """
  Return the average of a map with aggregated (and anonymized?)
  purchase prices.
  """
  def p_average(pps, ptype \\ "airline")
  def p_average(pps, ptype) when pps != %{} do
    keys = Map.keys(pps)
    |> Enum.filter(fn({pt, _pv}) -> pt == ptype end)
    sum = keys |> Enum.reduce(0, fn({_pt, pv}, acc) -> pv + acc end)
    sum/Enum.count(keys)
  end
  def p_average(_pps, _ptype), do: 0


  @doc """
  Return the median of a map with aggregated (and anonymized?)
  purchase prices.
  """
  def p_median(pps, ptype \\ "airline")
  def p_median(pps, ptype) when pps != %{} do
    keys = Map.keys(pps)
    |> Enum.filter(fn({pt, _pv}) -> pt == ptype end)
    |> Enum.sort
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
  def p_median(_pps, _ptype), do: 0


  @doc """
  Return the minimum of a map with aggregated (and anonymized?)
  purchase prices.
  """
  def p_min(pps, ptype \\ "airline")
  def p_min(pps, ptype) when pps != %{} do
    Map.keys(pps)
    |> Enum.filter(fn({pt, _pv}) -> pt == ptype end)
    |> Enum.min
    |> elem(1)
  end
  def p_min(_pps, _ptype), do: 0


  @doc """
  Return the maximum of a map with aggregated (and anonymized?)
  purchase prices.
  """
  def p_max(pps, ptype \\ "airline")
  def p_max(pps, ptype) when pps != %{} do
    Map.keys(pps)
    |> Enum.filter(fn({pt, _pv}) -> pt == ptype end)
    |> Enum.max
    |> elem(1)
  end
  def p_max(_pps, _ptype), do: 0


  @doc """
  Main function.

  Process json files with purchase data

    --debug      print debug data
    --help       print this help
    --anonymize  anonymize purchase data [default: true]
    --path       path to the json data files [default: "data"]
    --tag        purchase tags to process [default: "airline"]
  """
  def main(argv) do
    { parse, _, _ } = OptionParser.parse(
      argv, strict: [
        debug: :boolean, help: :boolean, anonymize: :boolean, path: :string,
        tag: :string])

    if parse[:help] do
      print_help()
      System.halt(0)
    end

    params = Map.merge(
      %{debug: false, anonymize: true, path: "data", tag: "airline"},
      parse |> Enum.into(%{}))

    if params[:debug] == true do
      IO.puts("\n>> command line args:")
      IO.inspect parse

      IO.puts("\n>> application parameters:")
      IO.inspect params
    end

    data = process_json_files(params[:path], params[:anonymize])

    if params[:debug] == true do
      IO.puts("\n>> aggregated (& anonymized?) data:")
      IO.inspect data
    end

    min = p_min(data, params[:tag])
    max = p_max(data, params[:tag])
    avg = p_average(data, params[:tag])
    med = p_median(data, params[:tag])

    IO.puts("\nmin: #{min}, max: #{max}, average: #{avg}, median: #{med}")

  end


  defp print_help() do
    help_text = """
      Process json files with purchase data

        --debug      print debug data [default: false]
        --help       print this help
        --anonymize  anonymize purchase data [default: true]
        --path       path to the json data files [default: "data"]
        --tag        purchase tags to process [default: "airline"]
      """
    IO.puts help_text
  end
end
