defmodule Liquix.Compiler do
  import NimbleParsec
  import Liquix.Compiler.Common
  import Liquix.Compiler.Conditionals
  import Liquix.Compiler.Iteration

  import Liquix.Compiler.Literals
  import Liquix.Compiler.Object

  defparsec(:literal, any_literal())
  defparsec(:placeholder, choice([parsec(:literal), object()]))

  defparsec(:object_path, object_path())

  defparsec(
    :filterable_placeholder,
    parsec(:placeholder)
    |> optional(
      times(
        wrap(
          ignore(
            whitespace_or_nothing()
            |> string("|")
            |> concat(whitespace_or_nothing())
          )
          |> unwrap_and_tag(identifier(), :name)
          |> optional(
            ignore(string(":"))
            |> ignore(whitespace_or_nothing())
            |> unwrap_and_tag(parsec(:literal), :param)
            |> repeat(
              ignore(whitespace_or_nothing())
              |> ignore(string(","))
              |> ignore(whitespace_or_nothing())
              |> unwrap_and_tag(parsec(:literal), :param)
            )
          )
        ),
        min: 1
      )
    )
    |> reduce({__MODULE__, :c_filterable_placeholder, []})
  )

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

  if_binary =
    parsec(:placeholder)
    |> ignore(whitespace())
    |> concat(binary_operator)
    |> ignore(whitespace())
    |> parsec(:placeholder)
    |> reduce({__MODULE__, :if_binary, []})

  if_placeholder =
    parsec(:placeholder)
    |> reduce({__MODULE__, :placeholder_present?, []})

  defparsec(
    :if_clause,
    choice([if_binary, if_placeholder])
    |> optional(
      ignore(whitespace_or_nothing())
      |> concat(bool_operator)
      |> ignore(whitespace_or_nothing())
      |> parsec(:if_clause)
    )
    |> tag(:if_clause)
    |> reduce({__MODULE__, :c_if_clause, []})
  )

  assign_tag =
    open_tag()
    |> ignore(string("assign"))
    |> ignore(whitespace())
    |> unwrap_and_tag(identifier(), :var_name)
    |> ignore(whitespace())
    |> ignore(string("="))
    |> ignore(whitespace())
    |> unwrap_and_tag(parsec(:filterable_placeholder), :var_val)
    |> concat(close_tag())
    |> tag(parsec(:markup), :body)
    |> reduce({__MODULE__, :assign_tag, []})

  raw_tag =
    open_tag()
    |> ignore(string("raw"))
    |> concat(close_tag())
    |> optional(
      times(
        # TODO: this is not well thought-out
        lookahead_not(string("{% endraw %}"))
        |> utf8_string([], 1),
        min: 1
      )
      |> reduce({Enum, :join, []})
    )
    |> concat(open_tag())
    |> ignore(string("endraw"))
    |> concat(close_tag())
    |> reduce({Enum, :join, []})

  liquid = choice([object_tag(), if_tag(), unless_tag(), case_tag(), assign_tag, for_tag(), raw_tag])

  garbage =
    times(
      lookahead_not(choice([whitespace() |> string("{%-"), string("{{"), string("{%"), string("{%-")]))
      |> utf8_string([], 1),
      min: 1
    )
    |> reduce({Enum, :join, []})

  defparsec(:markup, repeat(choice([liquid, garbage])))

  defparsec(:parse, parsec(:markup))

  def assign_tag(var_name: var_name, var_val: var_val, body: body) do
    quote do
      data = Map.put(data, unquote(var_name), unquote(var_val))
      unquote(body)
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

  def c_filterable_placeholder([val | filters]) do
    filter_applies =
      Enum.map(filters, fn [{:name, name} | params] ->
        params = Keyword.get_values(params, :param)

        quote do
          val = Liquix.Runtime.filter(val, unquote(name), unquote(params))
        end
      end)

    quote do
      val = unquote(val)
      unquote_splicing(filter_applies)
      val
    end
  end

  def placeholder_present?([val]) do
    quote do
      !!unquote(val)
    end
  end
end
