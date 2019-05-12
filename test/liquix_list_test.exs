defmodule LiquixListTest do
  use ExUnit.Case

  defmodule Bam do
    require Liquix

    template = """
    {% assign var = 2 %}
    {{ list[0].name }} - {{ object['one'].nested[var] }}
    """

    Liquix.compile_from_string(:simple, template)

    template = """
    {% assign var = object['first'].nil %}
    {{ var[object.second].here[object['third']] }}
    """

    Liquix.compile_from_string(:ridiculous, template)

    template = """
    {{ object['first']['second'].third }}
    """

    Liquix.compile_from_string(:chained, template)
  end

  test "simple" do
    assert Bam.simple(%{list: [%{name: "peter"}], object: %{one: %{nested: [0, 0, "Wuhu!"]}}}) ==
             "\npeter - Wuhu!\n"
  end

  test "ridiculous" do
    assert Bam.ridiculous(%{
             object: %{first: %{nil: %{nested: %{here: %{low: "Wuhu!"}}}}, second: "nested", third: "low"}
           }) == "\nWuhu!\n"
  end

  test "chained" do
    assert Bam.chained(%{object: %{first: %{second: %{third: "Yes!"}}}}) == "Yes!\n"
  end
end
