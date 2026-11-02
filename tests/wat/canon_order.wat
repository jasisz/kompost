;; Same members in a different order are different types: the cast traps.
(module
  (rec (type $p (struct (field (ref null $q)))) (type $q (struct (field i64))))
  (rec (type $q2 (struct (field i64))) (type $p2 (struct (field (ref null $q2)))))
  (func (export "main") (result i32)
    (drop (ref.cast (ref $p2) (struct.new $p (ref.null $q))))
    (i32.const 1)))
