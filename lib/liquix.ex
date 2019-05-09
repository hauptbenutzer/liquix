defmodule Liquix do
  import NimbleParsec

  word = ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_, ?-], min: 1)
  whitespace = times(choice([string(" "), string("\t"), string("\n"), string("\r")]), min: 1)
  whitespace_or_nothing = repeat(whitespace)

  identifier =
    ascii_string([?a..?z, ?A..?Z, ?_], 1)
    |> repeat(word)
    |> optional(ascii_string([??], 1))
    |> reduce({Enum, :join, []})

  object_path = identifier |> repeat(ignore(string(".")) |> concat(identifier))

  open_object_tag = ignore(string("{{") |> concat(whitespace_or_nothing))
  close_object_tag = ignore(whitespace_or_nothing |> string("}}"))

  object =
    object_path
    |> reduce({__MODULE__, :object, []})

  object_tag =
    open_object_tag
    |> parsec(:placeholder)
    |> concat(close_object_tag)
    |> reduce({__MODULE__, :object_tag, []})

  open_tag = ignore(string("{%") |> concat(whitespace_or_nothing))
  close_tag = ignore(whitespace_or_nothing |> string("%}"))

  binary_operator =
    choice([
      string("contains"),
      string("=="),
      string("!="),
      string(">="),
      string("<="),
      string(">"),
      string("<")
    ])

  bool_operator = choice([string("and"), string("or")])

  double_string_literal =
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

  single_string_literal =
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

  string_literal = choice([double_string_literal, single_string_literal])
  int = integer(min: 1)

  float =
    integer(min: 1)
    |> concat(string("."))
    |> integer(min: 1)
    # TODO: oh boy
    |> map({Kernel, :to_string, []})
    |> reduce({Enum, :join, []})
    |> map({String, :to_float, []})
    |> reduce({List, :first, []})

  num_literal = choice([float, int])

  bool_literal =
    choice([
      string("true") |> replace(true),
      string("false") |> replace(false),
      string("nil") |> replace(nil)
    ])
    |> lookahead_not(word)
    |> reduce({List, :first, []})

  literal = choice([string_literal, num_literal, bool_literal])

  defparsec(:placeholder, choice([literal, object]))

  if_binary =
    parsec(:placeholder)
    |> ignore(whitespace)
    |> concat(binary_operator)
    |> ignore(whitespace)
    |> parsec(:placeholder)
    |> reduce({__MODULE__, :if_binary, []})

  if_placeholder =
    parsec(:placeholder)
    |> reduce({__MODULE__, :placeholder_present?, []})

  defparsec(
    :if_clause,
    choice([if_binary, if_placeholder])
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
    |> optional(
      times(
        open_tag
        |> ignore(string("elsif "))
        |> parsec(:if_clause)
        |> concat(close_tag)
        |> tag(parsec(:markup), :body)
        |> tag(:elsif),
        min: 1
      )
    )
    |> concat(
      optional(
        open_tag
        |> ignore(string("else"))
        |> concat(close_tag)
        |> tag(parsec(:markup), :body)
        |> tag(:else)
      )
    )
    |> ignore(open_tag |> concat(string("endif")) |> concat(close_tag))
    |> tag(:if)
    |> reduce({__MODULE__, :if_tag, []})

  case_tag =
    open_tag
    |> ignore(string("case "))
    |> unwrap_and_tag(parsec(:placeholder), :placeholder)
    |> concat(close_tag)
    |> ignore(whitespace_or_nothing)
    |> times(
      open_tag
      |> ignore(string("when "))
      |> unwrap_and_tag(literal, :literal)
      |> concat(close_tag)
      |> tag(parsec(:markup), :body)
      |> tag(:case),
      min: 1
    )
    |> concat(
      optional(
        open_tag
        |> ignore(string("else"))
        |> concat(close_tag)
        |> tag(parsec(:markup), :body)
        |> tag(:else)
      )
    )
    |> ignore(open_tag |> concat(string("endcase")) |> concat(close_tag))
    |> tag(:case)
    |> reduce({__MODULE__, :case_tag, []})

  defparsec(:test, if_tag)

  liquid = choice([object_tag, if_tag, case_tag])

  garbage =
    times(
      lookahead_not(choice([string("{{"), string("{%")]))
      |> utf8_string([], 1),
      min: 1
    )
    |> reduce({Enum, :join, []})

  defparsec(:markup, repeat(choice([liquid, garbage])))

  defparsec(:parse, parsec(:markup))

  defmacro compile_from_string(fun_name, template) do
    quote bind_quoted: binding() do
      body = Liquix.compile(template)
      IO.puts(inspect(fun_name))
      body |> Macro.to_string() |> Code.format_string!() |> IO.puts()

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

  def case_tag(case: [{:placeholder, placeholder} | clauses]) do
    case_clauses =
      Enum.flat_map(clauses, fn
        {:case, [literal: literal, body: body]} ->
          quote do
            unquote(literal) -> unquote(body)
          end

        {:else, [body: body]} ->
          quote do
            _ -> unquote(body)
          end
      end)

    empty_else =
      quote do
        _ -> ""
      end

    case_clauses = if Keyword.has_key?(clauses, :else), do: case_clauses, else: Enum.concat(case_clauses, empty_else)

    quote do
      case unquote(placeholder) do
        unquote(case_clauses)
      end
    end
  end

  def if_binary([left, "contains", right]) do
    quote do
      String.contains?(to_string(unquote(left)), to_string(unquote(right)))
    end
  end

  def if_binary([left, op, right]) do
    quote do
      Kernel.unquote(String.to_atom(op))(unquote(left), unquote(right))
    end
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

  def if_tag(if: [ast | [body: body, else: [body: else_body]]]) do
    quote do
      if unquote(ast), do: unquote(body), else: unquote(else_body)
    end
  end

  def if_tag(if: [ast, {:body, body} | clauses]) do
    cond_clauses =
      Enum.flat_map(clauses, fn
        {:elsif, [ast, {:body, body}]} ->
          quote do
            unquote(ast) -> unquote(body)
          end

        {:else, [body: body]} ->
          quote do
            true -> unquote(body)
          end
      end)

    [if_clause] =
      quote do
        unquote(ast) -> unquote(body)
      end

    quote do
      cond do
        unquote([if_clause | cond_clauses])
      end
    end
  end

  def object_present?(path) do
    quote do
      Liquix.Runtime.safe_present?(data, unquote(path))
    end
  end

  def object_tag([ast]) do
    quote do
      Kernel.to_string(unquote(ast))
    end
  end

  def object(path) do
    quote do
      case Liquix.Runtime.safe_lookup(data, unquote(path)) do
        {:ok, stuff} -> stuff
        :nope -> nil
      end
    end
  end

  def placeholder_present?([val]) do
    quote do
      !!unquote(val)
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
