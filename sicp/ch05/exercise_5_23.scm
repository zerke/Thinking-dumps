(load "../common/utils.scm")
(load "../common/test-utils.scm")

(load "./simu.scm")
(load "./simu_ec_patch.scm")

;; from now on, we just use "simu.scm" as the machine
;; simulator, as using the legacy one won't make too much difference.

;; a list of functions that does transformation:
;; * cond->if
;;   converts an cond-exprssion to a nested if-expression
;; * sequence->exp
;;   converts a list of expressions into one expression
;;   in which the expressions are evaluated in order and
;;   the result of the last expression returns as the final result
;; * let->lambda-app
;    converts a let-expression into an application of lambda-expression

;; TODO: implementation

(end-script)

;; Local variables:
;; proc-entry: ""
;; End:
