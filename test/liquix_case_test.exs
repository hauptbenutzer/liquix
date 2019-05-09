defmodule LiquixCaseTest do
  use ExUnit.Case

  defmodule Bam do
    require Liquix

    template = """
    {% case value %}{% when 'a' %}a{% when 'b' %}b{% when 42 %}c{% else %}else{% endcase %}
    """

    Liquix.compile_from_string(:inline, template)

    template = """
    {% case value %}
      {% when 'a' %}
        {% case eulav %}{% when 'a' %}a2{% endcase %}
      {% when 'b' %}
        b
      {% when 42 %}
        c
      {% else %}
        else
    {% endcase %}
    """

    Liquix.compile_from_string(:multiline_nested, template)
  end

  test "inline case" do
    assert Bam.multiline_nested(%{value: "a", eulav: "a"}) == "\n    a2\n  \n"
    assert Bam.multiline_nested(%{value: "b"}) == "\n    b\n  \n"
    assert Bam.multiline_nested(%{value: 42}) == "\n    c\n  \n"
    assert Bam.multiline_nested(%{value: "42"}) == "\n    else\n\n"
    assert Bam.multiline_nested(%{value: false}) == "\n    else\n\n"
  end
end
