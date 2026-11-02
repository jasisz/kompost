;; Regressions from an outside review of Kompost.

;; A trap stops the program but does not undo what it wrote before.
(module
  (global $g (mut i32) (i32.const 0))
  (memory 1)
  (func (export "write_then_trap")
    (global.set $g (i32.const 1))
    (i32.store (i32.const 0) (i32.const 7))
    unreachable)
  (func (export "read") (result i32) (global.get $g))
  (func (export "load") (result i32) (i32.load (i32.const 0))))
(assert_trap (invoke "write_then_trap") "unreachable")
(assert_return (invoke "read") (i32.const 1))
(assert_return (invoke "load") (i32.const 7))

;; A function section that declares one function and ends before its type index.
(assert_malformed
  (module binary "\00asm" "\01\00\00\00" "\03\01\01")
  "unexpected end")

;; A packed type (i8) as a function parameter: packed types are only for fields.
(assert_malformed
  (module binary "\00asm" "\01\00\00\00" "\01\05\01\60\01\78\00")
  "malformed value type")

;; Packed types stay fine where they belong.
(module binary "\00asm" "\01\00\00\00" "\01\04\01\5e\78\01")
