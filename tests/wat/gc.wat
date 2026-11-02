(module
  (type $pt (sub (struct (field (mut i32)))))
  (type $pt3 (sub $pt (struct (field (mut i32)) (field i32))))
  (type $bytes (array (mut i8)))
  (func $kind (param anyref) (result i32)
    (block $is3 (result (ref $pt3))
      (block $ispt (result (ref $pt))
        (br_on_cast $is3 anyref (ref $pt3) (local.get 0))
        (br_on_cast $ispt anyref (ref $pt))
        (drop) (return (i32.const 0)))
      (drop) (return (i32.const 1)))
    (drop) (i32.const 2))
  (func (export "main") (result i32) (local $a (ref null $bytes)) (local $s (ref null $pt))
    (local.set $a (array.new $bytes (i32.const 200) (i32.const 3)))
    (array.set $bytes (local.get $a) (i32.const 1) (i32.const 300))
    (local.set $s (struct.new $pt3 (i32.const 5) (i32.const 6)))
    (struct.set $pt 0 (local.get $s) (i32.const 50))
    ;; get_s 200 -> -56 ; get_u 300&255 = 44 ; len 3 ; field 50 ; kinds 2+1+0 ; i31 -1 get_u
    (i32.add
      (i32.add
        (i32.add (array.get_s $bytes (local.get $a) (i32.const 0))
                 (array.get_u $bytes (local.get $a) (i32.const 1)))
        (i32.add (array.len (local.get $a)) (struct.get $pt 0 (local.get $s))))
      (i32.add
        (i32.add (call $kind (local.get $s))
          (i32.add (call $kind (struct.new $pt (i32.const 0)))
                   (call $kind (ref.i31 (i32.const 9)))))
        (i32.add (i32.const 76)
          (i32.sub (i31.get_u (ref.i31 (i32.const -1))) (i32.const 2147483647)))))))
