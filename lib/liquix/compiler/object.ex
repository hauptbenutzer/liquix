defmodule Liquix.Compiler.Object do
  import NimbleParsec
  import Liquix.Compiler.Common

  defp open_object_tag(), do: ignore(string("{{") |> concat(whitespace_or_nothing()))

  defp close_object_tag(),
    do:
      ignore(
        whitespace_or_nothing()
        |> choice([
          string("}}"),
          string("-}}") |> concat(whitespace())
        ])
      )

  def object(),
    do:
      parsec(:object_path)
      |> reduce({__MODULE__, :c_object, []})

  @doc """
  `{{ some.object['path'] | filter: param1, param2 }}`
  """
  def object_tag(),
    do:
      open_object_tag()
      |> parsec(:filterable_placeholder)
      |> concat(close_object_tag())
      |> reduce({__MODULE__, :c_object_tag, []})

  def object_path(),
    do:
      identifier()
      |> optional(
        times(
          ignore(string("["))
          |> parsec(:placeholder)
          |> ignore(string("]")),
          min: 1
        )
      )
      |> optional(
        ignore(string("."))
        |> parsec(:object_path)
      )

  def c_object_tag([value]) do
    quote do
      Kernel.to_string(unquote(value))
    end
  end

  def c_object(path) do
    quote do
      case Liquix.Runtime.safe_lookup(data, unquote(path)) do
        {:ok, stuff} -> stuff
        :nope -> nil
      end
    end
  end
end
