(load "../common/utils.scm")
(load "../common/test-utils.scm")

(load "./exercise_2_97_setup.scm")

(let* ((t1 (make-tl-from-cseq-num
             'poly-termlist-sparse
             1 2 3))
       (t2 (make-tl-from-cseq-num
             'poly-termlist-sparse
             1 -1))
       (t3 (make-tl-from-cseq-num
             'poly-termlist-sparse
             2 -3 5 -7))
       (t4 (make-tl-from-cseq-num
             'poly-termlist-sparse
             8 -6 4 -2 0))
       (t5 (mul t1 (mul t2 t3)))
       (t6 (mul t1 (mul t2 t4))))
  (define to-poly ((curry2 make-poly) 'x))
  (define out-poly (compose out to-string))
  (let* ((p1 (to-poly t5))
         (p2 (to-poly t6))
         (reduce-result (reduce p1 p2))
         (pp1 (car reduce-result))
         (pp2 (cadr reduce-result)))
    (out "p1")
    (out-poly p1)
    (out "p2")
    (out-poly p2)
    (out "reduced p1")
    (out-poly pp1)
    (out "reduced p2")
    (out-poly pp2)))

(let ((a (make-scheme-number 10))
      (b (make-scheme-number 40)))
  (out (reduce a b)))

(end-script)
