defmodule GfreqTest do
  use ExUnit.Case


  test "interval(), price < 0" do
    assert Gfreq.interval(-1) == nil
  end


  test "interval(), price somewhere in the middle" do
    assert Gfreq.interval(4000) == {3684, 4268}
  end


  test "interval(), price at lower bound" do
    assert Gfreq.interval(0) == {0, 140}
  end


  test "interval(), price in last interval" do
    assert Gfreq.interval(9000) == {9000, 10014}
  end


  test "interval(), price at upper bound" do
    assert Gfreq.interval(10014) == {9000, 10014}
  end


  test "interval(), price out of bounds" do
    assert Gfreq.interval(10015) == nil
  end


  test "p_median(), empty map with airline purchases prices" do
    input = %{}
    expected = 0
    assert Gfreq.p_median(input) == expected
  end


  test "p_median(), odd number of airline purchases prices" do
    input = %{
      {"airline", 201} => 6, {"airline", 2002} => 12, {"airline", 20003} => 17}
    expected = 2002
    assert Gfreq.p_median(input) == expected
  end


  test "p_median(), mixed prices, even number of airline records" do
    input = %{
      {"airline", 0} => 11, {"hotel", 1} => 22, {"airline", 2} => 33,
      {"bag", 0} => 11, {"airline", 1} => 22, {"food", 2} => 33,
      {"airline", 3} => 44}
    expected = 1.5
    assert Gfreq.p_median(input) == expected
  end


  test "p_average(), empty map with airline purchases prices" do
    input = %{}
    expected = 0
    assert Gfreq.p_average(input) == expected
  end


  test "p_average(), good map with mixed purchases prices" do
    input = %{
      {"airline", 201} => 6, {"beans", 2002} => 12, {"airline", 20003} => 17,
      {"jelly", 201} => 6, {"airline", 2002} => 12, {"toast", 20003} => 17}

    expected = 7402.0
    assert Gfreq.p_average(input) == expected
  end


  test "p_average(), contrived map with airline purchases prices" do
    input = %{{"airline", 0} => 11, {"bread", 5} => 11, {"airline", 1} => 22}
    expected = 0.5
    assert Gfreq.p_average(input) == expected
  end


  test "p_min(), empty map with airline purchases prices" do
    input = %{}
    expected = 0
    assert Gfreq.p_min(input) == expected
  end


  test "p_min(), good map with mixed purchases prices" do
    input = %{
      {"airline", 201} => 6, {"beans", 2002} => 12, {"airline", 20003} => 17,
      {"jelly", 201} => 6, {"airline", 2002} => 12, {"toast", 20003} => 17}

    expected = 201
    assert Gfreq.p_min(input) == expected
  end


  test "p_min(), contrived map with airline purchases prices" do
    input = %{{"airline", 0.1} => 11, {"bread", 5} => 11, {"airline", 1} => 22}
    expected = 0.1
    assert Gfreq.p_min(input) == expected
  end


  test "p_max(), empty map with airline purchases prices" do
    input = %{}
    expected = 0
    assert Gfreq.p_max(input) == expected
  end


  test "p_max(), good map with mixed purchases prices" do
    input = %{
      {"airline", 201} => 6, {"beans", 2002} => 12, {"airline", 20003} => 17,
      {"jelly", 201} => 6, {"airline", 2002} => 12, {"toast", 20003} => 17}

    expected = 20003
    assert Gfreq.p_max(input) == expected
  end


  test "p_max(), contrived map with airline purchases prices" do
    input = %{{"airline", 0.2} => 11, {"bread", 5} => 1, {"airline", 0.1} => 9}
    expected = 0.2
    assert Gfreq.p_max(input) == expected
  end
end
