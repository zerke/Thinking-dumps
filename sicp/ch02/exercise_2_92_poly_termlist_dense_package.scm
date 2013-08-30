(define (install-poly-termlist-dense-package)
  (define (make-empty) nil)
  (define empty-termlist? null?)

; (make-from-args order1 coeff1 order2 coeff2 ...)
  (define (make-from-args . args)
    (define (list-to-pair-list ls)
      (cond ((null? ls) '())
            ((>= (length ls) 2)
              (cons 
                (cons (car ls) (cadr ls))
                (list-to-pair-list (cddr ls))))
            (else
              (error "invalid list length"))))
    (define (pair-to-term p)
      ((get 'make 'poly-term) (car p) (cdr p)))

    (let ((terms (map pair-to-term
                      (list-to-pair-list args))))
      (fold-right adjoin-term
                 (make-empty)
                 terms)))

  (define (first-term-order ls) (- (length ls) 1))
  (define (first-term ls)
    ; to obtain a term, we should combine the coeff with its order
    (let ((term-order (first-term-order ls))
          (term-coeff (car ls)))
      ((get 'make 'poly-term) term-order term-coeff)))
  (define (rest-terms ls)
    (drop-while =zero? (cdr ls)))

  (define (adjoin-term term termlist)
    (let ((const-zero (const (make-scheme-number 0)))
          (t-coeff (coeff term))
          (t-order (order term)))
      (cond
        ; case #1: the term is zero
        ;   nothing to do
        ((=zero? t-coeff) termlist)
        ; + precond: term is non-zero
        ; case #2: the term list is empty
        ;   make a placeholder list of length {t-order}
        ;   e.g. to insert a term of order=3, coeff=x we need an empty list (0 0 0)
        ;         after that we simply put x in front of this list and produce (x 0 0 0)
        ((empty-termlist? termlist)
              (cons t-coeff
                    (map const-zero (list-in-range 1 t-order))))
        ; + precond: termlist is non-empty
        (else
          (let ((ft-order (first-term-order termlist)))
            ; case #3:
            ;   assume we are inserting a term into an empty list,
            ;   we need a place-holder list of length {t-order}
            ;   now we already have a list of length {ft-order + 1}
            ;   when t-order >= ft-order + 1, we need extra spaces for padding (including zero)
            (if (>= t-order (+ ft-order 1))
              (cons t-coeff
                    (append (map const-zero (list-in-range 1 (- t-order (+ ft-order 1))))
                            termlist))
              ; else we simple find the corresponding position and add coeff to it
              ; * note it's possible in this case 
              ;   that the rule of non-zero first term might be violated,
              ;   so we will try to remove leading zeros when the merge is done
              (drop-while
                =zero?
                (if (= t-order ft-order)
                  ; case #4: t-order = ft-order
                  (adjoin-term (add term (first-term termlist))
                               (rest-terms termlist))
                  ; case #5: t-order < ft-order
                  ; this part was affected by new rest-terms
                  ; TODO: try to find a better impl
                  (list-modify termlist 
                               (- ft-order t-order)
                               (add (list-ref termlist (- ft-order t-order))
                                    t-coeff))))))))))

  (define (list-modify ls ind val)
    (if (= ind 0)
      (cons val (cdr ls))
      (cons (car ls) (list-modify (cdr ls) (- ind 1) val))))

  (define termlist-equ?
    ((get 'termlist-equ?-maker 'poly-generic)
     first-term
     rest-terms
     empty-termlist?))

  (define add-terms
    ((get 'add-terms-maker 'poly-generic)
     first-term
     rest-terms
     empty-termlist?
     adjoin-term))

  (define mul-term-by-all-terms
    ((get 'mul-term-by-all-terms-maker 'poly-generic)
     first-term
     rest-terms
     empty-termlist?
     make-empty
     adjoin-term))

  (define mul-terms
    ((get 'mul-terms-maker 'poly-generic)
      first-term
      rest-terms
      empty-termlist?
      make-empty
      add-terms
      mul-term-by-all-terms))

  (define neg-terms
    ((get 'neg-terms-maker 'poly-generic)
     mul-term-by-all-terms))

  (define sub-terms
    ((get 'sub-terms-maker 'poly-generic)
     add-terms
     neg-terms))

  (define (test)
    ((get 'test-poly-termlist 'poly-generic)
     'poly-termlist-dense
     make-empty
     make-from-args
     first-term
     rest-terms
     adjoin-term
     add-terms
     sub-terms
     mul-term-by-all-terms
     mul-terms
     empty-termlist?
     termlist-equ?)
    (let* ((make-term (get 'make 'poly-term))
           (gen-empty-list (lambda (len) (map (const (make-scheme-number 0))
                                              (list-in-range 1 len))))
           (to-termlist ((curry2 map) make-scheme-number))
           )
      ; test accessors
      (let ((testcases
              (list (mat (to-termlist (list 1 0 2 3 4))
                         ; result: (cons <first-term-result> <rest-terms-result>)
                         (cons (make-term 4 (make-scheme-number 1))
                               (to-termlist (list 2 3 4))))
                    (mat (to-termlist (list 1 0 0 0 0 0 0 0))
                         (cons (make-term 7 (make-scheme-number 1))
                               nil))
                    ))
            (f (lambda (x) (cons (first-term x) (rest-terms x))))
            (result-eq?
              (lambda (a b)
                (and (equ? (car a) (car b)) 
                     (= (length (cdr a)) (length (cdr b)))
                     (apply boolean/and (map equ? (cdr a) (cdr b))))))
            )
        (do-test-q f testcases result-eq?))
      ; test mul-terms
      (let ((testcases
              (list
                (mat nil nil
                     nil)
                (mat nil (to-termlist (list 1 2 3 4 5))
                     nil)
                (mat (to-termlist (list 1 2 3 4 5)) nil
                     nil)
                (mat (to-termlist (list 1 2 3)) (to-termlist (list 4 5 6))
                     ; (x^2 + 2x + 3) * (4x^2 + 5x + 6)
                     ; => 4x^4 + 13x^3 + 28^x2 + 27x + 18
                     (to-termlist (list 4 13 28 27 18)))
                (mat (to-termlist (list 5 0 0 7 0 9 0)) (to-termlist (list 2 0 4 0 0))
                     ;(5x^6 + 7x^3 + 9x) * (2x^4 + 4x^2)
                     ; => 10x^10 + 20x^8 + 14x^7 + 46x^5 + 36x^3
                     (to-termlist (list 10 0 20 14 0 46 0 36 0 0 0)))
                )))
        (do-test-q mul-terms testcases termlist-equ?))
      ; test make-from-args
      (let ((testcases
              (list
                (mat 1 (make-scheme-number 3)
                     2 (make-scheme-number 2)
                     3 (make-scheme-number 1)
                     (to-termlist (list 1 2 3 0)))
                (mat 1 (make-scheme-number 2)
                     3 (make-scheme-number 4)
                     (to-termlist (list 4 0 2 0)))
                (mat 10 (make-scheme-number 3)
                     (to-termlist (cons 3 (gen-empty-list 10))))
                )))
        (do-test-q make-from-args testcases termlist-equ?))
      ))

  (put 'make 'poly-termlist-dense (tagged 'poly-termlist-dense make-empty))
  (put 'make-from-args 'poly-termlist-dense (tagged 'poly-termlist-dense make-from-args))
  (put 'first-term '(poly-termlist-dense) first-term)
  (put 'rest-terms '(poly-termlist-dense) (tagged 'poly-termlist-dense rest-terms))
  (put 'add '(poly-termlist-dense poly-termlist-dense) (tagged 'poly-termlist-dense add-terms))
  (put 'sub '(poly-termlist-dense poly-termlist-dense) (tagged 'poly-termlist-dense sub-terms))
  (put 'mul '(poly-termlist-dense poly-termlist-dense) (tagged 'poly-termlist-dense mul-terms))
  (put 'empty? '(poly-termlist-dense) empty-termlist?)
  (put '=zero? '(poly-termlist-dense) empty-termlist?)
;  (put 'order-list '(poly-termlist-dense) order-list)
;  (put 'coeff-list '(poly-termlist-dense) coeff-list)
  (put 'equ? '(poly-termlist-dense poly-termlist-dense) termlist-equ?)
;
  (put 'test 'poly-termlist-dense-package test)

  'done)
