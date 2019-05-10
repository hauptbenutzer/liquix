defmodule LiquixListTest do
  use ExUnit.Case

  defmodule Bam do
    require Liquix

    template = """
    {% assign var = 2 %}
    {{ list[0].name }} - {{ object['one'].nested[var] }}
    """

    Liquix.compile_from_string(:simple, template)
  end

  test "simple" do
    assert Bam.simple(%{list: [%{name: "peter"}], object: %{one: %{nested: [0, 0, "Wuhu!"]}}}) ==
             "\npeter - Wuhu!\n"
  end
end
