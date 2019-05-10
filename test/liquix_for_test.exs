defmodule LiquixForTest do
  use ExUnit.Case

  defmodule Bam do
    require Liquix

    template = """
    {% for user in site.users %}
      {{ user }}
    {% endfor %}
    """

    Liquix.compile_from_string(:simple, template)
  end

  # test "simple for" do
  #   assert Bam.simple(%{site: %{users: ["Peter", "Retep", "Suzy"]}}) == "Hello\n"
  # end
end
