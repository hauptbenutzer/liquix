defmodule LiquixTest do
  use ExUnit.Case

  defmodule Bam do
    require Liquix

    Liquix.compile(
      :simple,
      """
      {% if user %}
        Hello {{ user.name }}!
      {% endif %}
      """
    )
  end

  test "greets the world" do
    assert Bam.simple(%{user: %{name: "Peter"}}) == "\n  Hello Peter!\n\n"
    assert Bam.simple(%{user: %{eman: "Peter"}}) == "\n  Hello !\n\n"
    assert Bam.simple(%{user: "nopey"}) == "\n  Hello !\n\n"
    assert Bam.simple(%{}) == "\n"
  end
end
