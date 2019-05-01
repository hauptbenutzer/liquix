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

    template = """
    {% if val.a and val.b %}1{% endif %}
    {% if val.a or val.b %}2{% endif %}
    """

    Liquix.compile_from_string(:bool_operator, template)

    template = """
    {% if val.a and val.b or val.c %}1{% endif %}
    {% if val.a or val.b and val.c %}2{% endif %}
    """

    Liquix.compile_from_string(:bool_operator_order, template)
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

  test "bool operator" do
    assert Bam.bool_operator(%{val: %{a: true, b: false}}) == "\n2\n"
    assert Bam.bool_operator(%{val: %{a: false, b: true}}) == "\n2\n"
    assert Bam.bool_operator(%{val: %{a: false, b: false}}) == "\n\n"
    assert Bam.bool_operator(%{val: %{a: true, b: true}}) == "1\n2\n"

    assert Bam.bool_operator(%{val: %{a: 42}}) == "\n2\n"
    assert Bam.bool_operator(%{val: %{b: :yes}}) == "\n2\n"
    assert Bam.bool_operator(%{val: %{}}) == "\n\n"
    assert Bam.bool_operator(%{val: %{a: "what", b: 123.31}}) == "1\n2\n"
  end

  test "bool operator order" do
    assert Bam.bool_operator_order(%{val: %{a: true, b: true, c: true}}) == "1\n2\n"
    assert Bam.bool_operator_order(%{val: %{a: true, b: true, c: false}}) == "1\n2\n"
    assert Bam.bool_operator_order(%{val: %{a: true, b: false, c: true}}) == "1\n2\n"
    assert Bam.bool_operator_order(%{val: %{a: true, b: false, c: false}}) == "\n2\n"
    assert Bam.bool_operator_order(%{val: %{a: false, b: true, c: true}}) == "\n2\n"
    assert Bam.bool_operator_order(%{val: %{a: false, b: true, c: false}}) == "\n\n"
    assert Bam.bool_operator_order(%{val: %{a: false, b: false, c: true}}) == "\n\n"
    assert Bam.bool_operator_order(%{val: %{a: false, b: false, c: false}}) == "\n\n"
  end
end
