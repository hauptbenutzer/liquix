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

    template = """
    {% if a == b %}1{% endif %}
    {% if a != b %}2{% endif %}
    {% if a > b %}3{% endif %}
    {% if a < b %}4{% endif %}
    {% if a >= b %}5{% endif %}
    {% if a <= b %}6{% endif %}
    """

    Liquix.compile_from_string(:binary_operators, template)

    template = ~S"""
    {% if 42 %}1{% endif %}
    {% if '42' %}2{% endif %}
    {% if "42\"1" %}3{% endif %}
    {% if 42.41 %}4{% endif %}
    {% if true %}5{% endif %}
    {% if false %}6{% endif %}
    {% if truedat or nilyou or falseify %}7{% endif %}
    {% if "" and empty %}8{% endif %}
    """

    Liquix.compile_from_string(:literal, template)

    template = ~S"""
    {% if fourtytwo >= 42 %}1{% endif %}
    {% if "42" > "142" %}2{% endif %}
    {% if 42.41 == 42.410 %}3{% endif %}
    {% if falsefy < true %}4{% endif %}
    {% if there != nil %}5{% endif %}
    {% if 'this' == "this" %}6{% endif %}
    """

    Liquix.compile_from_string(:literal_comparison, template)

    template = ~S"""
    {% if 'fourtytwo' contains 'two' %}1{% endif %}
    {% if fourtytwo contains 'ourt' %}2{% endif %}
    {% if '42' contains 42 %}3{% endif %}
    {% if fourtytwo contains 'zweiundvierzig' %}4{% endif %}
    """

    Liquix.compile_from_string(:contains, template)

    template = ~S"""
    {{ 'me' }} {{ "I'm "}} not {{ 42.2 }} {{ false }}
    """

    Liquix.compile_from_string(:object_literals, template)
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
    assert Bam.binary_operators(%{a: "peter", b: "peter"}) == "1\n\n\n\n5\n6\n"
    assert Bam.binary_operators(%{a: "peter", b: "peter!"}) == "\n2\n\n4\n\n6\n"
    assert Bam.binary_operators(%{a: 42, b: 40}) == "\n2\n3\n\n5\n\n"
    assert Bam.binary_operators(%{a: 40, b: 42}) == "\n2\n\n4\n\n6\n"
    assert Bam.binary_operators(%{a: "peter", b: "peter"}) == "1\n\n\n\n5\n6\n"
    assert Bam.binary_operators(%{a: "peter", b: "peter!"}) == "\n2\n\n4\n\n6\n"
  end

  test "literals" do
    assert Bam.literal(%{truedat: 1, empty: ""}) == "1\n2\n3\n4\n5\n\n7\n8\n"
  end

  test "literal comparison" do
    assert Bam.literal_comparison(%{fourtytwo: 42, falsefy: false, there: "nil"}) ==
             "1\n2\n3\n4\n5\n6\n"
  end

  test "contains" do
    assert Bam.contains(%{fourtytwo: "fourtytwo"}) == "1\n2\n3\n\n"
  end

  test "object literals" do
    assert Bam.object_literals(%{}) == "me I'm  not 42.2 false\n"
  end
end
