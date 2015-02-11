(load "../common/utils.scm")
(load "../common/test-utils.scm")

;; spread-arguments takes a list of operands
;; and assign each of them into the corresponding
;; target registers, note that in order
;; to keep the order of operands' evaluation consistent
;; the operands are evaluated from right to left
;; e.g.
;;  (spread-arguments (list <exp1> <exp2>))
;; first evaluates "exp2", assigning the value to
;; "arg1" register, and then "exp1" is evaluated
;; and its value is assigned to "arg2"
;; * the length of the operand list must be less or equal to 2
;; * this function assumes the existence of register "arg1" and "arg2"
;;   which the target machine should provide
(define (spread-arguments operands)
  ;; TODO: if we use "val" as "argument register",
  ;; can we handle "open-code" primitives that
  ;; takes 3 arguments?
  (assert (<= (length operands) 2)
          "the length of the operand list must not exceed 2")
  ;; TODO: I'm not sure if targeting registers other than "val" or "proc"
  ;; will yield problematic instruction lists. previously I recall there's
  ;; somewhere in the compiler that assume the target register being
  ;; either "val" or "proc".

  ;; for now, let's just go back to the exercise and think about "open-code"
  ;; primitives for the second time: an "(assign arg1 (reg val))" instruction
  ;; right after the evaluation will be fine, but it makes code more verbose
  ;; which violates what "open-code" primitive is doing.
  (let ((compiled-operands (map (lambda (operand-exp target)
                                  (compile operand-exp target 'next))
                                operands
                                '(arg1 arg2))))
    'todo))

(end-script)

;; Local variables:
;; proc-entry: ""
;; End:
