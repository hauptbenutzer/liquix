defmodule LiquixTest do
  use Liquix.Test.LiquidCase, async: true

  @tag template: """
       {% if user %}
         Hello {{ user.name }}!
       {% endif %}
       """
  test "greets the world", %{render: render} do
    assert render.(%{"user" => %{"name" => "Peter"}}) == "\n  Hello Peter!\n\n"
    assert render.(%{"user" => %{"eman" => "Peter"}}) == "\n  Hello !\n\n"
    assert render.(%{"user" => "nopey"}) == "\n  Hello !\n\n"
    assert render.(%{}) == "\n"
  end

  @tag template: """
       {% if user %}
         Hello {% if user.name %}my good friend {{ user.name }}!{% endif %}
       {% endif %}
       """
  test "nested", %{render: render} do
    assert render.(%{"user" => %{"name" => "Freud"}}) == "\n  Hello my good friend Freud!\n\n"
    assert render.(%{"user" => %{"name" => false}}) == "\n  Hello \n\n"
    assert render.(%{"user" => %{"name" => :some_atom}}) == "\n  Hello my good friend some_atom!\n\n"
  end

  @tag template: """
       {% if val.a and val.b %}1{% endif %}
       {% if val.a or val.b %}2{% endif %}
       """
  test "bool operator", %{render: render} do
    assert render.(%{"val" => %{"a" => true, "b" => false}}) == "\n2\n"
    assert render.(%{"val" => %{"a" => false, "b" => true}}) == "\n2\n"
    assert render.(%{"val" => %{"a" => false, "b" => false}}) == "\n\n"
    assert render.(%{"val" => %{"a" => true, "b" => true}}) == "1\n2\n"

    assert render.(%{"val" => %{"a" => 42}}) == "\n2\n"
    assert render.(%{"val" => %{"b" => :yes}}) == "\n2\n"
    assert render.(%{"val" => %{}}) == "\n\n"
    assert render.(%{"val" => %{"a" => "what", "b" => 123.31}}) == "1\n2\n"
  end

  @tag template: """
       {% if val.a and val.b or val.c %}1{% endif %}
       {% if val.a or val.b and val.c %}2{% endif %}
       """
  test "bool operator order", %{render: render} do
    assert render.(%{"val" => %{"a" => true, "b" => true, "c" => true}}) == "1\n2\n"
    assert render.(%{"val" => %{"a" => true, "b" => true, "c" => false}}) == "1\n2\n"
    assert render.(%{"val" => %{"a" => true, "b" => false, "c" => true}}) == "1\n2\n"
    assert render.(%{"val" => %{"a" => true, "b" => false, "c" => false}}) == "\n2\n"
    assert render.(%{"val" => %{"a" => false, "b" => true, "c" => true}}) == "\n2\n"
    assert render.(%{"val" => %{"a" => false, "b" => true, "c" => false}}) == "\n\n"
    assert render.(%{"val" => %{"a" => false, "b" => false, "c" => true}}) == "\n\n"
    assert render.(%{"val" => %{"a" => false, "b" => false, "c" => false}}) == "\n\n"
  end

  @tag template: """
       {% if a == b %}1{% endif %}
       {% if a != b %}2{% endif %}
       {% if a > b %}3{% endif %}
       {% if a < b %}4{% endif %}
       {% if a >= b %}5{% endif %}
       {% if a <= b %}6{% endif %}
       """
  test "comparison operators", %{render: render} do
    assert render.(%{"a" => "peter", "b" => "peter"}) == "1\n\n\n\n5\n6\n"
    assert render.(%{"a" => "peter", "b" => "peter!"}) == "\n2\n\n4\n\n6\n"
    assert render.(%{"a" => 42, "b" => 40}) == "\n2\n3\n\n5\n\n"
    assert render.(%{"a" => 40, "b" => 42}) == "\n2\n\n4\n\n6\n"
    assert render.(%{"a" => "peter", "b" => "peter"}) == "1\n\n\n\n5\n6\n"
    assert render.(%{"a" => "peter", "b" => "peter!"}) == "\n2\n\n4\n\n6\n"
  end

  @tag template: ~S"""
       {% if 42 %}1{% endif %}
       {% if '42' %}2{% endif %}
       {% if "42\"1" %}3{% endif %}
       {% if 42.41 %}4{% endif %}
       {% if true %}5{% endif %}
       {% if false %}6{% endif %}
       {% if truedat or nilyou or falseify %}7{% endif %}
       {% if "" and empty %}8{% endif %}
       """
  test "literals", %{render: render} do
    assert render.(%{"truedat" => 1, "empty" => ""}) == "1\n2\n3\n4\n5\n\n7\n8\n"
  end

  @tag template: ~S"""
       {% if fourtytwo >= 42 %}1{% endif %}
       {% if "42" > "142" %}2{% endif %}
       {% if 42.41 == 42.410 %}3{% endif %}
       {% if falsefy < true %}4{% endif %}
       {% if there != nil %}5{% endif %}
       {% if 'this' == "this" %}6{% endif %}
       """
  test "literal comparison", %{render: render} do
    assert render.(%{"fourtytwo" => 42, "falsefy" => false, "there" => "nil"}) ==
             "1\n2\n3\n4\n5\n6\n"
  end

  @tag template: ~S"""
       {% if 'fourtytwo' contains 'two' %}1{% endif %}
       {% if fourtytwo contains 'ourt' %}2{% endif %}
       {% if '42' contains 42 %}3{% endif %}
       {% if fourtytwo contains 'zweiundvierzig' %}4{% endif %}
       """
  test "contains", %{render: render} do
    assert render.(%{"fourtytwo" => "fourtytwo"}) == "1\n2\n3\n\n"
  end

  @tag template: ~S"""
       {{ 'me' }} {{ "I'm "}} not {{ 42.2 }} {{ false }}
       """
  test "object literals", %{render: render} do
    assert render.(%{}) == "me I'm  not 42.2 false\n"
  end
end
