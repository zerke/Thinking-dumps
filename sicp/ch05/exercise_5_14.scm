(load "../common/utils.scm")
(load "../common/test-utils.scm")

;; Using approach 1
;; (see exercise_5_14.md for explanation)

(load "./simu.scm")
(load "./simu-monitor-patch.scm")

(load "./figure_5_11.scm")

(let ((m (ctl->machine
          fac-machine-controller)))
  (let loop ((n 2))
    (if (<= n 10)
        (begin
          (machine-init-regs! m `((n ,n)))
          (machine-fresh-start! m)
          (let ((stat (stack-get-statistics (machine-stack m))))
            (format
             #t
             "n = ~A, number-pushes = ~A, max-depth = ~A~%"
             n
             (cdr (assoc 'number-pushes stat))
             (cdr (assoc 'max-depth stat))))
          (loop (add1 n)))
        'done)))

(end-script)

;; Local variables:
;; proc-entry: ""
;; End:
