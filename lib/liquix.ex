defmodule Liquix do
  alias Liquix.Compiler

  defmacro compile_from_string(fun_name, template, options \\ []) do
    quote bind_quoted: binding() do
      body = Liquix.compile(template)

      {_, data_seen} =
        Macro.postwalk(body, false, fn
          expr, true -> {expr, true}
          {:data, _, nil} = expr, false -> {expr, true}
          expr, val -> {expr, val}
        end)

      if Keyword.get(options, :debug) do
        IO.puts(inspect(fun_name))
        body |> Macro.to_string() |> Code.format_string!() |> IO.puts()
      end

      var_name = if data_seen, do: :data, else: :_data

      def unquote(fun_name)(unquote({var_name, [], nil})), do: IO.iodata_to_binary(unquote(body))
    end
  end

  def compile(template) do
    {:ok, ast, _, _, _, _} = Compiler.parse(template)

    Macro.postwalk(ast, fn
      {:data, y, _} -> {:data, y, nil}
      expr -> expr
    end)
  end
end
