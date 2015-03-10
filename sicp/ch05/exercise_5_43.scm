(load "../common/utils.scm")
(load "../common/test-utils.scm")

(load "simu_utils.scm")
(load "ec-prim.scm")
(load "exercise_5_23_common.scm")
(load "set.scm")

#|
;; what happens when we have the following expression:
(lambda (x)
  (begin
    (define y 1)
    (define z 2)
    (if (= x 0)
        (begin
          (define a 10)
          (+ x a))
        (begin
          (define b 320)
          (* x 3 b)))))

;; TODO
;; conclusion: we have to go deeper
;; until we can reach another lambda-subexpression
|#

;; based on exercise 4.16
;; only scans definitions directly appear
;; in the procedure body
;; TODO: I think we can do something recursive
;; to go into deeper internal definitions

;; to make an almost-correct local definition
;; eliminator, we basically need an sexp to sexp
;; transformer for each form of s-exp:
;; * self-evaluating?
;; * quoted?
;; * variable?
;; * assignment?
;; * definition?
;; * if?
;; * lambda?
;; * begin?
;; * cond?
;; * let? (derived form)
;; * application?
;; we shouldn't assume the derived form is expanded,
;; as the transformation might introduce s-expressions in derived
;; form which would require expansion.

;; TODO: scan-and-transform approach needs 2 traversals
;; but I think only one is necessary
;; before we try to do this traversal-fusion,
;; let's first have a correct implementation

(define (scan-and-transform-exps exps)
    (let* ((scan-results
            (map scan-definitions-and-transform exps))
           (result-sets
            (map car scan-results))
           (transformed-exps
            (map cdr scan-results)))
      (cons (fold-right set-union '() result-sets)
            transformed-exps)))

;; SExp -> (Set Var, SExp)
(define (scan-definitions-and-transform exp)
  (cond
   ((or (self-evaluating? exp)
        (quoted? exp)
        (variable? exp))
    ;; no new definition, keep original expression
    (cons '() exp))
   ((assignment? exp)
    ;; (set! <var> <exp>)
    (let ((scan-result (scan-definitions-and-transform
                        (assignment-value exp))))
      ;; pass inner definitions, create transformed expression
      (cons (car scan-result)
            `(set! ,(assignment-variable exp)
                   ,(cdr scan-result)))))
   ((definition? exp)
    (let ((exp (normalize-define exp)))
      ;; one local definition detected
      (let ((scan-result (scan-definitions-and-transform
                          (definition-value exp))))
        (cons (set-insert (definition-variable exp)
                          (car scan-result))
              ;; definition translated into assignment
              `(set! ,(definition-variable exp)
                     ,(cdr scan-result))))))
   ((if? exp)
    ;; (if <pred> <cons> <alt>)
    ;; since the accessor assigns a value
    ;; when there is no alternative expression
    ;; the assumed syntax here is safe
    (let ((scan-result
           ;; (cdr exp) => (<pred> <cons> <alt>)
           (scan-and-transform-exps (cdr exp))))
      (cons (car scan-result)
            `(if ,@(cdr scan-result)))))
   ((lambda? exp)
    ;; this is the tricky part: lambda is the definition boundary
    ;; we will perform the transformation inside, but passing
    ;; the empty set of defintions out.
    ;; this loop can be terminated
    ;; because this lambda-expression will be structurally smaller
    (cons '()
          (transform-sexp exp)))
   ((begin? exp)
    (let ((scan-result
           (scan-and-transform-exps (begin-actions exp))))
      (cons (car scan-result)
            `(begin ,@(cdr scan-result)))))
   ((cond? exp)
    ;; desugar it
    (scan-definitions-and-transform (cond->if exp)))
   ((let? exp)
    ;; desugar it
    (scan-definitions-and-transform (let->combination exp)))
   ((application? exp)
    (scan-and-transform-exps exp))
   (else
    (error "invalid s-expression: "
           exp))))


(define (transform-sexp exp)
  (out "transform: " exp)
  ;; invariant:
  ;; * the inner-expressions are always transformed before
  ;;   its outer-expression
  ;; * the input is a valid s-exp
  ;;   and the output is a valid s-exp but without local definitions
  (cond
   ((or (self-evaluating? exp)
        (quoted? exp)
        (variable? exp))
    ;; forms that couldn't contain a sub-expression,
    ;; the transformation will just leave them unchanged
    exp)
   ((assignment? exp)
    ;; (set! <var> <exp>)
    `(set! ,(assignment-variable exp)
           ,(transform-sexp (assignment-value exp))))
   ((definition? exp)
    ;; We are not going to take two cases into account.
    ;; Instead, we "normalize" the definition so we are sure to
    ;; deal with a normalized form later
    ;; (this makes "lambda" the only form that the transformation cares about)
    (let ((exp (normalize-define exp)))
      ;; overwritten exp shadowing the original one
      `(define
         ,(definition-variable exp)
         ,(transform-sexp (definition-value exp)))))
   ((if? exp)
    ;; (if <pred> <cons> <alt>)
    ;; since the accessor assigns a value
    ;; when there is no alternative expression
    ;; the assumed syntax here is safe
    `(if ,(transform-sexp (if-predicate exp))
         ,(transform-sexp (if-consequent exp))
         ,(transform-sexp (if-alternative exp))))
   ((lambda? exp)
    ;; here we need to:
    ;; * scan exposed definitions
    ;; * eliminate them
    ;; we can do things in one traversal:
    ;; * scan definition, if something like "(define ...)"
    ;;   is found, change it to "(set! ...)" and put the variable
    ;;   somewhere
    ;;   this function will have type: SExp -> (Set Var, SExp)
    ;; * after this is done, wrap the subexpression with a "let"
    ;;   to include local variables
    (let* ((scan-result
            (scan-and-transform-exps (lambda-body exp)))
           (local-defs
            (car scan-result))
           (transformed-body
            (cdr scan-result))
           (transformed-body2
            `(let ,(map (lambda (var)
                          `(,var '*unassigned*))
                        local-defs)
               ,@(map transform-sexp transformed-body))))
      `(lambda ,(lambda-parameters exp)
         ,transformed-body2)))
   ((begin? exp)
    ;; (begin <exp> ...)
    `(begin ,@(map
               transform-sexp
               (begin-actions exp))))
   ((cond? exp)
    ;; well, let's desugar it
    (transform-sexp (cond->if exp)))
   ((let? exp)
    ;; well, let's desugar it
    (transform-sexp (let->combination exp)))
   ((application? exp)
    ;; (<exp1> <exp2s> ...)
    `(,(transform-sexp (operator exp))
      ,@(map transform-sexp (operands exp))))
   (else
    (error "invalid s-expression: "
           exp))))

;; TODO: need some unit tests to figure it out..
(pretty-print
 (transform-sexp
  `(lambda (x)
     (begin
       (define y 1)
       (define z 2)
       (if (= x 0)
           (begin
             (define a 10)
             (+ x a))
           (begin
             (define b 320)
             ;; TODO: local function definition results
             ;; in infinite loop...
             (define (f x y)
               (+ x y))
             (f (* x 3 b) 20)))))))

(define (scan-out-defines p-body)
  ;; p-body is a sequence of expression
  (define internal-definition
    (filter definition? p-body))

  (define intern-def-exps
    (filter
     intern-define?
     p-body))
  (define intern-def-vars
    (map definition-variable intern-def-exps))
  (define intern-def-vals
    (map definition-value    intern-def-exps))
  (define (def->set exp)
    (if (definition? exp)
        `(set! ,(definition-variable exp)
               ,(definition-value    exp))
        exp))
  `(let
       ;; generate var-unassigned pairs
       ,(map (lambda (var)
               `(,var '*unassigned*))
             intern-def-vars)
     ;; let body
     ,@(map def->set p-body)))

(end-script)