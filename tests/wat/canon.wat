;; Structurally identical rec groups are one type: a struct made as $a
;; casts to $b, and a function of type $fa is called through $fb.
(module
  (rec (type $a (struct (field i32) (field (ref null $a)))))
  (rec (type $b (struct (field i32) (field (ref null $b)))))
  (type $fa (func (result i32)))
  (type $fb (func (result i32)))
  (table 1 funcref)
  (elem (i32.const 0) $seven)
  (func $seven (type $fa) (i32.const 7))
  (func (export "main") (result i32)
    (i32.add
      (struct.get $b 0 (ref.cast (ref $b) (struct.new $a (i32.const 35) (ref.null $a))))
      (call_indirect (type $fb) (i32.const 0)))))
