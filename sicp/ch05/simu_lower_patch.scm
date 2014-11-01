;; in the original simu.scm,
;; we can store anything we like in a register
;; and don't pay much attention when it comes to
;; pairs and storage.
;; this patch puts the machine to a "lower" level:
;; we now only keep value of basic types in a register
;; and on the stack, pairs will be represented in memory
;; and as "pointers".

(load "./simu.scm")

(define (make-primitive-exp exp m)
  (define (constant-exp? exp)
    (tagged-list? exp 'const))
  (define (valid-constant data)
    ;; now data can only be one of:
    ;; symbol, number, boolean, string, char or null
    (or (symbol? data)
        (number? data)
        (boolean? data)
        (string? data)
        (char? data)
        (null? data)))
  (define (constant-exp-value exp)
    (let ((data (cadr exp)))
      (if (valid-constant data)
          data
          (error "cannot use" data
                 "as a constant"))))

  (cond ((constant-exp? exp)
         (let ((c (constant-exp-value exp)))
           (lambda () c)))
        ((label-exp? exp)
         (lambda ()
           (machine-lookup-label
            m (label-exp-label exp))))
        ((register-exp? exp)
         (let ((r (machine-find-register
                   m (register-exp-reg exp))))
           (lambda () (register-get r))))
        (else
         (error "unexpected expression:" exp))))

(define (machine-define-registers! m regs-all)
  (define regs
    (remove-duplicates
     `(,@machine-reserved-registers ,@regs-all)))

;; a list of registers that must be
;; present in a machine
(define machine-reserved-registers
  '(pc flag the-cars the-cdrs))

;; make a machine pointer
;; that represents a "memory location"
(define (machine-pointer n)
  (cons 'ptr n))

;; check if the data is a machine pointer
(define (machine-pointer? data)
  (and (pair? data)
       (eq? (car data) 'ptr)
       (integer? (cdr data))))

(define default-ops-builder
  (let ((old-builder default-ops-builder))
    (lambda (m)
      `(;; TODO: vector-ref and vector-set!
        ,@(old-builder m)))))
