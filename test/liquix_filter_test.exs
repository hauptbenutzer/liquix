defmodule LiquixFilterTest do
  use ExUnit.Case

  defmodule Bam do
    require Liquix

    template = """
    {{ 4 | at_most: 5 }}-{{ 4 | at_most: 3 }}
    """

    Liquix.compile_from_string(:at_most, template)

    template = ~S({{ "Take my protein pills and put my helmet on" | replace: "my", "your" }})
    Liquix.compile_from_string(:replace, template)

    template = """
    {% assign my_array = "ants, bugs, bees, bugs, ants" | split: ", " %}

    {{ my_array | uniq | join: ", " }}
    """

    Liquix.compile_from_string(:uniq_join, template)
  end

  test "at_most" do
    assert Bam.at_most(%{}) == "4-3\n"
  end

  test "replace" do
    assert Bam.replace(%{}) == "Take your protein pills and put your helmet on"
  end

  test "uniq_join" do
    assert Bam.uniq_join(%{}) == "\n\nants, bugs, bees"
  end
end
