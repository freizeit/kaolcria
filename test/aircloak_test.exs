defmodule AircloakTest do
  use ExUnit.Case
  doctest Aircloak

  test "the truth" do
    assert 1 + 1 == 2
  end
end


defmodule ListJsonFilesTest do
  use ExUnit.Case
  doctest Aircloak

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
    assert Aircloak.list_json_files(context[:tpath]) == []
  end


  @tag fs: ["aa.abc", "bb.xxx"]
  test "list_json_files(), no json files", context do
    assert Aircloak.list_json_files(context[:tpath]) == []
  end


  @tag fs: ["ca.abc", "db.xxx", "ee.json", "ffjson", "gg.json"]
  test "list_json_files(), 2 json files", context do
    assert Aircloak.list_json_files(context[:tpath]) == ["ee.json", "gg.json"]
  end


end
