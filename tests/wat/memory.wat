(module
  (memory 1 3)
  (data (i32.const 16) "\01\02\03\04")
  (func (export "main") (result i32)
    (i64.store (i32.const 100) (i64.const -2))
    (memory.copy (i32.const 200) (i32.const 16) (i32.const 4))
    ;; load 0x04030201 = 67305985 ; load8_s of 0xfe = -2 ; grow 1 -> 1 ; size 2
    (i32.add
      (i32.add (i32.load (i32.const 200)) (i32.load8_s (i32.const 100)))
      (i32.add (i32.sub (memory.grow (i32.const 1)) (i32.const 67305985))
               (i32.add (memory.size) (i32.const 1000000))))))
