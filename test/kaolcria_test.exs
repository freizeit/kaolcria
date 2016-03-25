defmodule KaolcriaTest do
  use ExUnit.Case
  doctest Kaolcria

  test "get_airline_purchase_counts(), empty prices list" do
    assert Kaolcria.get_airline_purchase_counts([]) == %{}
  end


  test "get_airline_purchase_counts(), only one kind of price in list" do
    assert Kaolcria.get_airline_purchase_counts([101, 101, 101]) == %{101 => 3}
  end


  test "get_airline_purchase_counts(), mixed prices in list" do
    assert Kaolcria.get_airline_purchase_counts(
      [101, 101, 101, 1002, 1002, 10003]) == %{101 => 3, 1002 =>2, 10003 => 1}
  end
end


defmodule ListJsonFilesTest do
  use ExUnit.Case
  doctest Kaolcria

  setup context do
    {tpath, 0} = System.cmd("mktemp", ["-d", "/tmp/air.XXXXX.cloak"])
    tpath = String.rstrip(tpath)
    Enum.each(context[:fs], fn f ->
      path = tpath <> "/" <> f
      File.touch!(path)
    end)

    on_exit fn ->
      System.cmd("rm", ["-rf", tpath])
    end

    {:ok, tpath: tpath}
  end


  @tag fs: []
  test "list_json_files(), empty dir", context do
    assert Kaolcria.list_json_files(context[:tpath]) == []
  end


  @tag fs: ["aa.abc", "bb.xxx"]
  test "list_json_files(), no json files", context do
    assert Kaolcria.list_json_files(context[:tpath]) == []
  end


  @tag fs: ["ca.abc", "db.xxx", "ee.json", "ffjson", "gg.json"]
  test "list_json_files(), 2 json files", context do
    expected = [
      context[:tpath] <> "/" <> "ee.json", context[:tpath] <> "/" <> "gg.json"]
    assert Kaolcria.list_json_files(context[:tpath]) == expected
  end
end


defmodule ExtractAirlinePurchasesTest do
  use ExUnit.Case


  setup context do
    {fpath, 0} = System.cmd("mktemp", ["acl.XXXXX.json"])
    fpath = String.rstrip(fpath)
    write_file(fpath, context[:content])

    on_exit fn ->
      System.cmd("rm", ["-f", fpath])
    end

    {:ok, fpath: fpath}
  end


  @tag content: """
    {"purchases":[
      {"type":"hotel","amount":460},
      {"type":"drink","amount":6},
      {"type":"airline","amount":150},
      {"type":"car","amount":928759},
      {"type":"drink","amount":4}
    ]}
    """
  test "extract_airline_purchases(), single entry", context do
    expected = [150]
    assert Kaolcria.extract_airline_purchases(context[:fpath]) == expected
  end


  @tag content: """
    {"purchases":[
      {"type":"airline","amount":10000},
      {"type":"airline","amount":10000},
      {"type":"airline","amount":10000},
      {"type":"airline","amount":10000},
      {"type":"airline","amount":10000},
      {"type":"pillow","amount":25}
    ]}
    """
  test "extract_airline_purchases(), 5x10k", context do
    expected = [10000, 10000, 10000, 10000, 10000]
    assert Kaolcria.extract_airline_purchases(context[:fpath]) == expected
  end


  @tag content: """
    {"purchases":[
      {"type":"hotel","amount":460},
      {"type":"drink","amount":6},
      {"type":"phoneline","amount":150},
      {"type":"car","amount":928759},
      {"type":"drink","amount":4}
    ]}
    """
  test "extract_airline_purchases(), no airline purchases", context do
    expected = []
    assert Kaolcria.extract_airline_purchases(context[:fpath]) == expected
  end


  @tag content: """
    {"purchases":[
      {"type":"airline","amount":10004},
      {"type":"airline","amount":1003},
      {"type":"airline","amount":102},
      {"type":"airline","amount":1003},
      {"type":"airline","amount":10004},
      {"type":"pillow","amount":25}
    ]}
    """
  test "extract_airline_purchases(), mixed bag", context do
    expected = [102, 1003, 1003, 10004, 10004]
    assert Kaolcria.extract_airline_purchases(context[:fpath]) == expected
  end


  defp write_file(path, content) do
    {:ok, file} = File.open path, [:write]
    IO.binwrite file, content
    File.close file
  end
end
