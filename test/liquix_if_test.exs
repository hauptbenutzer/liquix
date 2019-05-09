defmodule LiquixIfTest do
  use ExUnit.Case

  defmodule Bam do
    require Liquix

    template = """
    {% if user %}Hello{% else %}Oh no!{% endif %}
    """

    Liquix.compile_from_string(:if_else, template)

    template = """
    {% if a %}Hello{% elsif b %}Good god{% elsif c %}Help us{% else %}Oh no!{% endif %}
    """

    Liquix.compile_from_string(:if_elsif_else, template)
  end

  test "if with else" do
    assert Bam.if_else(%{user: "Peter"}) == "Hello\n"
    assert Bam.if_else(%{user: false}) == "Oh no!\n"
  end

  test "if with elsif and else" do
    assert Bam.if_elsif_else(%{a: true}) == "Hello\n"
    assert Bam.if_elsif_else(%{b: true}) == "Good god\n"
    assert Bam.if_elsif_else(%{c: true}) == "Help us\n"
    assert Bam.if_elsif_else(%{}) == "Oh no!\n"
  end
end
