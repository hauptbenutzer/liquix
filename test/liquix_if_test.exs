defmodule LiquixIfTest do
  use Liquix.Test.LiquidCase, async: true

  @tag template: ~S({% if user %}Hello{% else %}Oh no!{% endif %})
  test "if with else", %{render: render} do
    assert render.(%{"user" => "Peter"}) == "Hello"
    assert render.(%{"user" => false}) == "Oh no!"
  end

  @tag template: ~S({% if a %}Hello{% elsif b %}Good god{% elsif c %}Help us{% else %}Oh no!{% endif %})
  test "if with elsif and else", %{render: render} do
    assert render.(%{"a" => true}) == "Hello"
    assert render.(%{"b" => true}) == "Good god"
    assert render.(%{"c" => true}) == "Help us"
    assert render.(%{}) == "Oh no!"
  end
end
