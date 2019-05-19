defmodule Liquix.Runtime do
  @moduledoc """
  This module contains functions that are called while rendering a precompiled template.

  These cannot be further inlined, as they depend on the runtime assignment and configuration of variables.
  """
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
         "first" => idx == 0,
         "last" => idx == length - 1,
         "index" => idx + 1,
         "index0" => idx,
         "length" => length,
         "rindex" => length - idx,
         "rindex0" => length - idx - 1
       }, item}
    end)
  end

  def safe_lookup(data, []), do: {:ok, data}

  def safe_lookup(data, [key | rest]) when is_integer(key) do
    cond do
      is_list(data) -> safe_lookup(Enum.at(data, key), rest)
      true -> :nope
    end
  end

  def safe_lookup(data, [key | rest]) when is_binary(key) do
    case data do
      %{^key => val} -> safe_lookup(val, rest)
      _ -> :nope
    end
  end

  def filter(val, "abs", []) do
    abs(to_number(val))
  end

  def filter(val, "at_most", [most]) do
    min(val, most)
  end

  def filter(val, "replace", [this, that]) do
    String.replace(val, this, that)
  end

  def filter(val, "split", [splitter]) do
    String.split(val, splitter)
  end

  def filter(val, "uniq", []) do
    Enum.uniq(val)
  end

  def filter(val, "join", [joiner]) do
    Enum.join(val, joiner)
  end

  def to_number(val) when is_number(val), do: val

  def to_number(val) when is_binary(val) do
    case Integer.parse(val) do
      {int, ""} ->
        int

      _ ->
        case Float.parse(val) do
          {float, ""} -> float
          _ -> nil
        end
    end
  end
end
