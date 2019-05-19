defmodule LiquixAssignTest do
  use Liquix.Test.LiquidCase, async: true

  @tag template: ~S({% assign var = 42 %}{{ var }})
  test "simple assign", %{render: render} do
    assert render.(%{}) == "42"
  end

  @tag template: """
       {% assign var = 42 %}
       {% if var %}
         {% assign var = lookhere %}
         in if: {{ var }}
       {% endif %}
       outside if: {{ var }}
       """
  test "lookup and shadow", %{render: render} do
    assert render.(%{"lookhere" => "there"}) == "\n\n  \n  in if: there\n\noutside if: 42\n"
  end
end
