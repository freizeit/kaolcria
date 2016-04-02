defmodule KaolcriaTest do
  use ExUnit.Case

  test "p_median(), empty map with airline purchases prices" do
    input = %{}
    expected = 0
    assert Kaolcria.p_median(input) == expected
  end


  test "p_median(), odd number of airline purchases prices" do
    input = %{
      {"airline", 201} => 6, {"airline", 2002} => 12, {"airline", 20003} => 17}
    expected = 2002
    assert Kaolcria.p_median(input) == expected
  end


  test "p_median(), mixed prices, even number of airline records" do
    input = %{
      {"airline", 0} => 11, {"hotel", 1} => 22, {"airline", 2} => 33,
      {"bag", 0} => 11, {"airline", 1} => 22, {"food", 2} => 33,
      {"airline", 3} => 44}
    expected = 1.5
    assert Kaolcria.p_median(input) == expected
  end


  test "p_average(), empty map with airline purchases prices" do
    input = %{}
    expected = 0
    assert Kaolcria.p_average(input) == expected
  end


  test "p_average(), good map with mixed purchases prices" do
    input = %{
      {"airline", 201} => 6, {"beans", 2002} => 12, {"airline", 20003} => 17,
      {"jelly", 201} => 6, {"airline", 2002} => 12, {"toast", 20003} => 17}

    expected = 7402.0
    assert Kaolcria.p_average(input) == expected
  end


  test "p_average(), contrived map with airline purchases prices" do
    input = %{{"airline", 0} => 11, {"bread", 5} => 11, {"airline", 1} => 22}
    expected = 0.5
    assert Kaolcria.p_average(input) == expected
  end


  test "p_min(), empty map with airline purchases prices" do
    input = %{}
    expected = 0
    assert Kaolcria.p_min(input) == expected
  end


  test "p_min(), good map with mixed purchases prices" do
    input = %{
      {"airline", 201} => 6, {"beans", 2002} => 12, {"airline", 20003} => 17,
      {"jelly", 201} => 6, {"airline", 2002} => 12, {"toast", 20003} => 17}

    expected = 201
    assert Kaolcria.p_min(input) == expected
  end


  test "p_min(), contrived map with airline purchases prices" do
    input = %{{"airline", 0.1} => 11, {"bread", 5} => 11, {"airline", 1} => 22}
    expected = 0.1
    assert Kaolcria.p_min(input) == expected
  end


  test "p_max(), empty map with airline purchases prices" do
    input = %{}
    expected = 0
    assert Kaolcria.p_max(input) == expected
  end


  test "p_max(), good map with mixed purchases prices" do
    input = %{
      {"airline", 201} => 6, {"beans", 2002} => 12, {"airline", 20003} => 17,
      {"jelly", 201} => 6, {"airline", 2002} => 12, {"toast", 20003} => 17}

    expected = 20003
    assert Kaolcria.p_max(input) == expected
  end


  test "p_max(), contrived map with airline purchases prices" do
    input = %{{"airline", 0.2} => 11, {"bread", 5} => 1, {"airline", 0.1} => 9}
    expected = 0.2
    assert Kaolcria.p_max(input) == expected
  end


  test "anonymize_purchases(), empty price count list" do
    assert Kaolcria.anonymize_purchases(%{}) == %{}
  end

  test "anonymize_purchases(), all counts 6+" do
    input = %{
      {"airline", 150} => 6,
      {"car", 928759} => 7,
      {"drink", 4} => 8,
      {"drink", 6} => 9,
      {"hotel", 460} => 10}
    assert Kaolcria.anonymize_purchases(input) == input
  end


  test "anonymize_purchases(), with `anonymize` flag off" do
    input = %{
      {"airline", 150} => 1,
      {"car", 928759} => 2,
      {"drink", 4} => 3,
      {"drink", 6} => 4,
      {"hotel", 460} => 5}
    assert Kaolcria.anonymize_purchases(input, false) == input
  end


  test "anonymize_purchases(), mixed bag of counts" do
    input = %{
      {"airline", 151} => 7,
      {"airline", 1004} => 2,
      {"airline", 10005} => 1,
      {"car", 928751} => 9,
      {"drink", 5} => 3,
      {"drink", 7} => 1,
      {"hotel", 461} => 10,
      {"pillow", 26} => 2}
    expected = %{
      {"airline", 151} => 7,
      {"car", 928751} => 9,
      {"hotel", 461} => 10}
    assert Kaolcria.anonymize_purchases(input) == expected
  end
end


defmodule MergePurchaseCountsTest do
  use ExUnit.Case

  test "merge_purchases(), empty price count list" do
    input = []
    expected = %{}
    assert Kaolcria.merge_purchases(input) == expected
  end


  test "merge_purchases(), single price count list" do
    input = [[
      {"airline", 150},
      {"car", 928759},
      {"drink", 4},
      {"drink", 6},
      {"hotel", 460}]]
    expected = %{
      {"airline", 150} => 1,
      {"car", 928759} => 1,
      {"drink", 4} => 1,
      {"drink", 6} => 1,
      {"hotel", 460} => 1}
    assert Kaolcria.merge_purchases(input) == expected
  end


  test "merge_purchases(), multiple/mixed price count lists" do
    input = [
      [],
      [{"airline", 151},
       {"car", 928751},
       {"drink", 5},
       {"drink", 7},
       {"hotel", 461}],
      [{"airline", 151},
       {"drink", 5},
       {"airline", 1004},
       {"airline", 10005},
       {"pillow", 26}],
      [{"airline", 151},
       {"drink", 5},
       {"airline", 1004},
       {"pillow", 26}]]
    expected = %{
      {"airline", 151} => 3,
      {"airline", 1004} => 2,
      {"airline", 10005} => 1,
      {"car", 928751} => 1,
      {"drink", 5} => 3,
      {"drink", 7} => 1,
      {"hotel", 461} => 1,
      {"pillow", 26} => 2}

    assert Kaolcria.merge_purchases(input) == expected
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
  test "process_json_files(), directory not readable", context do
    flags = %{anonymize: true, printerrors: false}
    assert Kaolcria.process_json_files(
      context[:tpath], "airline", flags) == %{}
  end


  @tag dirmode: 0o755
  @tag jfs: [
    {"1.json", 0o600, """
      {"purchases":[
        {"type":"hotel","amount":460},
        {"type":"drink","amount":6},
        {"type":"airline","amount":2000},
        {"type":"car","amount":928759},
        {"type":"drink","amount":4},
        {"type":"airline","amount":10000}
      ]}
    """},
    {"2.json", 0o600, """
      {"purchases":[
        {"type":"airline","amount":6000}
      ]}
    """},
    {"3.json", 0o600, """
      {"purchases":[
        {"type":"drink","amount":4},
        {"type":"airline","amount":150}
      ]}
    """},
    {"4.json", 0o600, """
      {"purchases":[
        {"type":"airline","amount":3000},
        {"type":"drink","amount":4},
        {"type":"airline","amount":9000}
      ]}
    """},
    {"5.json", 0o600, """
      {"purchases":[
        {"type":"airline","amount":6000}
      ]}
    """},
    {"6.json", 0o600, """
      {"purchases":[
        {"type":"drink","amount":4},
        {"type":"airline","amount":10000}
      ]}
    """},
    {"7.json", 0o600, """
      {"purchases":[
        {"type":"drink","amount":4},
        {"type":"airline","amount":6000}
      ]}
    """},
    {"8.json", 0o600, """
      {"purchases":[
        {"type":"drink","amount":4},
        {"type":"airline","amount":6000}
      ]}
    """},
    {"9.json", 0o600, """
      {"purchases":[
        {"type":"drink","amount":4},
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
        {"type":"drink","amount":4},
        {"type":"airline","amount":10000},
        {"type":"airline","amount":10000},
        {"type":"airline","amount":150},
        {"type":"airline","amount":9000},
        {"type":"airline","amount":9000}
      ]}
    """}
    ]
  test "process_json_files(), all files readable", context do
    expected = %{{"airline", 6.0e3} => 6}
    flags = %{anonymize: true, printerrors: false}
    assert Kaolcria.process_json_files(
      context[:tpath], "airline", flags) == expected
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
    {"8.json", 0o400, """
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
    flags = %{anonymize: true, printerrors: false}
    assert Kaolcria.process_json_files(
      context[:tpath], "airline", flags) == %{{"airline", 1.0e4} => 6}
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
    flags = %{anonymize: true, printerrors: false}
    assert Kaolcria.process_json_files(context[:tpath], "airline", flags) == %{}
  end


  @tag dirmode: 0o755
  @tag jfs: [
    {"1.json", 0o600, """
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
  test "process_json_files(), `anonymize` flag off", context do
    expected = %{
      {"airline", 6716.666666666667} => 1, {"airline", 9714.285714285714} => 1}
    flags = %{anonymize: false, printerrors: false}
    assert Kaolcria.process_json_files(context[:tpath], "airline", flags) == expected
  end


  defp write_file(path, content) do
    {:ok, file} = File.open path, [:write]
    IO.binwrite file, content
    File.close file
  end
end


defmodule ExtractPurchasesTest do
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
  test "extract_purchases(), file not readable", context do
    assert Kaolcria.extract_purchases(context[:fpath]) == {:error, :eacces}
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
  test "extract_purchases(), single entry", context do
    expected = {:ok, [{"airline", 150}]}
    assert Kaolcria.extract_purchases(context[:fpath]) == expected
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
  test "extract_purchases(), 5x10k", context do
    expected = {:ok, [
      {"airline", 10000}, {"airline", 10000}, {"airline", 10000},
      {"airline", 10000}, {"airline", 10000}]}
    assert Kaolcria.extract_purchases(context[:fpath]) == expected
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
  test "extract_purchases(), no airline purchases", context do
    expected = {:ok, [{"drink", 4}, {"drink", 6}]}
    assert Kaolcria.extract_purchases(context[:fpath], "drink") == expected
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
  test "extract_purchases(), mixed bag", context do
    expected = {:ok, [
      {"airline", 102}, {"airline", 1003}, {"airline", 1003},
      {"airline", 10004}, {"airline", 10004}]}
    assert Kaolcria.extract_purchases(context[:fpath]) == expected
  end


  defp write_file(path, content) do
    {:ok, file} = File.open path, [:write]
    IO.binwrite file, content
    File.close file
  end
end
