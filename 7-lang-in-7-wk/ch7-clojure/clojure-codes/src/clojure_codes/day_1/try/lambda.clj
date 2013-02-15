(ns clojure-codes.day-1.try.lambda
  (:require 
    [clojure-codes.utils :as utils]))

(defn -main [& args]
  (utils/eval-and-println
    (def people ["Lea", "Han Solo"])
    (count "Lea")
    ; 3

    (map count people)
    ; (3 8)

    (defn twice-count [w] (* 2 (count w)))
    (twice-count "Lando")
    ; 10

    (map twice-count people)
    ; (6 16)

    (map (fn [w] (* 2 (count w))) people)
    ; same as line above

    (map #(* 2 (count %)) people)
    ; '#' is called reader macro

    (def v [3 1 2])

    (apply + v)
    ; call + taking arguments from v
    ; 3+1+2 = 6
    (apply max v)
    ; 3

    (filter odd? v)
    ; (3 1)

    ; smaller than 3
    (filter #(< % 3) v)
    ; (1 2)
  )
)
