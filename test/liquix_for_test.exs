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
end
