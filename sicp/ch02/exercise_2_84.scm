(load "../common/utils.scm")

; * we need to describe the linear relationship of types
;   so we'll be able to compare the type levels
; * after we come up with the comparator, we'll modify the apply-generic
;   for the final target:
;   * get a list of types
;   * pick up the highest type in the type list
;   * every argument needs to be raised to be of that type
;   * we don't need to raise beyond the highest one

(load "./4_3_data_directed_put_get.scm")
(load "./exercise_2_83_num_all.scm")

; type comparison
(load "./exercise_2_84_type_cmp.scm")

; installation
(define (add a b)
  (apply-generic 'add a b))

(define (sub a b)
  (apply-generic 'sub a b))

(define (raise x)
  (apply-generic 'raise x))

(install-integer-package)
(install-rational-package)
(install-real-package)
(install-complex-package)

(define make-integer (get 'make 'integer))
(define make-rational (get 'make 'rational))
(define make-real (get 'make 'real))
(define make-complex (get 'make 'complex))

; raise to a higher type for data (currying)
(define (raise-to type)
  (lambda (data)
    (let ((data-type (type-tag data)))
      (cond ((equal? type data-type) data)
            ((higher-type? type data-type)
             ((raise-to type) (raise data)))
            (else (error "no way to raise downwards: RAISE-TO"))))))

; pick up the highest type in the list
(define (highest-type ls)
  (fold-left
    (lambda (cur-highest cur-type)
      (if (higher-type? cur-type cur-highest)
        cur-type
        cur-highest))
    (car ls)
    (cdr ls)))

(define (apply-generic op . args)
  (define (raise-and-apply op args)
    (let* ((type-list (map type-tag args))
           (data-list (map contents args))

           (type-target (highest-type type-list))
           (new-type-list (map (const type-target) type-list))
           (raised-data (map (raise-to type-target) args))
           (proc (get op new-type-list)))
      (if proc
        (apply proc (map contents raised-data))
        (error "No method for thest types: APPLY-GENERIC"
               (list op args)))))

  (let ((type-list (map type-tag args))
        (data-list (map contents args)))
    (let ((proc (get op type-list)))
      (if proc
        (apply proc data-list)
        ; else try to raise all types and look for a procedure again
        (raise-and-apply op args)))))

; gradually raise to the complex type
(let* ((result1 (add (make-integer 1)
                     (make-rational 1 2)))
       (result2 (add result1
                     (make-real 0.25)))
       (result3 (add (make-complex 0.125 0.125)
                     result2)))
  (out result1 ; 1 + 1/2 => 3/2
       result2 ; 3/2 + 0.25 => 1.75
       result3 ; 0.125 + 0.125i + 1.75 => 1.875 + 0.125i
       ))

(end-script)
