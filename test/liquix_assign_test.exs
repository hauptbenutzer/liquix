defmodule LiquixAssignTest do
  use ExUnit.Case

  defmodule Bam do
    require Liquix

    template = """
    {% assign var = 42 %}{{ var }}
    """

    Liquix.compile_from_string(:simple, template)

    template = """
    {% assign var = 42 %}
    {% if var %}
      {% assign var = lookhere %}
      in if: {{ var }}
    {% endif %}
    outside if: {{ var }}
    """

    Liquix.compile_from_string(:lookup_and_shadow, template)
  end

  test "simple assign" do
    assert Bam.simple(%{}) == "42\n"
  end

  test "lookup and shadow" do
    assert Bam.lookup_and_shadow(%{lookhere: "there"}) == "\n\n  \n  in if: there\n\noutside if: 42\n"
  end
end
