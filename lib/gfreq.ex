defmodule Gfreq do
  @moduledoc """
  Mean, Median etc. from Grouped Frequencies
  See http://www.mathsisfun.com/data/frequency-grouped-mean-median-mode.html
  """


  require Integer


  @doc """
  %{140 => 0, 287 => 141, 462 => 288, 667 => 463, 904 => 668, 1177 => 905,
    1487 => 1178, 1837 => 1488, 2229 => 1838, 2666 => 2230, 3150 => 2667,
    3683 => 3151, 4268 => 3684, 4907 => 4269, 5602 => 4908, 6357 => 5603,
    7173 => 6358, 8053 => 7174, 8999 => 8054, 10014 => 9000}
  """
  @intervals
    8..70
    |> Enum.map(fn x -> (div((4*x*x*x + 7*x*x), 10) - 329) end)
    |> Enum.drop(2)
    |> Enum.take(20)
    |> Enum.map_reduce(0, fn(x, acc) -> {{x-1, acc}, x} end)
    |> elem(0)
    |> Enum.into(%{})


  @doc """
  [140, 287, 462, 667, 904, 1177, 1487, 1837, 2229, 2666, 3150, 3683, 4268,
   4907, 5602, 6357, 7173, 8053, 8999, 10014]
  """
  @upper_bounds @intervals |> Map.keys |> Enum.sort


  def interval(price) when price > 0 do
    case Enum.find(@upper_bounds, fn x -> price <= x end) do
      nil -> nil
      bound -> {@intervals[bound], bound}
  end
  def interval(_price), do: nil


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
