defmodule Liquix.Compiler.Common do
  import NimbleParsec

  def word(), do: ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?-], min: 1)
  def whitespace(), do: times(choice([string(" "), string("\t"), string("\n"), string("\r")]), min: 1)
  def whitespace_or_nothing(), do: repeat(whitespace())

  def open_tag(), do: ignore(string("{%") |> concat(whitespace_or_nothing()))
  def close_tag(), do: ignore(whitespace_or_nothing() |> string("%}"))

  def identifier(),
    do:
      ascii_string([?a..?z, ?A..?Z, ?_], 1)
      |> repeat(word())
      |> optional(ascii_string([??], 1))
      |> reduce({Enum, :join, []})
end
