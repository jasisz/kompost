(module (type $s (struct)) (type $t (struct (field i32)))
  (func (export "main") (result i32) (drop (ref.cast (ref $t) (struct.new $s))) (i32.const 0)))
