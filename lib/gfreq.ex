defmodule Gfreq do
  @moduledoc """
  Mean, Median etc. from Grouped Frequencies
  See http://www.mathsisfun.com/data/frequency-grouped-mean-median-mode.html
  """

  require Integer


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
end
