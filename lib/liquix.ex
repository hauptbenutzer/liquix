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

  defparsec(
    :object_path,
    identifier
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
  )

  open_object_tag = ignore(string("{{") |> concat(whitespace_or_nothing))
  close_object_tag = ignore(whitespace_or_nothing |> string("}}"))

  object =
    parsec(:object_path)
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

  # TODO: signed
  num_literal = choice([float, int])

  range_literal =
    ignore(string("("))
    |> unwrap_and_tag(choice([int, parsec(:placeholder)]), :from)
    |> ignore(string(".."))
    |> unwrap_and_tag(choice([int, parsec(:placeholder)]), :to)
    |> ignore(string(")"))
    |> reduce({__MODULE__, :range_literal, []})

  bool_literal =
    choice([
      string("true") |> replace(true),
      string("false") |> replace(false),
      string("nil") |> replace(nil)
    ])
    |> lookahead_not(word)
    |> reduce({List, :first, []})

  literal = choice([string_literal, num_literal, bool_literal, range_literal])

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

  assign_tag =
    open_tag
    |> ignore(string("assign"))
    |> ignore(whitespace)
    |> unwrap_and_tag(identifier, :var_name)
    |> ignore(whitespace)
    |> ignore(string("="))
    |> ignore(whitespace)
    |> unwrap_and_tag(parsec(:placeholder), :var_val)
    |> concat(close_tag)
    |> tag(parsec(:markup), :body)
    |> reduce({__MODULE__, :assign_tag, []})

  for_tag =
    open_tag
    |> ignore(string("for"))
    |> ignore(whitespace)
    |> unwrap_and_tag(identifier, :var_name)
    |> ignore(whitespace)
    |> ignore(string("in"))
    |> ignore(whitespace)
    |> unwrap_and_tag(parsec(:placeholder), :var_val)
    |> concat(close_tag)
    |> tag(parsec(:markup), :body)
    |> ignore(open_tag |> concat(string("endfor")) |> concat(close_tag))
    |> reduce({__MODULE__, :for_tag, []})

  if_tag =
    open_tag
    |> ignore(string("if "))
    |> unwrap_and_tag(parsec(:if_clause), :condition)
    |> concat(close_tag)
    |> tag(parsec(:markup), :body)
    |> tag(:if)
    |> optional(
      times(
        open_tag
        |> ignore(string("elsif "))
        |> unwrap_and_tag(parsec(:if_clause), :condition)
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
    |> reduce({__MODULE__, :if_tag, []})

  unless_tag =
    open_tag
    |> ignore(string("unless "))
    |> unwrap_and_tag(parsec(:if_clause), :condition)
    |> concat(close_tag)
    |> tag(parsec(:markup), :body)
    |> tag(:unless)
    |> optional(
      times(
        open_tag
        |> ignore(string("elsif "))
        |> unwrap_and_tag(parsec(:if_clause), :condition)
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
    |> ignore(open_tag |> concat(string("endunless")) |> concat(close_tag))
    |> reduce({__MODULE__, :unless_tag, []})

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

  liquid = choice([object_tag, if_tag, unless_tag, case_tag, assign_tag, for_tag])

  garbage =
    times(
      lookahead_not(choice([string("{{"), string("{%")]))
      |> utf8_string([], 1),
      min: 1
    )
    |> reduce({Enum, :join, []})

  defparsec(:markup, repeat(choice([liquid, garbage])))

  defparsec(:parse, parsec(:markup))

  defmacro compile_from_string(fun_name, template, options \\ []) do
    quote bind_quoted: binding() do
      body = Liquix.compile(template)

      if Keyword.get(options, :debug) do
        IO.puts(inspect(fun_name))
        body |> Macro.to_string() |> Code.format_string!() |> IO.puts()
      end

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

  def assign_tag(var_name: var_name, var_val: var_val, body: body) do
    quote do
      data = Map.put(data, unquote(String.to_atom(var_name)), unquote(var_val))
      unquote(body)
    end
  end

  def for_tag(var_name: var_name, var_val: var_val, body: body) do
    quote do
      case unquote(var_val) do
        list when is_list(list) ->
          for {forloop, item} <- Liquix.Runtime.forloop(list) do
            data = data |> Map.put(:forloop, forloop) |> Map.put(unquote(String.to_atom(var_name)), item)
            unquote(body)
          end

        _ ->
          ""
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

  def range_literal(from: from, to: to) do
    quote do
      from = Liquix.Runtime.range_limit(unquote(from))
      to = Liquix.Runtime.range_limit(unquote(to))
      from..to |> Enum.to_list()
    end
  end

  def if_tag(clauses) do
    cond_clauses =
      Enum.flat_map(clauses, fn
        {:if, [condition: condition, body: body]} ->
          quote do
            unquote(condition) -> unquote(body)
          end

        {:elsif, [condition: condition, body: body]} ->
          quote do
            unquote(condition) -> unquote(body)
          end

        {:else, [body: body]} ->
          quote do
            true -> unquote(body)
          end
      end)

    empty_else =
      quote do
        true -> ""
      end

    cond_clauses = if Keyword.has_key?(clauses, :else), do: cond_clauses, else: Enum.concat(cond_clauses, empty_else)

    quote do
      cond do
        unquote(cond_clauses)
      end
    end
  end

  # TODO: maybe refactor unless/if to use same logic?
  def unless_tag(clauses) do
    cond_clauses =
      Enum.flat_map(clauses, fn
        {:unless, [condition: condition, body: body]} ->
          quote do
            Kernel.not(unquote(condition)) -> unquote(body)
          end

        {:elsif, [condition: condition, body: body]} ->
          quote do
            unquote(condition) -> unquote(body)
          end

        {:else, [body: body]} ->
          quote do
            true -> unquote(body)
          end
      end)

    empty_else =
      quote do
        true -> ""
      end

    cond_clauses = if Keyword.has_key?(clauses, :else), do: cond_clauses, else: Enum.concat(cond_clauses, empty_else)

    quote do
      cond do
        unquote(cond_clauses)
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
    def range_limit(float) when is_float(float), do: trunc(float)
    def range_limit(int) when is_integer(int), do: int

    def range_limit(binary) when is_binary(binary) do
      case Integer.parse(binary) do
        {int, _} -> int
        _ -> 0
      end
    end

    def range_limit(_), do: 0

    def forloop(list) do
      length = length(list)

      list
      |> Enum.with_index()
      |> Enum.map(fn {item, idx} ->
        {%{
           first: idx == 0,
           last: idx == length - 1,
           index: idx + 1,
           index0: idx,
           length: length,
           rindex: length - idx,
           rindex0: length - idx - 1
         }, item}
      end)
    end

    def safe_present?(data, path) do
      case safe_lookup(data, path) do
        {:ok, val} -> !!val
        :nope -> false
      end
    end

    def safe_lookup(data, []), do: {:ok, data}

    def safe_lookup(data, [key | rest]) when is_integer(key) do
      cond do
        is_list(data) -> safe_lookup(Enum.at(data, key), rest)
        true -> :nope
      end
    end

    def safe_lookup(data, [key | rest]) when is_binary(key) do
      key = String.to_atom(key)

      case data do
        %{^key => val} -> safe_lookup(val, rest)
        _ -> :nope
      end
    end
  end
end
