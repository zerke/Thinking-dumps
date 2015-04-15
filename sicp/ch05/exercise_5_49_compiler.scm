;; based on ex 5.47

(load "exercise_5_47_compiler.scm")

(set! all-regs
      ;; well this is not actually necessary
      ;; as "compapp" is supposed to be immutable
      ;; after its initialization
      ;; but we want to keep the meaning of "all-regs"
      ;; consistent.
      (set-delete 'compapp all-regs))

(define (check-instruction-sequence compiled-seq)
  (let ((insn-seq (statements compiled-seq))
        (needed (registers-needed compiled-seq)))
    (assert
     ;; we no longer need compapp
     (set-subset<=? needed '(env))
     "the only required register (if any) should be 'env'")
    (if (check-labels insn-seq)
        'ok
        (out "Error regarding labels occurred."))

    (let ((operations (map car (extract-operations insn-seq))))
      (assert (set-subset<=? (remove-duplicates operations)
                             ;; primitive operations are just part of
                             ;; required operations
                             (ec-get-required-operations))
              "unknown operation found"))
    #t))

(define (compile-procedure-call target linkage)
  ;; function application for compiled procedures
  (define (compile-proc-appl target linkage)
    ;; note that the linkage will never be "next"
    ;; case coverage:
    ;;         | target = val | target != val
    ;; return  | covered      | error
    ;; <other> | covered      | covered
    (cond ((and (eq? target 'val)
                (not (eq? linkage 'return)))
           ;; - no need to move result value
           ;; - do an immediate jump afterwards
           (make-instruction-sequence
            '(proc) all-regs
            `((assign continue (label ,linkage))
              (assign val (op compiled-procedure-entry)
                      (reg proc))
              (goto (reg val)))))
          ((and (not (eq? target 'val))
                (not (eq? linkage 'return)))
           ;; - need to move result value "val" to the target
           ;; - do an immediate jump afterwards
           (let ((proc-return (make-label 'proc-return)))
             (make-instruction-sequence
              '(proc) all-regs
              `((assign continue (label ,proc-return))
                (assign val (op compiled-procedure-entry)
                        (reg proc))
                (goto (reg val))
                ,proc-return
                ;; need this extra step to transfer value
                (assign ,target (reg val))
                (goto (label ,linkage))))))
          ((and (eq? target 'val) (eq? linkage 'return))
           ;; - no need to move result value
           ;; - let the compiled procedure do the return job
           (make-instruction-sequence
            '(proc continue) all-regs
            `((assign val (op compiled-procedure-entry)
                      (reg proc))
              (goto (reg val)))))
          ((and (not (eq? target 'val))
                (eq? linkage 'return))
           ;; - convention is violated here: whenever we return,
           ;;   the resulting value should be available in "val"
           ;; - the only place where a "return" linkage used
           ;;   is in the body of "compile-lambda-body",
           ;;   and that code sets its target to "val".
           ;; so no code (at least for those found in book)
           ;; will hit this branch
           (error "return linkage, target not val: COMPILE"
                  target))))
  ;; ====
  (let ((primitive-branch (make-label 'primitive-branch))
        (compiled-branch (make-label 'compiled-branch))
        (after-call (make-label 'after-call)))
    ;; INVARIANT: compile-proc-appl and compile-compound-proc-appl
    ;; can never be called with linkage = next
    (let ((compiled-linkage
           (if (eq? linkage 'next) after-call linkage))
          (compound-linkage
           (if (eq? linkage 'next) after-call linkage)))
      (append-instruction-sequences
       (make-instruction-sequence
        '(proc) '()
        `((test (op primitive-procedure?) (reg proc))
          ;; goto primitive branch
          (branch (label ,primitive-branch))
          (test (op compiled-procedure?) (reg proc))
          (branch (label ,compiled-branch))
          ;; if all of the dispatches have failed ... we panic!
          (perform (op error) (const "unknown proc object"))
          ))
       (parallel-instruction-sequences
        (append-instruction-sequences
         ;; otherwise the procedure must be a compiled one
         compiled-branch
         ;; note that it's not possible for compiled-linkage to
         ;; take the value "next"
         (compile-proc-appl target compiled-linkage))
        ;; ==> deal with primitive procedures
        (append-instruction-sequences
         primitive-branch
         (end-with-linkage
          linkage
          (make-instruction-sequence
           '(proc argl) (list target)
           `((assign ,target
                     (op apply-primitive-procedure)
                     (reg proc)
                     (reg argl)))))))
       after-call))))

(define (compile-and-go exp)
  (let* ((compiled
          (compile exp 'val 'return))
         (insn-seq (statements compiled))
         (env (init-env))
         (m (build-with
             `(controller
               (goto (label external-entry))
               ,@evaluator-insns
               ;; we will always append extra code to the tail
               ;; of the previous instruction sequence
               ;; so that the behavior is consistent with
               ;; "additive assemble" patch.
               ;; i.e. new codes are always attached
               ;; to the existing one.
               external-entry
               ;; initialize compapp - we are not going
               ;; to change it during the whole program.
               (perform (op initialize-stack))
               (assign env (op get-global-environment))
               (assign continue (label print-result))
               ,@insn-seq
               )
             `((env ,env)
               (proc *unassigned*)
               (argl *unassigned*))
             (ec-ops-builder-modifier
              (ops-builder-union
               monitor-patch-ops-builder-extra
               default-ops-builder)))))
    (machine-extra-set! m 'global-env env)
    (machine-fresh-start! m)))
