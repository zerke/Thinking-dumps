;; for now I'm not sure what to do
;; guess if we copy the code here,
;; this will soon become useful
(define core-dispatch
  '(eval-dispatch
    (test (op self-evaluating?) (reg exp))
    (branch (label ev-self-eval))

    (test (op variable?) (reg exp))
    (branch (label ev-variable))

    (test (op quoted?) (reg exp))
    (branch (label ev-quoted))

    (test (op assignment?) (reg exp))
    (branch (label ev-assignment))

    (test (op definition?) (reg exp))
    (branch (label ev-definition))

    (test (op if?) (reg exp))
    (branch (label ev-if))

    (test (op lambda?) (reg exp))
    (branch (label ev-lambda))

    (test (op begin?) (reg exp))
    (branch (label ev-begin))

    (test (op application?) (reg exp))
    (branch (label ev-application))

    (goto (label unknown-expression-type))))

(define simple-expressions
  '(ev-self-eval
    (assign val (reg exp))
    (goto (reg continue))

    ev-variable
    (assign
     val (op lookup-variable-value) (reg exp) (reg env))
    (goto (reg continue))

    ev-quoted
    (assign val (op text-of-quotation) (reg exp))
    (goto (reg continue))

    ev-lambda
    (assign unev (op lambda-parameters) (reg exp))
    (assign exp (op lambda-body) (reg exp))
    (assign val (op make-procedure)
                (reg unev) (reg exp) (reg env))
    (goto (reg continue))))

(define proc-application
  '(ev-application
    (save continue) ; stack: [continue ..]
    (save env) ; stack: [env continue ..]
    (assign unev (op operands) (reg exp))
    (save unev) ; stack: [unev env continue ..]
    (assign exp (op operator) (reg exp))
    (assign continue (label ev-appl-did-operator))
    ;; exp -> val
    (goto (label eval-dispatch))

    ;; back
    ev-appl-did-operator
    (restore unev) ; stack: [env continue ..]
    (restore env) ; stack: [continue ..]
    ;; things evaluated so far
    (assign argl (op empty-arglist))
    ;; evaluated procedure
    (assign proc (reg val))
    ;; procedure called without operands, do application
    (test (op no-operands?) (reg unev))
    (branch (label apply-dispatch))
    ;; otherwise we need to evaluate them all
    (save proc) ; stack: [proc continue ..]
    ev-appl-operand-loop
    (save argl) ; stack: [argl proc continue ..]
    (assign exp (op first-operand) (reg unev))
    (test (op last-operand?) (reg unev))
    (branch (label ev-appl-last-arg))
    ;; this is not the last arg
    (save env) ; stack: [env argl proc continue ..]
    (save unev) ; stack: [unev env argl proc continue ..]
    (assign continue (label ev-appl-accumulate-arg))
    (goto (label eval-dispatch))
    ;; back
    ev-appl-accumulate-arg
    ;; first operand turned into val,
    ;; add it to argl
    (restore unev) ; stack: [env argl proc continue ..]
    (restore env) ; stack: [argl proc continue ..]
    (restore argl) ; stack: [proc continue ..]
    ;; TODO: note that if we insert "val" in front of "argl"
    ;; then "argl" is storing arguments in the reversed order,
    ;; what is "adjoin-arg" is not mentioned in the book
    ;; but I guess it needs to at least keep the order of "argl"
    ;; and the order of "unev" consistent.
    (assign argl (op adjoin-arg) (reg val) (reg argl))
    ;; drop the first operand
    (assign unev (op rest-operands) (reg unev))
    (goto (label ev-appl-operand-loop))

    ;; we only go to here when there's only one unevaluated expression left
    ev-appl-last-arg
    (assign continue (label ev-appl-accum-last-arg))
    (goto (label eval-dispatch))
    ev-appl-accum-last-arg
    (restore argl) ; stack: [proc continue ..]
    (assign argl (op adjoin-arg) (reg val) (reg argl))
    (restore proc) ; stack: [continue ..]
    (goto (label apply-dispatch))
    ;; TODO: stack not balanced here?
    ;; note that when calling "apply-dispatch",
    ;; a "continue" is always on the stack.. but why?
    ;; ---looks like apply-dispatch simply assume that
    ;; there's always one "continue" on the top of the stack
    ))

(define procedure-application
  '(apply-dispatch
    (test (op primitve-procedure?) (reg proc))
    (branch (label primitive-apply))
    (test (op compound-procedure?) (reg proc))
    (branch (label compound-apply))
    (goto (label unknown-procedure-type))

    primitive-apply
    (assign val (op apply-primitive-procedure)
                (reg proc)
                (reg argl))
    ;; stack: <balanced>
    (restore continue)
    (goto (reg continue))

    compound-apply
    (assign unev (op procedure-parameters) (reg proc))
    (assign env (op procedure-environment) (reg proc))
    (assign env (op extend-environment)
                (reg unev) (reg argl) (reg env))
    (assign unev (op procedure-body) (reg proc))
    (goto (label ev-sequence))))

(define seq-eval
  '(ev-begin
    ;; TODO: what's begin-actions?
    (assign unev (op begin-actions) (reg exp))
    (save continue)                     ; stack: [continue ..]
    (goto (label ev-sequence))
    ev-sequence
    (assign exp (op first-exp) (reg unev))
    (test (op last-exp?) (reg unev))
    (branch (label ev-sequence-last-exp))
    ;; seems like every time we call a "eval-dispatch" subroutine
    ;; the preparation phase looks similiar
    (save unev)                        ; stack: [unev continue ..]
    (save env)                         ; stack: [env unev continue ..]
    (assign continue (label ev-sequence-continue))
    (goto (label eval-dispatch))
    eq-sequence-continue
    (restore env)                       ; stack: [unev continue ..]
    (restore unev)                      ; stack: [continue ..]
    (assign unev (op rest-exps) (reg unev))
    (goto (label ev-sequence))
    ev-sequence-last-exp
    (restore continue)                  ; stack: <balanced>
    (goto (label eval-dispatch))))
