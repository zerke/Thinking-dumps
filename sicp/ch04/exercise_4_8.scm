(load "../common/utils.scm")
(load "../common/test-utils.scm")

(load "./exercise_4_5_common.scm")
(load "./exercise_4_6_common.scm")

(load "./exercise_4_8_common.scm")

(out 
  (eval-let
    '(let ((x 1)
           (y 2)
           (z 3))
       (display y)
       (newline)
       (+ x y z))
    (the-environment)))
; 2 (outputed by evaluation)
; 6 (outputed by `out`)

(out
  (eval-let
    '(let ()
       1)
    (the-environment)))
; 1

(out
  (let->combination
    '(let fib-iter ((a 1)
                    (b 0)
                    (count 10))
       (if (= count 0)
         b
         (fib-iter (+ a b) a (- count 1))))))

(end-script)
