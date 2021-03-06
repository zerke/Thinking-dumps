;; a collection of testcases that might have side effects to the system

(define (qeval-database-tests-db)
  (qe-fresh-asserts!
   '(assert1 foo)
   '(assert1 bar)
   '(assert2 a)
   '(assert2 1 2 3 4)
   '(rule (both ?x ?y)
          (and (good ?x) (good ?y)))
   '(rule (good ?a))
   '(rule (?not ?indexable)))

  (do-test
   fetch-assertions
   (list
    ;; indexable assertions
    (mat '(assert1 (? x)) 'not-used
         '((assert1 foo) (assert1 bar)))
    (mat '(assert2 (? y) 2 3 (? z)) 'not-used
         '((assert2 a) (assert2 1 2 3 4)))
    ;; not indexable, return all assertions
    (mat '((pat pat) (foo bar)) 'not-used
         '((assert1 foo) (assert1 bar) (assert2 a) (assert2 1 2 3 4))))
   (lambda (actual expected)
     (set-equal? (stream->list actual) expected)))

  (do-test
   fetch-rules
   (list
    ;; indexable rules
    (mat '(both 'a 'b) 'not-used
         '((rule (both (? x) (? y))
                 (and (good (? x)) (good (? y))))
           (rule ((? not) (? indexable)))))
    (mat '(good 't) 'not-used
         '((rule (good (? a)))
           (rule ((? not) (? indexable)))))
    ;; not indexable, return all rules
    (mat '((not indexable)) 'not-used
         '((rule  (both (? x) (? y))
                 (and (good (? x)) (good (? y))))
           (rule (good (? a)))
           (rule ((? not) (? indexable))))))
   (lambda (actual expected)
     (set-equal? (stream->list actual) expected)))

  (qeval-initialize!)
  'ok)

(define (qeval-query-tests)
  (qeval-initialize!)

  ;; cover database queries and
  ;; pattern matching and unification
  ;; in real database queries
  (apply
   qe-fresh-asserts!
   '((lisps mit-scheme)
     (lisps racket)
     (lisps elisp)
     (lisps clojure)
     (doge wow cool)
     (doge such scheme)
     (list (a b c d) (c d e f))
     (list (a b c g) ())
     (edge a b)
     (edge b c)
     (edge c d)
     (only-a a)
     (num 1)
     (num 2)
     (num 3)
     (rule (connect ?a ?b)
           (or (edge ?a ?b)
               (and (edge ?a ?c)
                    (connect ?c ?b))))
     ))

  (do-test
   qe-all
   (list
    ;; simple query test
    (mat '(lisps ?x)
         '((lisps mit-scheme)
           (lisps racket)
           (lisps elisp)
           (lisps clojure)))
    (mat '(doge ?x)
         '())
    (mat '(doge ?x ?y)
         '((doge wow cool)
           (doge such scheme)))
    (mat '(doge ?x scheme)
         '((doge such scheme)))
    (mat '(doge wow ?y)
         '((doge wow cool)))
    (mat '(list (a b c . ?x) ?y)
         '((list (a b c d) (c d e f))
           (list (a b c g) ())))
    ;; compound query test
    (mat '(connect a ?x)
         '((connect a b)
           (connect a c)
           (connect a d)))
    ;; "or" handler
    (mat '(or (doge wow ?a)
              (edge a ?a))
         '((or (doge wow cool) (edge a cool))
           (or (doge wow b) (edge a b))))
    (mat '(or (only-a ?a) (edge ?a b))
         '((or (only-a a) (edge a b))))
    (mat '(or (no such) (an assertion))
         '())
    ;; "and" handler
    (mat '(and (doge wow ?a)
               (edge a ?a))
         '())
    (mat '(and (only-a ?a) (edge ?a b))
         '((and (only-a a) (edge a b))))
    (mat '(and (no such) (an assertion))
         '())
    ;; "not" handler
    (mat '(not (edge b c))
         '())
    (mat '(not (edge a d))
         '((not (edge a d))))
    ;; "lisp-value" handler
    (mat '(and (num ?a) (num ?b)
               (lisp-value < ?a ?b))
         '((and (num 1) (num 2)
                (lisp-value < 1 2))
           (and (num 2) (num 3)
                (lisp-value < 2 3))
           (and (num 1) (num 3)
                (lisp-value < 1 3))))
    ;; "always-true" handler
    (mat '(always-true)
         '((always-true)))
    (mat '(and (always-true) (num ?a))
         '((and (always-true) (num 1))
           (and (always-true) (num 2))
           (and (always-true) (num 3))))
    ;; "lisp-eval" handler
    (mat '(lisp-eval (lambda (l)
                       (map (lambda (x) (* x 3))
                            l))
                     (?x . ?y)
                     (1 2 3 4))
         '((lisp-eval (lambda (l)
                        (map (lambda (x) (* x 3))
                             l))
                      (3 6 9 12)
                      (1 2 3 4))))
    (mat '(lisp-eval (lambda ()
                       (cons 1 2))
                     (?x ?y))
         '())
    )
   set-equal?)

  (qeval-initialize!))

(define (qeval-tests)
  (qeval-database-tests-db)
  (qeval-query-tests)
  'ok)

(if *qeval-tests*
    (qeval-tests)
    'ok)

;; Local variables:
;; proc-entry: "./qeval.scm"
;; End:
