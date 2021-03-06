#lang racket
(require (planet soegaard/sicp:2:1/sicp))

(define (p->file painter filename)
  (send (send (paint painter) get-bitmap)
        save-file
        (string-append "./pic_out/" filename ".png")
        'png))

; list should be placed in format: '(((0.1 0.2) (0.3 0.4)) ... )
(define (list->segments point-pairs)
  (map
    (lambda (point-pair)
      (let* ((a (car point-pair))
             (b (cadr point-pair))
             (ax (car a))
             (ay (cadr a))
             (bx (car b))
             (by (cadr b)))
        (make-segment (make-vect ax ay)
                      (make-vect bx by))))
    point-pairs))

(define (right-split painter n)
  (if (= n 0)
    painter
    (let ((smaller (right-split painter (- n 1))))
      (beside painter (below smaller smaller)))))
(define (up-split painter n)
  (if (= n 0)
    painter
    (let ((smaller (up-split painter (- n 1))))
      (below painter (beside smaller smaller)))))

; ------------------ the original corner-split
(define (corner-split1 painter n)
  (if (= n 0)
    painter
    (let* ((up (up-split painter (- n 1)))
           (rt (right-split painter (- n 1)))
           (top-left (beside up up))
           (bottom-right (below rt rt))
           (corner (corner-split1 painter (- n 1))))
      (beside (below painter top-left)
              (below bottom-right corner)))))


; ------------------ solution to pattern changing on corner-split
(define (corner-split2 painter n)
  (if (= n 0)
    painter
    (let* ((up (up-split painter (- n 1)))
           (rt (right-split painter (- n 1)))
           (top-left up)
           (bottom-right rt)
           (corner (corner-split2 painter (- n 1))))
      (beside (below painter top-left)
              (below bottom-right corner)))))

(define raw-data
  (file->lines "./wave_segments.txt"))

(define pic-size
  (string->number
    (car
      (string-split (car raw-data)))))

(define raw-wave-segment-list
  (map
    (lambda (line)
      (let ((data (string-split line)))
        (list (list (car data)
                    (cadr data))
              (list (caddr data)
                    (cadddr data)))))
    (cdr raw-data)))

(define (remap-point p)
  (let ((x0 (car p))
        (y0 (cadr p)))
    (list (/ x0 pic-size)
          (/ (- pic-size y0) pic-size))))
(define (str-pt->num-pt p)
  (map string->number p))

(define wave-segment-list
  (map
    (lambda (segment)
      (map remap-point
           ; remap points
           (map str-pt->num-pt
                ; convert str-segments to num-segments
                segment)))
    raw-wave-segment-list))

(define wave
  (segments->painter
    (list->segments
      wave-segment-list)))

(p->file (corner-split1 wave 4) "ex_2_52_b_cs1")
(p->file (corner-split2 wave 4) "ex_2_52_b_cs2")
