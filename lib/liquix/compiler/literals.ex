defmodule Liquix.Compiler.Literals do
  import NimbleParsec
  import Liquix.Compiler.Common

  @doc ~S"""
  `'me is a \' string'` and `"me \" too"`
  """
  def string_literal(), do: choice([double_string_literal(), single_string_literal()])

  # TODO: signed
  def num_literal(), do: choice([float(), int()])

  @doc """
  `(0..3)`, `(from..to)`
  """
  def range_literal(),
    do:
      ignore(string("("))
      |> unwrap_and_tag(choice([int(), parsec(:placeholder)]), :from)
      |> ignore(string(".."))
      |> unwrap_and_tag(choice([int(), parsec(:placeholder)]), :to)
      |> ignore(string(")"))
      |> reduce({__MODULE__, :range_literal, []})

  @doc """
  `true`, `false` and `nil`
  """
  def atom_literal(),
    do:
      choice([
        string("true") |> replace(true),
        string("false") |> replace(false),
        string("nil") |> replace(nil)
      ])
      |> lookahead_not(word())
      |> reduce({List, :first, []})

  defp double_string_literal(),
    do:
      ignore(ascii_char([?"]))
      |> repeat(
        lookahead_not(ascii_char([?"]))
        |> choice([
          string(~S(\")) |> replace(?"),
          utf8_char([])
        ])
      )
      |> ignore(ascii_char([?"]))
      |> reduce({List, :to_string, []})

  defp single_string_literal(),
    do:
      ignore(ascii_char([?']))
      |> repeat(
        lookahead_not(ascii_char([?']))
        |> choice([
          string(~S(\')) |> replace(?'),
          utf8_char([])
        ])
      )
      |> ignore(ascii_char([?']))
      |> reduce({List, :to_string, []})

  defp int(), do: integer(min: 1)

  defp float(),
    do:
      integer(min: 1)
      |> concat(string("."))
      |> integer(min: 1)
      # TODO: oh boy
      |> map({Kernel, :to_string, []})
      |> reduce({Enum, :join, []})
      |> map({String, :to_float, []})
      |> reduce({List, :first, []})

  def range_literal(from: from, to: to) do
    quote do
      from = Liquix.Runtime.range_limit(unquote(from))
      to = Liquix.Runtime.range_limit(unquote(to))
      from..to |> Enum.to_list()
    end
  end
end
