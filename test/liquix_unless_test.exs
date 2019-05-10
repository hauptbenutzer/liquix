defmodule LiquixUnlessTest do
  use ExUnit.Case

  defmodule Bam do
    require Liquix

    template = """
    {% unless user %}Hello{% else %}Oh no!{% endunless %}
    """

    Liquix.compile_from_string(:unless_else, template)

    template = """
    {% unless a %}Hello{% elsif b %}Good god{% elsif c %}Help us{% else %}Oh no!{% endunless %}
    """

    Liquix.compile_from_string(:unless_elsif_else, template)
  end

  test "if with else" do
    assert Bam.unless_else(%{user: "Peter"}) == "Oh no!\n"
    assert Bam.unless_else(%{user: false}) == "Hello\n"
  end

  test "if with elsif and else" do
    assert Bam.unless_elsif_else(%{a: true}) == "Oh no!\n"
    assert Bam.unless_elsif_else(%{a: true, b: true}) == "Good god\n"
    assert Bam.unless_elsif_else(%{a: true, c: true}) == "Help us\n"
    assert Bam.unless_elsif_else(%{}) == "Hello\n"
  end
end
