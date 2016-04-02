defmodule Kaolcria do
  @moduledoc """
  coding challenge solution
  """

  require Integer


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
  """
  def extract_purchases(path, tag \\ "airline") do
    case File.read(path) do
      {:error, _} = err -> err
      {:ok, body} -> {:ok,
        body
        |> Poison.Parser.parse!
        |> Access.get("purchases")
        |> Enum.filter(fn d -> d["type"] == tag end)
        |> Enum.map(fn d -> {d["type"], d["amount"]} end)
        |> Enum.sort}
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
    |> Enum.filter(fn({_, v}) -> v > 0 end)
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
  From the "Programming Elixir" book but receives results in random order.
  """
  def pmap(collection, fun) do
    me = self
    collection
    |> Enum.map(fn (elem) ->
        spawn_link fn -> (send me, { self, fun.(elem) }) end
      end)
    |> Enum.map(fn (_) ->
        receive do { _, result } -> result end
      end)
  end


  @doc """
  Processes, aggregates and anonymizes the data contained in the json files in
  the given directory.
  Returns an aggregated and anonymized map with airline price counts.
  """
  def process_json_files(path, tag \\ "airline", flags \\ %{anonymize: true}) do
    case list_json_files(path) do
      {:ok, files} ->

        ### report
        files
        |> Enum.map(fn path ->
            case extract_purchases(path, tag) do
              {:ok, _} = result -> result
              {:error, ev} -> {:error, ev, path}
            end
          end)
        |> Enum.map(fn
            {:ok, result} -> [{tag, p_average(result)}]
            {:error, err, path} ->
              if flags[:printerrors] do
                IO.puts(:stderr, "Error: #{:file.format_error(err)} :: #{path}")
              end
              [{"error", -1}]
          end)
        ### aggregate
        |> merge_purchases
        ### anonymize
        |> anonymize_purchases(flags[:anonymize])
      {:error, err} ->
        if flags[:printerrors] do
          IO.puts(:stderr, "Error: #{:file.format_error(err)} :: #{path}")
        end
        %{}
    end
  end


  @doc """
  Return the average of a map with aggregated (and anonymized?)
  purchase prices.
  """
  def p_average(pps, ptype \\ "airline")
  def p_average(pps, ptype) when is_list(pps) do
    keys = pps |> Enum.filter(fn({pt, _pv}) -> pt == ptype end)
    sum = keys |> Enum.reduce(0, fn({_pt, pv}, acc) -> pv + acc end)
    case keys do
      [] -> -1
       _ -> sum/Enum.count(keys)
    end
  end
  def p_average(pps, ptype) when pps != %{} do
    p_average(Map.keys(pps), ptype)
  end
  def p_average(_pps, _ptype), do: 0


  @doc """
  Return the median of a map with aggregated (and anonymized?)
  purchase prices.
  """
  def p_median(pps, ptype \\ "airline")
  def p_median(pps, ptype) when is_list(pps) do
    keys = pps
    |> Enum.filter(fn({pt, _pv}) -> pt == ptype end)
    |> Enum.sort
    num_keys = Enum.count(keys)
    if num_keys > 0 do
      if Integer.is_odd(num_keys) do
        # odd number of keys
        Enum.at(keys, div(num_keys, 2)) |> elem(1)
      else
        {_, m1} = Enum.at(keys, div(num_keys, 2) - 1)
        {_, m2} = Enum.at(keys, div(num_keys, 2))
        (m1 + m2)/2
      end
    else
      -1
    end
  end
  def p_median(pps, ptype) when pps != %{} do
    p_median(Map.keys(pps), ptype)
  end
  def p_median(_pps, _ptype), do: 0


  @doc """
  Return the minimum of a map with aggregated (and anonymized?)
  purchase prices.
  """
  def p_min(pps, ptype \\ "airline")
  def p_min(pps, ptype) when is_list(pps) do
    case pps |> Enum.filter(fn({pt, _pv}) -> pt == ptype end) do
          [] -> -1
          ps -> Enum.min(ps) |> elem(1)
    end
  end
  def p_min(pps, ptype) when pps != %{} do
    p_min(Map.keys(pps), ptype)
  end
  def p_min(_pps, _ptype), do: 0


  @doc """
  Return the maximum of a map with aggregated (and anonymized?)
  purchase prices.
  """
  def p_max(pps, ptype \\ "airline")
  def p_max(pps, ptype) when is_list(pps) do
    case pps |> Enum.filter(fn({pt, _pv}) -> pt == ptype end) do
      [] -> -1
      ps -> Enum.max(ps) |> elem(1)
    end
  end
  def p_max(pps, ptype) when pps != %{} do
    p_max(Map.keys(pps), ptype)
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

    flags = %{anonymize: params[:anonymize], printerrors: true}
    data = process_json_files(params[:path], params[:tag], flags)

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


  def print_result(prs) do
    min = p_min(prs)
    max = p_max(prs)
    avg = p_average(prs)
    med = p_median(prs)

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
