(module
  (func (export "main") (result i64 i64 i64)
    (i64.shr_s (i64.const -8) (i64.const 70))
    (i64.div_u (i64.const -1) (i64.const 2))
    (i64.clz (i64.const 1))
    (drop) (drop) (drop)
    (i64.rem_s (i64.const -9) (i64.const 8))
    (i64.shr_u (i64.const -1) (i64.const 1))
    (i64.popcnt (i64.const 0x7fffffffffffffff))))
