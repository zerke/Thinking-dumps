(load "../common/utils.scm")
(load "../common/test-utils.scm")

(define (make-account balance password)
  (define (withdraw amount)
    (if (>= balance amount)
      (begin (set! balance (- balance amount))
             (out balance))
      (out "Insufficient funds")))
  (define (deposit amount)
    (set! balance (+ balance amount))
    (out balance))
  ; support password changing in addition
  ;   given that `change-password` can only be called when
  ;   the old password has been confirmed (by `dispatch`)
  ;   so here we don't need the old password
  (define (change-password new-password)
    (set! password new-password))
  (define (dispatch try-password m)
    (if (eq? password try-password)
      (cond ((eq? m 'withdraw) withdraw)
            ((eq? m 'deposit) deposit)
            ((eq? m 'change-password) change-password)
            (else (error "Unknown request: MAKE-ACCOUNT"
                         m)))
      (lambda args (out "Incorrect password"))))
  dispatch)

(define acc (make-account 100 'secret-password))

((acc 'secret-password 'withdraw) 40)
; 60
((acc 'some-other-password 'withdraw) 40)
; Incorrect password
((acc 'secret-password 'change-password) 'new-secret)
((acc 'secret-password 'withdraw) 40)
; Incorrect password
((acc 'new-secret 'withdraw) 40)
; 20

(end-script)
