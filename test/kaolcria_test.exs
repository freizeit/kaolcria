defmodule KaolcriaTest do
  use ExUnit.Case

  test "merge_airline_purchase_counts(), empty price count list" do
    input = []
    expected = %{}
    assert Kaolcria.merge_airline_purchase_counts(input) == expected
  end


  test "merge_airline_purchase_counts(), single price count list" do
    input = [[101, 1002, 10003]]
    expected = %{101 => 1, 1002 => 1, 10003 => 1}
    assert Kaolcria.merge_airline_purchase_counts(input) == expected
  end


  test "merge_airline_purchase_counts(), multiple/mixed price count lists" do
    input = [[], [101, 1002, 10003], [105], [102], [101, 105]]
    expected = %{101 => 2, 102 => 1, 105 => 2, 1002 => 1, 10003 => 1}
    assert Kaolcria.merge_airline_purchase_counts(input) == expected
  end


  test "anonymize_airline_purchase_counts(), empty price count list" do
    assert Kaolcria.anonymize_airline_purchase_counts(%{}) == %{}
  end

  test "anonymize_airline_purchase_counts(), all counts 6+" do
    input = %{201 => 6, 2002 => 12, 20003 => 17}
    assert Kaolcria.anonymize_airline_purchase_counts(input) == input
  end


  test "anonymize_airline_purchase_counts(), mixed bag of counts" do
    input = %{201 => 6, 2002 => 0, 20003 => 7, 1 => 5, 0 => -1}
    expected = %{201 => 6, 20003 => 7}
    assert Kaolcria.anonymize_airline_purchase_counts(input) == expected
  end
end


defmodule ListJsonFilesTest do
  use ExUnit.Case

  setup context do
    {tpath, 0} = System.cmd("mktemp", ["-d", "/tmp/air.XXXXX.cloak"])
    tpath = String.rstrip(tpath)
    Enum.each(context[:fs], fn f ->
      path = tpath <> "/" <> f
      File.touch!(path)
    end)
    if context[:dirmode] != nil do
      File.chmod!(tpath, context[:dirmode])
    end

    on_exit fn ->
      File.chmod!(tpath, 0o755)
      System.cmd("rm", ["-rf", tpath])
    end

    {:ok, tpath: tpath}
  end


  @tag fs: []
  test "list_json_files(), empty dir", context do
    assert Kaolcria.list_json_files(context[:tpath]) == {:ok, []}
  end


  @tag fs: ["aa.abc", "bb.xxx"]
  test "list_json_files(), no json files", context do
    assert Kaolcria.list_json_files(context[:tpath]) == {:ok, []}
  end


  @tag fs: ["ca.abc", "db.xxx", "ee.json", "ffjson", "gg.json"]
  test "list_json_files(), 2 json files", context do
    expected = {:ok, [context[:tpath] <> "/" <> "ee.json",
                      context[:tpath] <> "/" <> "gg.json"]}
    assert Kaolcria.list_json_files(context[:tpath]) == expected
  end


  @tag dirmode: 0o000
  @tag fs: ["ca.abc", "db.xxx", "ee.json", "ffjson", "gg.json"]
  test "list_json_files(), directory not readable", context do
    expected = {:error, :eacces}
    assert Kaolcria.list_json_files(context[:tpath]) == expected
  end
end


defmodule ExtractAirlinePurchasesTest do
  use ExUnit.Case

  setup context do
    {fpath, 0} = System.cmd("mktemp", ["acl.XXXXX.json"])
    fpath = String.rstrip(fpath)
    write_file(fpath, context[:content])
    if context[:filemode] != nil do
      File.chmod!(fpath, context[:filemode])
    end

    on_exit fn ->
      File.chmod!(fpath, 0o644)
      System.cmd("rm", ["-f", fpath])
    end

    {:ok, fpath: fpath}
  end


  @tag filemode: 0o000
  @tag content: """
    {"purchases":[
      {"type":"hotel","amount":460},
      {"type":"drink","amount":6},
      {"type":"airline","amount":150},
      {"type":"car","amount":928759},
      {"type":"drink","amount":4}
    ]}
    """
  test "extract_airline_purchases(), file not readable", context do
    assert Kaolcria.extract_airline_purchases(context[:fpath]) == {:error, :eacces}
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
    expected = {:ok, [150]}
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
    expected = {:ok, [10000]}
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
    expected = {:ok, []}
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
    expected = {:ok, [102, 1003, 10004]}
    assert Kaolcria.extract_airline_purchases(context[:fpath]) == expected
  end


  defp write_file(path, content) do
    {:ok, file} = File.open path, [:write]
    IO.binwrite file, content
    File.close file
  end
end


defmodule ProcessJsonFilesTest do
  use ExUnit.Case

  setup context do
    {tpath, 0} = System.cmd("mktemp", ["-d", "/tmp/acl.XXXXX.jsond"])
    tpath = String.rstrip(tpath)
    Enum.each(context[:jfs], fn {name, mode, content} ->
      path = tpath <> "/" <> name
      write_file(path, content)
      File.chmod!(path, mode)
    end)
    if context[:dirmode] != nil do
      File.chmod!(tpath, context[:dirmode])
    end

    on_exit fn ->
      File.chmod!(tpath, 0o755)
      System.cmd("rm", ["-rf", tpath])
    end

    {:ok, tpath: tpath}
  end


  @tag dirmode: 0o255
  @tag jfs: [
    {"2.json", 0o400, """
      {"purchases":[
        {"type":"airline","amount":10000},
        {"type":"drink","amount":4}
      ]}
    """},
    {"4.json", 0o400, """
      {"purchases":[
        {"type":"airline","amount":10000},
        {"type":"airline","amount":10000},
        {"type":"drink","amount":4}
      ]}
    """},
    {"5.json", 0o400, """
      {"purchases":[
        {"type":"airline","amount":10000},
        {"type":"drink","amount":4}
      ]}
    """},
    {"6.json", 0o400, """
      {"purchases":[
        {"type":"airline","amount":10000},
        {"type":"airline","amount":10000},
        {"type":"drink","amount":4}
      ]}
    """},
    {"7.json", 0o400, """
      {"purchases":[
        {"type":"airline","amount":10000},
        {"type":"drink","amount":4}
      ]}
    """},
    {"15.json", 0o640, """
      {"purchases":[
        {"type":"airline","amount":10000},
        {"type":"airline","amount":10000},
        {"type":"airline","amount":9000},
        {"type":"airline","amount":9000},
        {"type":"pillow","amount":25}
      ]}
    """},
    {"16.json", 0o644, """
      {"purchases":[]}
    """},
    {"17.json", 0o644, """
      {"purchases":[
        {"type":"airline","amount":9000},
        {"type":"airline","amount":9000},
        {"type":"airline","amount":9000}
      ]}
    """}
    ]
  test "process_json_files(), directory not readable", context do
    assert Kaolcria.process_json_files(context[:tpath]) == %{}
  end


  @tag dirmode: 0o755
  @tag jfs: [
    {"1.json", 0o600, """
      {"purchases":[
        {"type":"hotel","amount":460},
        {"type":"drink","amount":6},
        {"type":"airline","amount":150},
        {"type":"car","amount":928759},
        {"type":"drink","amount":4},
        {"type":"airline","amount":10000}
      ]}
    """},
    {"2.json", 0o600, """
      {"purchases":[
        {"type":"airline","amount":150},
        {"type":"airline","amount":10000}
      ]}
    """},
    {"3.json", 0o600, """
      {"purchases":[
        {"type":"airline","amount":150}
      ]}
    """},
    {"4.json", 0o600, """
      {"purchases":[
        {"type":"airline","amount":150},
        {"type":"drink","amount":4},
        {"type":"airline","amount":10000}
      ]}
    """},
    {"5.json", 0o600, """
      {"purchases":[
        {"type":"airline","amount":9000}
      ]}
    """},
    {"6.json", 0o600, """
      {"purchases":[
        {"type":"airline","amount":10000}
      ]}
    """},
    {"7.json", 0o600, """
      {"purchases":[
        {"type":"airline","amount":9000}
      ]}
    """},
    {"8.json", 0o600, """
      {"purchases":[
        {"type":"airline","amount":10000}
      ]}
    """},
    {"9.json", 0o600, """
      {"purchases":[
        {"type":"airline","amount":9000}
      ]}
    """},
    {"15.json", 0o640, """
      {"purchases":[
        {"type":"airline","amount":10000},
        {"type":"airline","amount":150},
        {"type":"airline","amount":600},
        {"type":"airline","amount":10000},
        {"type":"pillow","amount":25}
      ]}
    """},
    {"16.json", 0o644, """
      {"purchases":[]}
    """},
    {"17.json", 0o644, """
      {"purchases":[
        {"type":"airline","amount":10000},
        {"type":"airline","amount":10000},
        {"type":"airline","amount":150},
        {"type":"airline","amount":9000},
        {"type":"airline","amount":9000}
      ]}
    """}
    ]
  test "process_json_files(), all files readable", context do
    assert Kaolcria.process_json_files(
      context[:tpath]) == %{150 => 6, 10000 => 7}
  end


  @tag dirmode: 0o755
  @tag jfs: [
    {"1.json", 0o200, """
      {"purchases":[
        {"type":"airline","amount":10000},
        {"type":"airline","amount":10000},
        {"type":"hotel","amount":460},
        {"type":"drink","amount":6},
        {"type":"airline","amount":150},
        {"type":"car","amount":928759},
        {"type":"drink","amount":4}
      ]}
    """},
    {"2.json", 0o400, """
      {"purchases":[
        {"type":"airline","amount":10000},
        {"type":"drink","amount":4}
      ]}
    """},
    {"4.json", 0o400, """
      {"purchases":[
        {"type":"airline","amount":10000},
        {"type":"airline","amount":10000},
        {"type":"drink","amount":4}
      ]}
    """},
    {"5.json", 0o400, """
      {"purchases":[
        {"type":"airline","amount":10000},
        {"type":"drink","amount":4}
      ]}
    """},
    {"6.json", 0o400, """
      {"purchases":[
        {"type":"airline","amount":10000},
        {"type":"airline","amount":10000},
        {"type":"drink","amount":4}
      ]}
    """},
    {"7.json", 0o400, """
      {"purchases":[
        {"type":"airline","amount":10000},
        {"type":"drink","amount":4}
      ]}
    """},
    {"15.json", 0o640, """
      {"purchases":[
        {"type":"airline","amount":10000},
        {"type":"airline","amount":10000},
        {"type":"airline","amount":9000},
        {"type":"airline","amount":9000},
        {"type":"pillow","amount":25}
      ]}
    """},
    {"16.json", 0o644, """
      {"purchases":[]}
    """},
    {"17.json", 0o644, """
      {"purchases":[
        {"type":"airline","amount":9000},
        {"type":"airline","amount":9000},
        {"type":"airline","amount":9000}
      ]}
    """}
    ]
  test "process_json_files(), 1.json not readable", context do
    assert Kaolcria.process_json_files(context[:tpath]) == %{10000 => 6}
  end


  @tag dirmode: 0o755
  @tag jfs: [
    {"1.json", 0o200, """
      {"purchases":[
        {"type":"airline","amount":10000},
        {"type":"airline","amount":10000},
        {"type":"hotel","amount":460},
        {"type":"drink","amount":6},
        {"type":"airline","amount":150},
        {"type":"car","amount":928759},
        {"type":"drink","amount":4}
      ]}
    """},
    {"15.json", 0o640, """
      {"purchases":[
        {"type":"airline","amount":10000},
        {"type":"airline","amount":10000},
        {"type":"airline","amount":10000},
        {"type":"airline","amount":10000},
        {"type":"airline","amount":10000},
        {"type":"airline","amount":9000},
        {"type":"airline","amount":9000},
        {"type":"pillow","amount":25}
      ]}
    """},
    {"16.json", 0o644, """
      {"purchases":[]}
    """},
    {"17.json", 0o244, """
      {"purchases":[
        {"type":"airline","amount":9000},
        {"type":"airline","amount":9000},
        {"type":"airline","amount":9000},
        {"type":"airline","amount":9000}
      ]}
    """}
    ]
  test "process_json_files(), 1.json and 17.json not readable", context do
    assert Kaolcria.process_json_files(context[:tpath]) == %{}
  end


  defp write_file(path, content) do
    {:ok, file} = File.open path, [:write]
    IO.binwrite file, content
    File.close file
  end
end
