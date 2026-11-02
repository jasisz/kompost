(module
  (memory 1)
  (func (export "main") (result i32)
    (local $x f32)
    (local.set $x (f32.div (f32.const 1) (f32.const 3)))
    (f32.store (i32.const 8) (f32.add (local.get $x) (f32.const 0.1)))
    (i32.add
      (i32.add (i32.reinterpret_f32 (f32.load (i32.const 8)))
               (i32.trunc_f32_s (f32.mul (f32.convert_i64_u (i64.const -1)) (f32.const 0x1p-40))))
      (i32.add (i32.reinterpret_f32 (f32.demote_f64 (f64.const 0.1)))
               (i32.reinterpret_f32 (f32.sqrt (f32.convert_i32_s (i32.const 16777219))))))))
