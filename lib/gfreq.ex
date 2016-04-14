defmodule Gfreq do
  @moduledoc """
  Mean, Median etc. from Grouped Frequencies
  See http://www.mathsisfun.com/data/frequency-grouped-mean-median-mode.html
  """


  require Integer


  # %{0 => 140, 141 => 287, 288 => 462, 463 => 667, 668 => 904, 905 => 1177,
  #   1178 => 1487, 1488 => 1837, 1838 => 2229, 2230 => 2666, 2667 => 3150,
  #   3151 => 3683, 3684 => 4268, 4269 => 4907, 4908 => 5602, 5603 => 6357,
  #   6358 => 7173, 7174 => 8053, 8054 => 8999, 9000 => 10014}
  @intervals 8..29
    |> Enum.map(fn x -> (div((4*x*x*x + 7*x*x), 10) - 329) end)
    |> Enum.drop(2)
    |> Enum.map_reduce(0, fn(x, acc) -> {{acc, x-1}, x} end)
    |> elem(0)
    |> Enum.into(%{})


  # [9000, 8054, 7174, 6358, 5603, 4908, 4269, 3684, 3151, 2667, 2230, 1838,
  #  1488, 1178, 905, 668, 463, 288, 141, 0]
  @lower_bounds @intervals |> Map.keys |> Enum.sort |> Enum.reverse

  # 10014
  @max_price @intervals[List.first(@lower_bounds)]

  def interval(price) when price >= 0 and price <= @max_price do
    case Enum.find(@lower_bounds, fn x -> price >= x end) do
      nil -> nil
      bound -> {bound, @intervals[bound]}
    end
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
