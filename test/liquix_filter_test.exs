defmodule LiquixFilterTest do
  use Liquix.Test.LiquidCase, async: true

  @tag template: ~S({{ 4 | at_most: 5 }}-{{ 4 | at_most: 3 }})
  test "at_most", %{render: render} do
    assert render.(%{}) == "4-3"
  end

  @tag template: ~S({{ "Take my protein pills and put my helmet on" | replace: "my", "your" }})
  test "replace", %{render: render} do
    assert render.(%{}) == "Take your protein pills and put your helmet on"
  end

  @tag template: """
       {% assign my_array = "ants, bugs, bees, bugs, ants" | split: ", " %}

       {{ my_array | uniq | join: ", " }}
       """
  test "uniq_join", %{render: render} do
    assert render.(%{}) == "\n\nants, bugs, bees\n"
  end

  @tag template: """
       {{ -17 | abs }}
       {{ 4 | abs }}
       {{ "-19.86" | abs }}
       {{ "-42" | abs}}
       """
  test "abs", %{render: render} do
    assert render.(%{}) == "17\n4\n19.86\n42\n"
  end
end
