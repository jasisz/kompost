<p align="center"><img src="assets/logo.svg" width="160" alt="Kompost"></p>

# Kompost

A WebAssembly interpreter written in [Aver](https://github.com/jasisz/aver), a
language with no loops, no `if` and no mutation: everything here is `match`,
recursion and persistent data, compiled to native code by Aver's Rust backend.

Kompost implements the WebAssembly 3.0 core: GC (structs, arrays, i31,
subtyping, casts, iso-recursive type canonicalization), typed function
references, tail calls, exception handling, multiple memories, memory64 and
table64, SIMD and relaxed SIMD, bulk memory and tables, with a full
validator and a strict binary decoder. It runs the output of
`aver compile --target wasm-gc` with the host imports Aver's programs use.

## Status

Checked against the official spec testsuite with `bin/wast`, which compares
every result bit for bit (NaN classes and v128 lanes included):

| | passed | failed |
|---|---|---|
| core and GC testsuite (114 files) | 19 609 | 37 |
| SIMD and relaxed SIMD (66 files) | 25 073 | 0 |
| memory64, multi-memory, exceptions, bulk, … (the other 94 files) | 16 498 | 580 |

Every remaining failure needs **linking**: a module importing a function, memory,
table, global or tag that another module exports. Kompost instantiates one
module at a time; host imports come from Kompost itself (`spectest`, Aver's
`aver.*`).

Not supported: linking several modules, threads and atomics (not part of
3.0), the legacy exception instructions, Aver host imports beyond console,
arguments and reading files.

**Speed.** Kompost resolves control flow before running and fuses frequent
instruction sequences, but it is an interpreter written in a language
without mutable arrays: about 35–40 ns per instruction, roughly 60 times
slower than Wasmtime on the same module. It is meant as an independent
implementation to check other engines and compilers against, not as a fast
runtime.

## Building

Kompost needs Aver at the commit in `.aver-commit`, and a Rust toolchain.

```
git clone https://github.com/jasisz/aver ../aver
(cd ../aver && git checkout $(cat ../kompost/.aver-commit))
cargo install --path ../aver --features wasm --root .aver-tool
AVER_REPO=../aver bin/fetch-rt    # the Aver runtime crate at that commit
bin/build                         # → .build/target/release/kompost
```

## Running

```
kompost FILE.wasm [ARGS...]              # runs _start; ARGS are the program's arguments
kompost --invoke NAME FILE.wasm [ARGS]   # one export, prints its results
kompost --validate FILE.wasm             # decode and validate only
kompost --script FILE.wasm SCRIPT        # invocations from SCRIPT on one instance (used by bin/wast)
```

The same runs on Aver's VM: `aver run src/main.av --module-root src -- FILE.wasm`.

## Tests

- `aver verify src/main.av --module-root src` — examples and laws attached to
  every function (about 1 300 cases).
- `bin/wast FILE.wast|NAME…` — spec tests through `wasm-tools json-from-wast`
  (needs `wasm-tools`; names are looked up in `SPEC_DIR`). Each module's
  invocations run on one instance and every value is compared exactly;
  `assert_invalid` and `assert_malformed` modules must be refused.
- `bin/wattest` — hand-written `tests/wat/*.wat` against Wasmtime.
- `bin/difftest` — `tests/av/*.av` compiled to wasm-gc, run by Wasmtime and by
  Kompost; output must match.
- `bin/spec` — the testsuite replayed by
  [miscast](https://github.com/jasisz/miscast) with Wasmtime as the oracle.
- `bin/pestka` — a larger wasm-gc program (Pestka, a Lean export checker
  written in Aver) run in Kompost against its native build.
- `bin/guard CMD` — runs a command under a memory limit for its whole process
  tree (`GUARD_GB`, default 6); the test scripts above are worth running
  under it.
- `bin/profile FILE.wasm [ARGS]` — builds a counting copy of Kompost and prints
  the most dispatched instructions, pairs and triples.

## Layout

| module | what |
|---|---|
| `src/bin.av` | octets, strict LEB128 by width, UTF-8 names |
| `src/ast.av` | the decoded module and its instructions |
| `src/decode.av` | binary format → `Ast.Module` |
| `src/canon.av` | iso-recursive type canonicalization |
| `src/valid.av` | the validator; also measures each body's stack heights |
| `src/value.av` | run-time values |
| `src/num.av` | scalar numeric instructions, traps and float bit patterns |
| `src/simd.av` | SIMD and relaxed SIMD on a v128 held as one 128-bit number |
| `src/mem.av` | linear memory as pages of words |
| `src/arr.av` | GC array storage, packed for i8 and i16 elements |
| `src/exec.av` | resolution of control flow, instruction fusion and the machine |
| `src/kompost.av` | the heap and its garbage collector |
| `src/main.av` | command line and host imports |

## License

MIT, see `LICENSE`.
