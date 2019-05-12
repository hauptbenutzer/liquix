defmodule Liquix.Compiler.Conditionals do
  import NimbleParsec
  import Liquix.Compiler.Common

  def if_tag(),
    do:
      open_tag()
      |> ignore(string("if "))
      |> unwrap_and_tag(parsec(:if_clause), :condition)
      |> concat(close_tag())
      |> tag(parsec(:markup), :body)
      |> tag(:if)
      |> optional(
        times(
          open_tag()
          |> ignore(string("elsif "))
          |> unwrap_and_tag(parsec(:if_clause), :condition)
          |> concat(close_tag())
          |> tag(parsec(:markup), :body)
          |> tag(:elsif),
          min: 1
        )
      )
      |> concat(
        optional(
          open_tag()
          |> ignore(string("else"))
          |> concat(close_tag())
          |> tag(parsec(:markup), :body)
          |> tag(:else)
        )
      )
      |> ignore(open_tag() |> concat(string("endif")) |> concat(close_tag()))
      |> reduce({__MODULE__, :if_tag, []})

  def unless_tag(),
    do:
      open_tag()
      |> ignore(string("unless "))
      |> unwrap_and_tag(parsec(:if_clause), :condition)
      |> concat(close_tag())
      |> tag(parsec(:markup), :body)
      |> tag(:unless)
      |> optional(
        times(
          open_tag()
          |> ignore(string("elsif "))
          |> unwrap_and_tag(parsec(:if_clause), :condition)
          |> concat(close_tag())
          |> tag(parsec(:markup), :body)
          |> tag(:elsif),
          min: 1
        )
      )
      |> concat(
        optional(
          open_tag()
          |> ignore(string("else"))
          |> concat(close_tag())
          |> tag(parsec(:markup), :body)
          |> tag(:else)
        )
      )
      |> ignore(open_tag() |> concat(string("endunless")) |> concat(close_tag()))
      |> reduce({__MODULE__, :unless_tag, []})

  def case_tag(),
    do:
      open_tag()
      |> ignore(string("case "))
      |> unwrap_and_tag(parsec(:placeholder), :placeholder)
      |> concat(close_tag())
      |> ignore(whitespace_or_nothing())
      |> times(
        open_tag()
        |> ignore(string("when "))
        |> unwrap_and_tag(parsec(:literal), :literal)
        |> concat(close_tag())
        |> tag(parsec(:markup), :body)
        |> tag(:case),
        min: 1
      )
      |> concat(
        optional(
          open_tag()
          |> ignore(string("else"))
          |> concat(close_tag())
          |> tag(parsec(:markup), :body)
          |> tag(:else)
        )
      )
      |> ignore(open_tag() |> concat(string("endcase")) |> concat(close_tag()))
      |> tag(:case)
      |> reduce({__MODULE__, :case_tag, []})

  def case_tag(case: [{:placeholder, placeholder} | clauses]) do
    case_clauses =
      clauses
      |> maybe_add_else()
      |> Enum.flat_map(fn
        {:case, [literal: literal, body: body]} ->
          quote do
            unquote(literal) -> unquote(body)
          end

        {:else, [body: body]} ->
          quote do
            _ -> unquote(body)
          end
      end)

    quote do
      case unquote(placeholder) do
        unquote(case_clauses)
      end
    end
  end

  def if_tag(clauses) do
    cond_clauses =
      clauses
      |> maybe_add_else()
      |> Enum.flat_map(fn
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

    quote do
      cond do
        unquote(cond_clauses)
      end
    end
  end

  # TODO: maybe refactor unless/if to use same logic?
  def unless_tag(clauses) do
    cond_clauses =
      clauses
      |> maybe_add_else()
      |> Enum.flat_map(fn
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

    quote do
      cond do
        unquote(cond_clauses)
      end
    end
  end

  defp maybe_add_else(clauses) do
    if Keyword.has_key?(clauses, :else), do: clauses, else: Enum.concat(clauses, else: [body: ""])
  end
end
