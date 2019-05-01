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

  operator =
    choice([string("=="), string("!="), string(">"), string("<"), string(">="), string("<=")])

  bool_operator = choice([string("and"), string("or")])

  if_object =
    object_path
    |> reduce({__MODULE__, :object_present?, []})

  defparsec(
    :if_clause,
    if_object
    |> optional(
      ignore(whitespace_or_nothing)
      |> concat(bool_operator)
      |> ignore(whitespace_or_nothing)
      |> parsec(:if_clause)
    )
    |> tag(:if_clause)
    |> reduce({__MODULE__, :c_if_clause, []})
  )

  if_tag =
    open_tag
    |> ignore(string("if "))
    |> parsec(:if_clause)
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

  def c_if_clause(if_clause: [a_clause, "and", b_clause]) do
    quote do
      Kernel.and(unquote(a_clause), unquote(c_if_clause(b_clause)))
    end
  end

  def c_if_clause(if_clause: [a_clause, "or", b_clause]) do
    quote do
      Kernel.or(unquote(a_clause), unquote(c_if_clause(b_clause)))
    end
  end

  def c_if_clause(if_clause: [single_clause]), do: single_clause
  def c_if_clause(single_clause), do: single_clause

  def if_tag(if: [ast | [body: body]]) do
    quote do
      if unquote(ast), do: unquote(body), else: ""
    end
  end

  def object_present?(path) do
    quote do
      Liquix.Runtime.safe_present?(data, unquote(path))
    end
  end

  def object_lookup(path) do
    quote do
      case Liquix.Runtime.safe_lookup(data, unquote(path)) do
        {:ok, stuff} -> to_string(stuff)
        :nope -> ""
      end
    end
  end

  defmodule Runtime do
    def safe_present?(data, path) do
      case safe_lookup(data, path) do
        {:ok, val} -> !!val
        :nope -> false
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
end
