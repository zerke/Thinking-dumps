(load "./rewrite.scm")

;; rules are just lists,
;; to merge rules we simply combine them together
(define merge-rules append)

;; this function is for internal use only,
;; it returns a pair, whose `car` should be considered a boolean value
;; indicating if there's any rule application happens in this round
;; and `cdr` part being the resulting instruction list
(define (rewrite-instructions-intern rules insns)
  ;; 3 things we need to keep
  ;; * a new instruction list
  ;; * rest of the old instruction list to be processed
  ;; * a flag indicating if any rule application has happened
  (let loop ((new-insns '())
             (curr-insns insns)
             (at-least-once #f))
    (if (null? curr-insns)
        (cons at-least-once new-insns)
        (let ((result (try-rewrite-once rules (car curr-insns))))
          (loop (append new-insns
                        (or result (list (car curr-insns))))
                (cdr curr-insns)
                (or at-least-once result))))))

;; this rewrite function applies only the first applicable rule
;; and do the application only once
(define (rewrite-instructions rules insns)
  (cdr (rewrite-instructions-intern rules insns)))

;; expand the list of instructions
;; as long as there is at least one applicable rule
;; and also we need to make sure that we don't write rules that expands
;; infinitely.
;; we need this function because the stack manipulations are still using
;; list primitives like "car" "cdr" and "cons", and the reason we have this
;; rewrite system is that we are trying to avoid doing these tasks manually.
;; it will be great if we can just write down the most intuitive code
;; and leave all the boring tasks to computer.
(define (rewrite-instructions* rules insns)
  (let ((result (rewrite-instructions-intern rules insns)))
    (if (car result)
        (rewrite-instructions* rules (cdr result))
        (cdr result))))
