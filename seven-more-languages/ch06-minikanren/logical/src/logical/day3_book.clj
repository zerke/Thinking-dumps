;---
; Excerpted from "Seven More Languages in Seven Weeks",
; published by The Pragmatic Bookshelf.
; Copyrights apply to this code. It may not be used to create training material,
; courses, books, articles, and the like. Contact us if you are in doubt.
; We make no guarantees that this code is fit for any purpose.
; Visit http://www.pragmaticprogrammer.com/titles/7lang for more book information.
;---
;; modified by Javran for doing exercises in book xD
(ns logical.day3-book
  (:refer-clojure :exclude [==])
  (:use
   clojure.core.logic
   clojure.core.logic.pldb))

(def story-elements
  [[:maybe-telegram-girl :telegram-girl
    "A singing telegram girl arrives."]
   [:maybe-motorist :motorist
    "A stranded motorist comes asking for help."]
   [:motorist :policeman
    "Investigating an abandoned car, a policeman appears."]
   [:motorist :dead-motorist
    "The motorist is found dead in the lounge, killed by a wrench."]
   [:telegram-girl :dead-telegram-girl
    "The telegram girl is murdered in the hall with a revolver."]
   [:policeman :dead-policeman
    "The policeman is killed in the library with a lead pipe."]
   [:dead-motorist :guilty-mustard
    "Colonel Mustard killed the motorist, his old driver during the war."]
   [:dead-motorist :guilty-scarlet
    "Miss Scarlet killed the motorist to keep her secrets safe."]
   [:dead-motorist :guilty-peacock
    "Mrs. Peacock killed the motorist."]
   [:dead-telegram-girl :guilty-scarlet
    "Miss Scarlet killed the telegram girl so she wouldn't talk."]
   [:dead-telegram-girl :guilty-peacock
    "Mrs. Peacock killed the telegram girl."]
   [:dead-telegram-girl :guilty-wadsworth
    "Wadsworth shot the telegram girl."]
   [:dead-policeman :guilty-scarlet
    "Miss Scarlet tried to cover her tracks by murdering the policeman."]
   [:dead-policeman :guilty-peacock
    "Mrs. Peacock killed the policeman."]
   [:mr-boddy :dead-mr-boddy
    "Mr. Boddy's body is found in the hall beaten to death with a candlestick."]
   [:dead-mr-boddy :guilty-plum
    "Mr. Plum killed Mr. Boddy thinking he was the real blackmailer."]
   [:dead-mr-boddy :guilty-scarlet
    "Miss Scarlet killed Mr. Boddy to keep him quiet."]
   [:dead-mr-boddy :guilty-peacock
    "Mrs. Peacock killed Mr. Boddy."]
   [:cook :dead-cook
    "The cook is found stabbed in the kitchen."]
   [:dead-cook :guilty-scarlet
    "Miss Scarlet killed the cook to silence her."]
   [:dead-cook :guilty-peacock
    "Mrs. Peacock killed her cook, who used to work for her."]
   [:yvette :dead-yvette
    "Yvette, the maid, is found strangled with the rope in the billiard room."]
   [:dead-yvette :guilty-scarlet
    "Miss Scarlet killed her old employee, Yvette."]
   [:dead-yvette :guilty-peacock
    "Mrs. Peacock killed Yvette."]
   [:dead-yvette :guilty-white
    "Mrs. White killed Yvette, who had an affair with her husband."]
   [:wadsworth :dead-wadsworth
    "Wadsworth is found shot dead in the hall."]
   [:dead-wadsworth :guilty-green
    "Mr. Green, an undercover FBI agent, shot Wadsworth."]])

(db-rel ploto a b)

;; story-db is the result of accumulating elements as "ploto" relation
;; nothing fancy.
(def story-db
  (reduce
   (fn [dbase elems]
     (apply db-fact dbase ploto (take 2 elems)))
   (db)
   story-elements))

;; resources available at the very beginning
(def start-state
  [:maybe-telegram-girl :maybe-motorist
   :wadsworth :mr-boddy :cook :yvette])

(defn actiono [state new-state action]
  (fresh [in out temp]
    ;; pick up one available resource
    (membero in state)
    ;; try to "trade" it for something else
    (ploto in out)
    ;; remove the old resource and add the new one
    (rembero in state temp)
    (conso out temp new-state)
    (== action [in out])))

(declare storyo*)

(defn storyo [end-elems actions]
  ;; shuffle start state for a more "randomized" solution
  (storyo* (shuffle start-state) end-elems actions))

(defn storyo* [start-state end-elems actions]
  (fresh [action new-state new-actions]
    ;; make one action
    (actiono start-state new-state action)
    ;; and add it to the list of actions
    (conso action new-actions actions)
    (conda
     ;; story generation ends if all end-elems
     ;; are accquired in the current state
     [(everyg #(membero % new-state) end-elems)
      (== new-actions [])]
     ;; otherwise, we keep generating more actions
     [(storyo* new-state end-elems new-actions)])))

;; story pretty-printing
(def story-map
  (reduce (fn [m elems] ;; (13)
            (assoc m (vec (take 2 elems)) (nth elems 2)))
          {}
          story-elements))

(defn print-story [actions]
  (println "PLOT SUMMARY:")
  (doseq [a actions] ;; (14)
    (println (story-map a))))
