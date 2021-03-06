;; eaa: extended argument annotation

;; (define-eaa <proc-arg-list> <body>)
(define define-eaa-proc-arg-list cadr)

(define define-eaa-proc-name
  (compose
   car
   define-eaa-proc-arg-list))

;; proc argument list with extended annotation
(define define-eaa-args-extended
  (compose
   cdr
   define-eaa-proc-arg-list))

(define (define-eaa-args exp)
  (map (lambda (e)
         (if (list? e)
             (car e)
             e))
         (define-eaa-args-extended exp)))

(define define-eaa-body cddr)

(define (install-eval-define-eaa)

  ;; structure:
  ;; (list 'proc-eaa <annotations> <proc>)
  ;; annotations: (list (list <var-name> <call-strategy>))
  ;; var-name: symbol
  ;; call-strategy: 'call-by-value 'call-by-name 'call-by-need
  ;; proc: a lambda
  (define (define-eaa->define exp)
    (let ((proc-name
           (define-eaa-proc-name exp))
          (proc-args
           (define-eaa-args exp))
          (proc-argsx
           (define-eaa-args-extended exp))
          (proc-body
           (define-eaa-body exp)))
      ;; build up annotation here
      (define (var-spec->annotation var-spec)
        (cond ((symbol? var-spec)
               (list var-spec 'call-by-value))
              ((and (non-empty? var-spec)
                    (list? var-spec)
                    (= (length var-spec) 2))
               (list (car var-spec)
                     (case (cadr var-spec)
                       ((lazy) 'call-by-name)
                       ((lazy-memo) 'call-by-need)
                       (else (error "ill-formed var-spec"
                                    var-spec)))))
              (else
               (error "ill-formed var-spec"
                      var-spec))))
      (let ((annotations
             (map var-spec->annotation
                  proc-argsx)))
        `(define ,proc-name
           (list 'proc-eaa
                 (quote ,annotations)
                 ,(make-lambda
                   proc-args
                   proc-body))))))

  (define (eval-define-eaa exp env)
    (my-eval (define-eaa->define exp) env))

  (define (analyze-define-eaa exp)
    (my-analyze (define-eaa->define exp)))

  (define (test-eval eval-define-eaa)

    (define sample-1
      `(define-eaa (f1 a (b lazy) c (d lazy-memo))
         (+ a (b) c (force d))))

    (define sample-2
      `(define-eaa (f2 a (b lazy) (c lazy-memo))
         (- a (b) (force c))))

    ;; we know the underlying structure,
    ;; so we just manipulate on the structure here.

    (define call-sample-1
      `((car (cdr (cdr f1)))
        1                ; a
        (lambda () 2)    ; b lazy
        3                ; c
        (delay 4)        ; d lazy-memo
        ))

    (define call-sample-2
      `((car (cdr (cdr f2)))
        10               ; a
        (lambda () 8)    ; b lazy
        (delay 3)        ; c lazy-memo
        ))

    (define env (init-env))
    ;; put stuffs into env

    (eval-define-eaa sample-1 env)
    (eval-define-eaa sample-2 env)

    (do-test
     my-eval
     (list
      (mat call-sample-1 env 10)  ; 1+2+3+4
      (mat call-sample-2 env -1)  ; 10-8-3
      ))

    'ok)

  (define handler
    (make-handler
     'define-eaa
     eval-define-eaa
     analyze-define-eaa
     (test-both
      test-eval
      eval-define-eaa
      analyze-define-eaa)))

  (handler-register! handler)
  'ok)

(define (install-eval-call-eaa)

  (define call-eaa-proc-exp cadr)
  (define call-eaa-arg-exps cddr)

  ;; we can not make decision about
  ;; how to do the transformation until
  ;; we evaluate the proc and get back the spec
  (define (call-eaa->proc-app exp env)

    ;; this auxiluary function
    ;; uses the annotation to do the transformation
    ;; on the argument expressions, and then
    ;; evaluate each transformed expressions
    ;; so they will be ready to be applied.
    (define (annot-argexp->transformed
             annot argexp)
      (case (cadr annot)
        ((call-by-value) argexp)
        ((call-by-name) `(lambda () ,argexp))
        ((call-by-need) `(delay ,argexp))
        (else (error "unknown annotation:"
                     annot))))

    (let ((proc-exp (call-eaa-proc-exp exp))
          (arg-exps (call-eaa-arg-exps exp)))
      (let ((proc-val (my-eval proc-exp env)))
        (if (and (list? proc-val)
                 (= (length proc-val) 3)
                 (eq? (car proc-val) 'proc-eaa))
            ;; if call-eaa is called on the right structure
            (let ((wrapped-proc (caddr proc-val))
                  (annotations  (cadr  proc-val)))
              (let ((transformed-arg-exps
                     (map annot-argexp->transformed
                          annotations
                          arg-exps)))
                (let ((transformed-args
                       (map (lambda (exp)
                              (my-eval exp env))
                            transformed-arg-exps)))
                  (my-apply wrapped-proc transformed-args))))
            ;; otherwise, the structure is invalid
            (error "invalid data for call-eaa:"
                   exp)))))

  (define (eval-call-eaa exp env)
    (call-eaa->proc-app exp env))

  (define (analyze-call-eaa exp)
    (lambda (env)
      (call-eaa->proc-app exp env)))

  (define (test-eval eval-call-eaa)
    ;; we use the same example used in `define-eaa`
    ;; but `call-eaa` will take care of the transformation
    (define env (init-env))

    (define sample-1
      `(define-eaa (f1 a (b lazy) c (d lazy-memo))
         (+ a (b) c (force d))))

    (define sample-2
      `(define-eaa (f2 a (b lazy) (c lazy-memo))
         (- a (b) (force c))))

    (my-eval sample-1 env)
    (my-eval sample-2 env)

    (do-test
     eval-call-eaa
     (list
      (mat `(call-eaa f1 1 2 3 4) env 10)
      (mat `(call-eaa f2 10 8 3) env -1)
      ))

    'ok)

  (define handler
    (make-handler
     'call-eaa
     eval-call-eaa
     analyze-call-eaa
     (test-both
      test-eval
      eval-call-eaa
      analyze-call-eaa)))

  (handler-register! handler)
  'ok)

;; Local variables:
;; proc-entry: "./exercise_4_31.scm"
;; End:
