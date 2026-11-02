(module
  (type $bin (func (param i32 i32) (result i32)))
  (table 2 funcref)
  (elem (i32.const 0) $add $mul)
  (func $add (type $bin) (i32.add (local.get 0) (local.get 1)))
  (func $mul (type $bin) (i32.mul (local.get 0) (local.get 1)))
  (func $pick (param i32) (result i32)
    (block $c (block $b (block $a
      (br_table $a $b $c (local.get 0)))
      (return (i32.const 10)))
    (return (i32.const 20)))
    (i32.const 30))
  (func $loop (param $n i32) (result i32) (local $acc i32)
    (block $done
      (loop $l
        (br_if $done (i32.eqz (local.get $n)))
        (local.set $acc (i32.add (local.get $acc) (local.get $n)))
        (local.set $n (i32.sub (local.get $n) (i32.const 1)))
        (br $l)))
    (local.get $acc))
  (func (export "main") (result i32)
    ;; 30 (pick 7 -> default) + call_indirect mul 2*3=6 + loop 1+2+3=6 = 42
    (i32.add
      (i32.add (call $pick (i32.const 7))
               (call_indirect (type $bin) (i32.const 2) (i32.const 3) (i32.const 1)))
      (call $loop (i32.const 3)))))
