(define (make-new-machine)
  (let ((pc (make-register 'pc))
        (flag (make-register 'flag))
        (stack (make-stack))
        (the-instruction-sequence '())
        (instruction-counter 0))
    (let ((the-ops
           (list
            ;; seems we have to modify the primitive list here
            (list 'print-insn-counter
                  (lambda ()
                    (format #t "# instruction executed: ~A~%"
                            instruction-counter)))
            (list 'reset-insn-counter
                  (lambda ()
                    (set! instruction-counter 0)))
            (list 'initialize-stack
                  (lambda ()
                    (stack 'initialize)))))
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
              (begin
                ((instruction-execution-proc (car insts)))
                ;; bump counter
                (set! instruction-counter
                      (add1 instruction-counter))
                (execute)))))
      (define (dispatch message)
        (cond ((eq? message 'start)
               ;; initialize instruction counter
               (set! instruction-counter 0)
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
              ;; new messages: get and reset counter
              ((eq? message 'get-insn-counter) instruction-counter)
              ((eq? message 'reset-insn-counter)
               (set! instruction-counter 0))
              (else
               (error "Unknown request: MACHINE"
                      message))))
      dispatch)))

(define (get-instruction-counter m)
  (m 'get-insn-counter))

(define (reset-insn-counter m)
  (m 'reset-insn-counter))
