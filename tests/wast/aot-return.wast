;; A branch to a block whose end is the function's end returns what the
;; branch carries together with what lies beneath the block (found by the
;; ahead-of-time compiler on br.wast's as-return-values).
(module
  (func (export "beneath") (result i32 i64)
    (i32.const 2)
    (block (result i64) (br 0 (i32.const 1) (i64.const 7))))
  (func (export "beneath-if") (param i32) (result i32 i64)
    (i32.const 3)
    (if (result i64) (local.get 0)
      (then (br 0 (i32.const 9) (i64.const 8)))
      (else (i64.const 6)))))
(assert_return (invoke "beneath") (i32.const 2) (i64.const 7))
(assert_return (invoke "beneath-if" (i32.const 1)) (i32.const 3) (i64.const 8))
(assert_return (invoke "beneath-if" (i32.const 0)) (i32.const 3) (i64.const 6))
