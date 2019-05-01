defmodule Liquix do
  import NimbleParsec

  word = ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?-], min: 1)
  whitespace_or_nothing = repeat(string(" "))

  identifier =
    ascii_string([?a..?z, ?A..?Z, ?_], 1)
    |> repeat(word)
    |> optional(ascii_string([??], 1))
    |> reduce({Enum, :join, []})

  object_path = identifier |> repeat(ignore(string(".")) |> concat(identifier))

  open_object = ignore(string("{{") |> concat(whitespace_or_nothing))
  close_object = ignore(whitespace_or_nothing |> string("}}"))

  object =
    open_object
    |> concat(object_path)
    |> concat(close_object)
    |> reduce({__MODULE__, :object_lookup, []})

  open_tag = ignore(string("{%") |> concat(whitespace_or_nothing))
  close_tag = ignore(whitespace_or_nothing |> string("%}"))

  if_clause =
    object_path |> reduce({__MODULE__, :object_present?, []}) |> unwrap_and_tag(:if_clause)

  if_tag =
    open_tag
    |> ignore(string("if "))
    |> concat(if_clause)
    |> concat(close_tag)
    |> tag(parsec(:markup), :body)
    |> ignore(open_tag |> concat(string("endif")) |> concat(close_tag))
    |> tag(:if)
    |> reduce({__MODULE__, :if_tag, []})

  liquid = choice([object, if_tag])

  garbage =
    times(
      lookahead_not(choice([string("{{"), string("{%")]))
      |> utf8_string([], 1),
      min: 1
    )

  defparsec(:markup, repeat(choice([liquid, garbage])))

  defparsec(:parse, parsec(:markup))

  defmacro compile_from_string(fun_name, template) do
    quote bind_quoted: binding() do
      body = Liquix.compile(template)

      def unquote(fun_name)(unquote({:data, [], nil})), do: IO.iodata_to_binary(unquote(body))
    end
  end

  def compile(template) do
    {:ok, ast, _, _, _, _} = parse(template)

    Macro.postwalk(ast, fn
      {x, y, nil} -> {x, y, nil}
      {x, y, __MODULE__} -> {x, y, nil}
      expr -> expr
    end)
  end

  def if_tag(if: [{:if_clause, ast} | [body: body]]) do
    quote do
      if unquote(ast), do: unquote(body), else: ""
    end
  end

  def object_present?(path) do
    quote do
      unquote(__MODULE__).safe_present?(data, unquote(path))
    end
  end

  def safe_present?(data, path) do
    case safe_lookup(data, path) do
      {:ok, val} -> !!val
      :nope -> false
    end
  end

  def object_lookup(path) do
    quote do
      case unquote(__MODULE__).safe_lookup(data, unquote(path)) do
        {:ok, stuff} -> to_string(stuff)
        :nope -> ""
      end
    end
  end

  def safe_lookup(data, []), do: {:ok, data}

  def safe_lookup(data, [key | rest]) do
    key = String.to_atom(key)

    case data do
      %{^key => val} -> safe_lookup(val, rest)
      _ -> :nope
    end
  end
end
