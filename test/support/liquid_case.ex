defmodule Liquix.Test.LiquidCase do
  use ExUnit.CaseTemplate

  setup context do
    if template = context[:template] do
      modname = :"#{context.module}.#{Macro.camelize(String.replace(Atom.to_string(context.test), " ", "_"))}"

      contents =
        quote do
          require Liquix
          Liquix.compile_from_string(:render, unquote(template))
        end

      Module.create(modname, contents, Macro.Env.location(__ENV__))

      [render: &modname.render/1]
    else
      :ok
    end
  end
end
