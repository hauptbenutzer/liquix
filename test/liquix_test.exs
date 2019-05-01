defmodule LiquixTest do
  use ExUnit.Case

  defmodule Bam do
    require Liquix

    template = """
    {% if user %}
      Hello {{ user.name }}!
    {% endif %}
    """

    Liquix.compile_from_string(:simple, template)

    template = """
    {% if user %}
      Hello {% if user.name %}my good friend {{ user.name }}!{% endif %}
    {% endif %}
    """

    Liquix.compile_from_string(:nested, template)
  end

  test "greets the world" do
    assert Bam.simple(%{user: %{name: "Peter"}}) == "\n  Hello Peter!\n\n"
    assert Bam.simple(%{user: %{eman: "Peter"}}) == "\n  Hello !\n\n"
    assert Bam.simple(%{user: "nopey"}) == "\n  Hello !\n\n"
    assert Bam.simple(%{}) == "\n"
  end

  test "nested" do
    assert Bam.nested(%{user: %{name: "Freud"}}) == "\n  Hello my good friend Freud!\n\n"
    assert Bam.nested(%{user: %{name: false}}) == "\n  Hello \n\n"
    assert Bam.nested(%{user: %{name: :some_atom}}) == "\n  Hello my good friend some_atom!\n\n"
  end
end
