defmodule LiquixListTest do
  use Liquix.Test.LiquidCase, async: true

  @tag template: """
       {% assign var = 2 %}
       {{ list[0].name }} - {{ object['one'].nested[var] }}
       """
  test "simple", %{render: render} do
    assert render.(%{"list" => [%{"name" => "peter"}], "object" => %{"one" => %{"nested" => [0, 0, "Wuhu!"]}}}) ==
             "\npeter - Wuhu!\n"
  end

  @tag template: """
       {% assign var = object['first'].nil %}
       {{ var[object.second].here[object['third']] }}
       """
  test "ridiculous", %{render: render} do
    assert render.(%{
             "object" => %{
               "first" => %{"nil" => %{"nested" => %{"here" => %{"low" => "Wuhu!"}}}},
               "second" => "nested",
               "third" => "low"
             }
           }) == "\nWuhu!\n"
  end

  @tag template: ~S({{ object['first']['second'].third }})
  test "chained", %{render: render} do
    assert render.(%{"object" => %{"first" => %{"second" => %{"third" => "Yes!"}}}}) == "Yes!"
  end
end
