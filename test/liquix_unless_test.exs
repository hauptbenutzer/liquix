defmodule LiquixUnlessTest do
  use Liquix.Test.LiquidCase, async: true

  @tag template: ~S({% unless user %}Hello{% else %}Oh no!{% endunless %})
  test "if with else", %{render: render} do
    assert render.(%{"user" => "Peter"}) == "Oh no!"
    assert render.(%{"user" => false}) == "Hello"
  end

  @tag template: ~S({% unless a %}Hello{% elsif b %}Good god{% elsif c %}Help us{% else %}Oh no!{% endunless %})
  test "if with elsif and else", %{render: render} do
    assert render.(%{"a" => true}) == "Oh no!"
    assert render.(%{"a" => true, "b" => true}) == "Good god"
    assert render.(%{"a" => true, "c" => true}) == "Help us"
    assert render.(%{}) == "Hello"
  end
end
