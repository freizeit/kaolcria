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
  Returns all the *.json files in the given `path`.
  """
  def list_json_files(path) do
    File.ls!(path)
    |> Enum.filter(fn f -> Regex.match?(~r/\.json$/, f) end)
    |> Enum.sort
  end
end
