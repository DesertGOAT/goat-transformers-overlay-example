# goat-transformers-overlay-example

An example of a **private transformer overlay**, kept separate from the engine it
runs on. It shows the layering without holding anything controlled: copy this
shape, drop in your real packs, and keep that overlay private.

It is to [`goat-transformers`](https://github.com/DesertGOAT/goat-transformers)
what an environment overlay is to the code it deploys — the engine is public and
pinned; the formats are the overlay.

## The layering

```
  public goat-transformers (engines, spec, public packs)   <- pinned by core.ref
                      +
  this overlay (model/, packs/, provenance)                 <- the private part
                      =
  assembled tree: the engines run the overlay's formats     <- ./assemble.sh
```

The engine code never moves into the overlay, and the overlay's packs never move
into the public core. A change to the engine is a new `core.ref`; a change to a
format is a commit here.

## What an overlay owns

| Path | Holds |
|---|---|
| `core.ref` | the `goat-transformers` commit this overlay builds with |
| `model/<module>.def` | model modules for keys that exist only in the overlay's formats, marked `distribution controlled` |
| `packs/<format>/` | each format: `pack.def` (marked `distribution controlled`, with its `source`), `vectors/` |
| `PROVENANCE.md` | the rights basis and handling for the packs (a template here) |
| `assemble.sh` | combines the pinned core and these packs into a working tree |

In a real overlay the repository is **private**, access is limited to the people
allowed to hold the material, and `PROVENANCE.md` is filled in. This example is
public because everything in it is fictional.

## The example formats

`packs/xtdl-example/` and `packs/xtdl-b-example/` are two invented fixed-layout
binary formats, and `model/xtdl.def` is an invented model module with one key,
`xtdl.sector`. All three are marked `distribution controlled` to show the
mechanics; nothing in them is real.

| Conversion | Carries | Why |
|---|---|---|
| `xtdl-example` to `geojson` | position | both map the public `core` keys |
| `xtdl-example` to `xtdl-b-example` | position and `xtdl.sector` | both use the overlay's `xtdl` module |
| any public format to `xtdl-example` | position | a public pack cannot use a controlled module |

An engine started with `--max-distribution public` refuses the overlay's module
and packs, so a deployment entitled only to public formats cannot load them.

## Try it

```bash
# with a local clone of the public core:
./assemble.sh --core-dir /path/to/goat-transformers /tmp/assembled
# or fetching the pinned core over the network:
./assemble.sh /tmp/assembled

# run the reference engine against the assembled packs (public + overlay):
(cd /tmp/assembled/engines/rust && cargo test)

# a public-only engine refuses the overlay (exits non-zero, `distribution-refused`):
(cd /tmp/assembled/engines/rust && cargo run -q -- list-formats --packs ../../packs --max-distribution public)
```

The assembled tree carries a `.goat-transformers-assembled` marker naming the
core commit it was built from. Do not commit an assembled tree; it mixes the
public core with the overlay.

## License

Apache-2.0 for this example's own files. A real overlay carries whatever terms
its contents require.
