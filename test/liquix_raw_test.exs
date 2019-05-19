defmodule LiquixRawTest do
  use Liquix.Test.LiquidCase, async: true

  @tag template: "{% raw %}Hello {{ peter }} vs. {{{ peter }}} and {% for %}{% endraw %}"
  test "if with else", %{render: render} do
    assert render.(%{}) == "Hello {{ peter }} vs. {{{ peter }}} and {% for %}"
  end
end
