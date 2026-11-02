;; expect: 42
;; A host call that runs the guest again (args_get -> __rt_string_from_lm)
;; must keep alive what the suspended caller holds: the callee allocates
;; past the collection threshold while main keeps a struct only in a local.
(module
  (type $s (struct (field i32)))
  (type $str (array (mut i8)))
  (import "aver" "args_get" (func $args_get (param i64) (result anyref)))
  (memory (export "memory") 1)
  (func (export "__rt_string_from_lm") (param $n i32) (result (ref $str))
    (local $i i32)
    (loop $l
      (drop (struct.new $s (local.get $i)))
      (local.set $i (i32.add (local.get $i) (i32.const 1)))
      (br_if $l (i32.lt_u (local.get $i) (i32.const 70000))))
    (array.new_default $str (local.get $n)))
  (func (export "main") (result i32) (local $keep (ref null $s))
    (local.set $keep (struct.new $s (i32.const 42)))
    (drop (call $args_get (i64.const 0)))
    (struct.get $s 0 (local.get $keep))))
