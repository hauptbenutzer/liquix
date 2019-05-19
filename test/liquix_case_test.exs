defmodule LiquixCaseTest do
  use Liquix.Test.LiquidCase, async: true

  @tag template: ~S({% case value %}{% when 'a' %}a{% when 'b' %}b{% when 42 %}c{% else %}else{% endcase %})
  test "inline case", %{render: render} do
    assert render.(%{"value" => "a"}) == "a"
    assert render.(%{"value" => "b"}) == "b"
    assert render.(%{"value" => 42}) == "c"
    assert render.(%{"value" => nil}) == "else"
    assert render.(%{"value" => "whatevs"}) == "else"
    assert render.(%{"value" => 42.0}) == "else"
  end

  @tag template: """
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
  test "nested case", %{render: render} do
    assert render.(%{"value" => "a", "eulav" => "a"}) == "\n    a2\n  \n"
    assert render.(%{"value" => "b"}) == "\n    b\n  \n"
    assert render.(%{"value" => 42}) == "\n    c\n  \n"
    assert render.(%{"value" => "42"}) == "\n    else\n\n"
    assert render.(%{"value" => false}) == "\n    else\n\n"
  end
end
