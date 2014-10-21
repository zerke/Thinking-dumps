(load "./exercise_5_17_legacy_prelabel_patch.scm")
(load "./exercise_5_19_breakpoint_table.scm")

;; TODO list:
;; * maintain resuming flag

;; based on ex 5.17 patch
(define (make-new-machine)
  (let ((pc (make-register 'pc))
        (flag (make-register 'flag))
        (stack (make-stack))
        (the-instruction-sequence '())
        (instruction-counter 0)
        ;; maintain "after-label-counter"
        (after-label-counter 0)
        (trace #f)
        ;; maintain "current-label"
        (current-label #f))
    (let ((the-ops
           (list
            (list 'initialize-stack
                  (lambda ()
                    (stack 'initialize)))
            (list 'trace-on
                  (lambda ()
                    (set! trace #t)))
            (list 'trace-off
                  (lambda ()
                    (set! trace #f)))
            (list 'print-insn-counter
                  (lambda ()
                    (format #t "# instruction executed: ~A~%"
                            instruction-counter)))
            (list 'reset-insn-counter
                  (lambda ()
                    (set! instruction-counter 0)))
            ))
          (register-table
           (list (list 'pc pc)
                 (list 'flag flag))))
      (define (allocate-register name)
        (if (assoc name register-table)
            (error "Multiply defined register:"
                   name)
            (set! register-table
                  (cons (list name (make-register name))
                        register-table)))
        'register-allocated)
      (define (lookup-register name)
        (let ((val (assoc name register-table)))
          (if val
              (cadr val)
              (error "Unknown register:"
                     name))))
      (define (execute)
        (let ((insts (get-contents pc)))
          (if (null? insts)
              'done
              (let* ((inst (car insts))
                     (proc (instruction-execution-proc inst))
                     (text (instruction-text inst))
                     (lbl  (instruction-previous-label inst)))
                (if trace
                    (begin
                      (if lbl
                          (format #t "into label: ~A~%" lbl)
                          'skipped)
                      (out text))
                    'skipped)
                (if lbl
                    (begin
                      (set! current-label lbl)
                      (set! after-label-counter 0))
                    'skipped)
                (format #t "current label:~A~%~
                            after-label-counter:~A~%"
                            current-label
                            after-label-counter)
                (proc)
                (set! instruction-counter
                      (add1 instruction-counter))
                (set! after-label-counter
                      (add1 after-label-counter))
                (execute)))))
      (define (dispatch message)
        (cond ((eq? message 'start)
               (set! instruction-counter 0)
               (set! after-label-counter 0)
               (set! current-label #f)
               (set-contents! pc the-instruction-sequence)
               (execute))
              ((eq? message 'install-instruction-sequence)
               (lambda (seq)
                 (set! the-instruction-sequence seq)))
              ((eq? message 'allocate-register)
               allocate-register)
              ((eq? message 'get-register)
               lookup-register)
              ((eq? message 'install-operations)
               (lambda (ops)
                 (set! the-ops (append the-ops ops))))
              ((eq? message 'stack) stack)
              ((eq? message 'operations) the-ops)
              ((eq? message 'trace?) trace)
              ((eq? message 'trace-on)
               (set! trace #t))
              ((eq? message 'trace-off)
               (set! trace #f))
              ((eq? message 'get-insn-counter) instruction-counter)
              ((eq? message 'reset-insn-counter)
               (set! instruction-counter 0))
              (else
               (error "Unknown request: MACHINE"
                      message))))
      dispatch)))

;; Local variables:
;; proc-entry: "./exercise_5_19_legacy.scm"
;; End:
