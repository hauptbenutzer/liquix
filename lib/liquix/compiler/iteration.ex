defmodule Liquix.Compiler.Iteration do
  import NimbleParsec
  import Liquix.Compiler.Common

  def for_tag(),
    do:
      open_tag()
      |> ignore(string("for"))
      |> ignore(whitespace())
      |> unwrap_and_tag(identifier(), :var_name)
      |> ignore(whitespace())
      |> ignore(string("in"))
      |> ignore(whitespace())
      |> unwrap_and_tag(parsec(:placeholder), :var_val)
      |> concat(close_tag())
      |> tag(parsec(:markup), :body)
      |> ignore(open_tag() |> concat(string("endfor")) |> concat(close_tag()))
      |> reduce({__MODULE__, :for_tag, []})

  def for_tag(var_name: var_name, var_val: var_val, body: body) do
    quote do
      case unquote(var_val) do
        list when is_list(list) ->
          for {forloop, item} <- Liquix.Runtime.forloop(list) do
            data = data |> Map.put("forloop", forloop) |> Map.put(unquote(var_name), item)
            unquote(body)
          end

        _ ->
          ""
      end
    end
  end
end
