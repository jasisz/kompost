;; A loop long enough that compiled code is plainly faster than interpreted:
;; bin/aot's builds are checked to run their compiled functions with it.
(module
  (func (export "count") (param $n i32) (result i32)
    (local $i i32) (local $acc i32)
    (block $done
      (loop $next
        (br_if $done (i32.ge_u (local.get $i) (local.get $n)))
        (local.set $acc (i32.add (local.get $acc) (i32.xor (local.get $i) (i32.const 7))))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $next)))
    (local.get $acc))
  (func (export "fib") (param $n i64) (result i64)
    (if (result i64) (i64.lt_s (local.get $n) (i64.const 2))
      (then (local.get $n))
      (else (i64.add (call 1 (i64.sub (local.get $n) (i64.const 1)))
                     (call 1 (i64.sub (local.get $n) (i64.const 2))))))))
(assert_return (invoke "count" (i32.const 20000000)) (i32.const 542894464))
(assert_return (invoke "fib" (i64.const 30)) (i64.const 832040))
