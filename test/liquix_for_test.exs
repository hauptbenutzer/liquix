defmodule LiquixForTest do
  use ExUnit.Case

  defmodule Bam do
    require Liquix

    template = """
    {% for user in site.users %}{{ user }} {% endfor %}
    """

    Liquix.compile_from_string(:simple, template)

    template = """
    {% for user in users %}
      {{ user }} {{ forloop.index }}/{{ forloop.index0 }}/{{ forloop.rindex }}/{{ forloop.rindex0 }} of {{ forloop.length }}, {{ forloop.first }}|{{ forloop.last }}
    {% endfor %}
    """

    Liquix.compile_from_string(:forloop_object, template)

    template = """
    {% for i in (0..4) %}{{ i }} {% endfor %}
    """

    Liquix.compile_from_string(:simple_range, template)

    template = """
    {% for i in (from..to) %}{{ i }} {% endfor %}
    """

    Liquix.compile_from_string(:var_range, template)
  end

  test "simple for" do
    assert Bam.simple(%{site: %{users: ["Peter", "Retep", "Suzy"]}}) == "Peter Retep Suzy \n"
  end

  test "forloop object" do
    assert Bam.forloop_object(%{users: ["Peter", "Retep", "Suzzy"]}) ==
             """

               Peter 1/0/3/2 of 3, true|false

               Retep 2/1/2/1 of 3, false|false

               Suzzy 3/2/1/0 of 3, false|true

             """
  end

  test "simple range" do
    assert Bam.simple_range(%{}) == "0 1 2 3 4 \n"
  end

  test "var range" do
    assert Bam.var_range(%{from: -3, to: 2}) == "-3 -2 -1 0 1 2 \n"
    assert Bam.var_range(%{from: "-3", to: "2"}) == "-3 -2 -1 0 1 2 \n"
    assert Bam.var_range(%{from: "nosir", to: -2.6}) == "0 -1 -2 \n"
  end
end
