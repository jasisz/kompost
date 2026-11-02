;; Linking that needs one store shared by all instances.

;; GC objects cross instances; casts compare types across modules iso-recursively.
(module $A
  (type $s (struct (field i32)))
  (func (export "make") (result anyref) (struct.new $s (i32.const 7)))
  (func (export "get") (param anyref) (result i32)
    (struct.get $s 0 (ref.cast (ref $s) (local.get 0)))))
(register "A" $A)
(module $B
  (type $s (struct (field i32)))
  (type $t (struct (field i64)))
  (import "A" "make" (func $make (result anyref)))
  (import "A" "get" (func $get (param anyref) (result i32)))
  (func (export "roundtrip") (result i32) (call $get (call $make)))
  (func (export "test_s") (result i32) (ref.test (ref $s) (call $make)))
  (func (export "test_t") (result i32) (ref.test (ref $t) (call $make)))
  (func (export "read") (result i32) (struct.get $s 0 (ref.cast (ref $s) (call $make)))))
(assert_return (invoke $B "roundtrip") (i32.const 7))
(assert_return (invoke $B "test_s") (i32.const 1))
(assert_return (invoke $B "test_t") (i32.const 0))
(assert_return (invoke $B "read") (i32.const 7))

;; Calling back into an instance that is waiting on its own call.
(module $E
  (type $v (func))
  (table (export "tab") 1 funcref)
  (global $g (export "eg") (mut i32) (i32.const 0))
  (func (export "set") (global.set $g (i32.const 5)))
  (func (export "run") (result i32)
    (call_indirect (type $v) (i32.const 0))
    (global.get $g)))
(register "E" $E)
(module $F
  (import "E" "tab" (table 1 funcref))
  (import "E" "set" (func $set))
  (func $cb (call $set))
  (elem (i32.const 0) $cb))
(assert_return (invoke $E "run") (i32.const 5))

;; Two imports of one global are one global.
(module $G (global (export "g") (mut i32) (i32.const 0)))
(register "G" $G)
(module $H
  (global $a (import "G" "g") (mut i32))
  (global $b (import "G" "g") (mut i32))
  (func (export "alias") (result i32) (global.set $a (i32.const 3)) (global.get $b)))
(assert_return (invoke $H "alias") (i32.const 3))

;; A function of another instance called through a table checks its type.
(module $I
  (type $ii (func (param i32) (result i32)))
  (func $inc (export "inc") (type $ii) (i32.add (local.get 0) (i32.const 1)))
  (table (export "t") 1 funcref)
  (elem (i32.const 0) $inc))
(register "I" $I)
(module $J
  (type $ii (func (param i32) (result i32)))
  (type $v (func))
  (import "I" "t" (table 1 funcref))
  (func (export "ok") (result i32) (call_indirect (type $ii) (i32.const 41) (i32.const 0)))
  (func (export "bad") (call_indirect (type $v) (i32.const 0))))
(assert_return (invoke $J "ok") (i32.const 42))
(assert_trap (invoke $J "bad") "indirect call type mismatch")
