<p align="center"><img src="assets/logo.svg" width="160" alt="Kompost"></p>
<p align="center"><a href="https://github.com/jasisz/aver"><img src="https://img.shields.io/badge/written%20in-Aver-6b4f9e" alt="Written in Aver"></a></p>

# Kompost

A WebAssembly interpreter written in [Aver](https://github.com/jasisz/aver), a
language with no loops, no `if` and no mutation: everything here is `match`,
recursion and persistent data, compiled to native code by Aver's Rust backend.

Kompost implements the WebAssembly 3.0 core: GC (structs, arrays, i31,
subtyping, casts, iso-recursive type canonicalization), typed function
references, tail calls, exception handling, multiple memories, memory64 and
table64, SIMD and relaxed SIMD, bulk memory and tables, with a full
validator, a strict binary decoder and linking of several modules. It runs the output of
`aver compile --target wasm-gc` with the host imports Aver's programs use.

## Status

Checked against the official spec testsuite with `bin/wast`, which compares
every result bit for bit (NaN classes and v128 lanes included) and counts a
crash, a timeout or a killed process as an error, never as a pass:

| | passed | failed |
|---|---|---|
| core and GC testsuite (114 files) and Kompost's own `tests/wast` | 20 092 | 0 |
| SIMD and relaxed SIMD (66 files) | 25 073 | 0 |
| memory64, multi-memory, exceptions, bulk, linking, … (the other 94 files) | 17 186 | 0 |

Linking works the way the specification defines it: every instance lives in
one store, and an instance maps its own indices to store addresses, so an
import is the exporting instance's very object. GC objects, function
references and exceptions cross instances, casts compare types across
modules iso-recursively, and an instance can be called back into while it
waits on a call it made. A call into another instance stops the machine like
a call to the host and runs the callee on the same store.

Not supported: threads and atomics (not part of 3.0), the legacy exception
instructions, Aver host imports beyond console, arguments and reading files.

**Speed.** Kompost resolves control flow before running and fuses frequent
instruction sequences, but it is an interpreter written in a language
without mutable arrays: about 35–40 ns per instruction, roughly 60 times
slower than Wasmtime on the same module. It is meant as an independent
implementation to check other engines and compilers against, not as a fast
runtime. For speed there is ahead-of-time compilation, below.

## Ahead-of-time compilation

`bin/aot FILE.wasm...` compiles a module's functions to Aver (`kompost
--compile`, written in Aver like the rest) and builds a Kompost with them
native. The compiled module replaces `src/native.av` in a copy of the
sources; a binary built this way runs those modules with their compiled
functions and everything else interpreted, and any other module it is given
entirely interpreted, as it recognises modules by their octets.

The operand stack and the locals turn into named values, i32 and i64 into
machine words, the rest into Kompost's values; every block a branch targets,
every if and every loop becomes a function of its own, taking only the
locals live there. The store is threaded through and written in place.
Instructions the compiler does not write out (the rarer GC, table and memory
instructions) run through the interpreter one at a time, so their meaning is
written once. A function is compiled when its every instruction is one the
compiler handles and every function it calls is compiled too; the
interpreter hands a compiled function over the way it hands an import to the
host, and compiled code calls back into the interpreter for one that is not.
Indirect calls (`call_ref`, `call_indirect`) are compiled only in a module
that imports nothing but Aver's host functions and exports no table, global
or function taking a function reference, so no other instance can hand it a
function; exceptions and SIMD stay interpreted.

Compiled code is checked as the interpreter is: the spec testsuite's core,
GC, reference, table and indirect-call files (about 18 000 cases) run with
every module they define compiled, with the same results bit for bit. What
it gains depends on what a program spends its time on:

| program | interpreted | compiled |
|---|---|---|
| fib(32) from Aver's wasm-gc output | 5.6 s | 0.27 s |
| a loop of 200 000 i32 loads and stores, 20 passes | 1.04 s | 0.30 s |
| Pestka on a small Lean export (GC data, hashing) | 5.0 s | 1.7 s |

A program dominated by dispatch gains most; one dominated by GC data gains
least, since compiled code keeps Kompost's heap and values. Building is
slow: Pestka's 2 900 functions become about 146 000 lines of Aver and take
several minutes of rustc and some gigabytes of memory.

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
kompost --script SCRIPT                  # a spec-test script: module, register, invoke (used by bin/wast)
```

The same runs on Aver's VM: `aver run src/main.av --module-root src -- FILE.wasm`.

## Tests

- `aver verify src/main.av --module-root src` — examples and laws attached to
  every function (about 1 300 cases).
- `bin/wast FILE.wast|NAME…` — spec tests through `wasm-tools json-from-wast`
  (needs `wasm-tools`; names are looked up in `SPEC_DIR`). A whole file runs
  as one script in one Kompost process, modules linked as the file registers
  them, and every value is compared exactly; `assert_invalid` and
  `assert_malformed` modules must be refused by Kompost itself, not by a
  crash. `tests/wast/review.wast` holds regressions from an outside review,
  `tests/wast/linking.wast` what linking in one store has to get right.
- `bin/wattest` — hand-written `tests/wat/*.wat` against Wasmtime.
- `bin/difftest` — `tests/av/*.av` compiled to wasm-gc, run by Wasmtime and by
  Kompost; output must match.
- `bin/spec` — the testsuite replayed by
  [miscast](https://github.com/jasisz/miscast) with Wasmtime as the oracle.
- `bin/pestka` — a larger wasm-gc program (Pestka, a Lean export checker
  written in Aver) run in Kompost against its native build.
- `bin/aot FILE.wasm...` — a Kompost with these modules compiled ahead of time
  (see above); `KOMPOST=` that binary with `bin/wast` runs the spec files
  whose modules were compiled. `tests/wast/aot-*.wast` hold what compiled
  code once got wrong, and loops long enough to tell compiled from
  interpreted.
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
| `src/link.av` | several instances in one store: imports checked and linked, calls and exceptions between instances |
| `src/aot.av` | the ahead-of-time compiler: a module's functions as an Aver module |
| `src/rt.av` | what compiled code calls at run time: machine words, the heap, indirect calls, the interpreter |
| `src/native.av` | the compiled functions; this copy has none, bin/aot replaces it |
| `src/types.av` | types compared across modules (iso-recursive identity, subtyping) |
| `src/main.av` | command line and host imports |

## License

MIT, see `LICENSE`.
