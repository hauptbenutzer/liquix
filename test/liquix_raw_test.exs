defmodule LiquixRawTest do
  use ExUnit.Case

  defmodule Bam do
    require Liquix

    template = "{% raw %}Hello {{ peter }} vs. {{{ peter }}} and {% for %}{% endraw %}"

    Liquix.compile_from_string(:simple, template)
  end

  test "if with else" do
    assert Bam.simple(%{}) == "Hello {{ peter }} vs. {{{ peter }}} and {% for %}"
  end
end
