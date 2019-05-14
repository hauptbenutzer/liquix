# Liquix

Liquix is a compile-time Liquid parser. It uses `NimbleParsec` to transform a given Liquid template into executable Elixir code (not entirely unlike Eex).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `liquix` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:liquix, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/liquix](https://hexdocs.pm/liquix).

## Currently unsupported

- Stateful looping features: 
  - `break` and `continue` in `for` loops
  - the `cycle` tag

### Code Caveats

- Currently, in NimbleParsec it is not possible to reference a `defparsec` from another module, i.e. all recursive calls have to happen in the same module. We do want to split up our code for readability, so `Liquix.Compiler` modules currently have `parsec()`-calls that are not defined within that same module.
