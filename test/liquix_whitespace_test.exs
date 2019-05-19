defmodule LiquixWhitespaceTest do
  use Liquix.Test.LiquidCase, async: true

  # @tag template: """
  #      {% assign my_variable = "tomato" -%}
  #      {{ my_variable -}}
  #      """
  # test "simple", %{render: render} do
  #   assert render.(%{}) == "tomato"
  # end

  # @tag template: """
  #      {%- assign username = "John G. Chalmers-Smith" -%}
  #      {%- if username and username.size > 10 -%}
  #        Wow, {{ username }}, you have a long name!
  #      {%- else -%}
  #        Hello there!
  #      {%- endif -%}
  #      """
  # test "if with else", %{render: render} do
  #   assert render.(%{}) == "tomato"
  # end
end
