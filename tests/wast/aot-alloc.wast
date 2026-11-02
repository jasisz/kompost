;; Allocation in compiled code: each struct.new must write the heap in place.
;; A store held twice would copy a chunk of the heap at every allocation.
(module
  (type $cell (struct (field i32) (field (ref null $cell))))
  (func (export "chain") (param $n i32) (result i32)
    (local $i i32) (local $c (ref null $cell))
    (block $done
      (loop $next
        (br_if $done (i32.ge_u (local.get $i) (local.get $n)))
        (local.set $c (struct.new $cell (local.get $i) (ref.null $cell)))
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $next)))
    (struct.get $cell 0 (local.get $c))))
(assert_return (invoke "chain" (i32.const 300000)) (i32.const 299999))
