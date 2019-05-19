defmodule LiquixForTest do
  use Liquix.Test.LiquidCase, async: true

  @tag template: ~S({% for user in site.users %}{{ user }} {% endfor %})
  test "simple for", %{render: render} do
    assert render.(%{"site" => %{"users" => ["Peter", "Retep", "Suzy"]}}) == "Peter Retep Suzy "
  end

  @tag template: """
       {% for user in users %}
         {{ user }} {{ forloop.index }}/{{ forloop.index0 }}/{{ forloop.rindex }}/{{ forloop.rindex0 }} of {{ forloop.length }}, {{ forloop.first }}|{{ forloop.last }}
       {% endfor %}
       """
  test "forloop object", %{render: render} do
    assert render.(%{"users" => ["Peter", "Retep", "Suzzy"]}) ==
             """

               Peter 1/0/3/2 of 3, true|false

               Retep 2/1/2/1 of 3, false|false

               Suzzy 3/2/1/0 of 3, false|true

             """
  end

  @tag template: ~S[{% for i in (0..4) %}{{ i }} {% endfor %}]
  test "simple range", %{render: render} do
    assert render.(%{}) == "0 1 2 3 4 "
  end

  @tag template: ~S[{% for i in (from..to) %}{{ i }} {% endfor %}]
  test "var range", %{render: render} do
    assert render.(%{"from" => -3, "to" => 2}) == "-3 -2 -1 0 1 2 "
    assert render.(%{"from" => "-3", "to" => "2"}) == "-3 -2 -1 0 1 2 "
    assert render.(%{"from" => "nosir", "to" => -2.6}) == "0 -1 -2 "
  end
end
