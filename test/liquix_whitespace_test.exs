defmodule LiquixWhitespaceTest do
  use ExUnit.Case

  defmodule Bam do
    require Liquix

    template = """
    {% assign my_variable = "tomato" -%}
    {{ my_variable -}}
    """

    Liquix.compile_from_string(:simple, template)

    template = """
    {%- assign username = "John G. Chalmers-Smith" -%}
    {%- if username and username.size > 10 -%}
      Wow, {{ username }}, you have a long name!
    {%- else -%}
      Hello there!
    {%- endif -%}
    """

    Liquix.compile_from_string(:more, template)
  end

  test "if with else" do
    assert Bam.more(%{}) == "tomato"
  end
end
