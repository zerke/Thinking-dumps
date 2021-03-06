(load "../common/utils.scm")
(load "../common/test-utils.scm")

(load "./amb-eval.scm")

;; I'll only extend noun phrases to include adjectives
;; and extend verb phrases to include adverbs
;; Just show some possibility

;; from natural_language_common.scm
(define (run-source-in-env src)
  ;; "src" will be evaluated after all the procedures
  ;; gets created
  `(begin
     ;; definition of all valid objects

     (define nouns
       '(noun
         student professor cat class fox dog))

     (define adjectives
       '(adjective
         quick brown lazy good bad new old))

     (define verbs
       '(verb
         studies lectures eats sleeps jumps))

     (define adverbs
       '(adverb
         nicely merely exactly happily))

     (define articles
       '(article
         the a))

     (define prepositions
       '(prep
         for to in by with over))

     ;; given a word list, try to parse the next data
     (define (parse-word word-list)
       (require (not (null? *unparsed*)))
       (require (memq (car *unparsed*)
                      (cdr word-list)))
       (let ((found-word (car *unparsed*)))
         (set! *unparsed* (cdr *unparsed*))
         (list (car word-list) found-word)))

     ;; prepostional phrase is a preposition followed by noun phrase
     ;; prep-phrase ::= prep noun-phrase
     (define (parse-prepositional-phrase)
       (list 'prep-phrase
             (parse-word prepositions)
             (parse-noun-phrase)))

     ;; now a sentence is noun phrase + verb phrase
     ;; sentence ::= noun-phrase verb-phrase
     (define (parse-sentence)
       (list 'sentence
             (parse-noun-phrase)
             (parse-verb-phrase)))

     ;; verb phrase: a verb (maybe followed by prepositional phrase)
     ;; e.g.: * eats to a cat with the cat ..
     ;;       * studies with a student
     ;;       * lectures
     ;; (well we don't do sanity check here)
     ;; verb-phrase ::= verb | verb-phrase prep-phrase
     ;; =>
     ;; verb-phrase ::= verb-phrase adverb | verb-phrase prep-phrase | verb
     ;; here I find the the exact meaning of "maybe-extend" is unclear
     (define (parse-verb-phrase)
       ;; verb-phrase ::= verb | verb-phrase prep-phrase
       (define (maybe-extend verb-phrase)
         (amb
          verb-phrase
          (maybe-extend
           (list 'verb-phrase
                 verb-phrase
                 (parse-prepositional-phrase)))
          (maybe-extend
           (list 'verb-phrase
                 verb-phrase
                 (parse-word adverbs)))))
       (maybe-extend (parse-word verbs)))

     ;; a simple noun phrase is an article followed by a noun
     (define (parse-simple-noun-phrase)
       (define (parse-adj*-noun)
         (amb (list 'adj-noun-phrase
                    (parse-word adjectives)
                    (parse-adj*-noun))
              (list (parse-word nouns))))
       (cons 'simple-noun-phrase
             (cons (parse-word articles)
                   (parse-adj*-noun))))

     ;; a noun phrase is: a simple one, might be followed by props
     (define (parse-noun-phrase)
       (define (maybe-extend noun-phrase)
         (amb noun-phrase
              (maybe-extend
               (list 'noun-phrase
                     noun-phrase
                     (parse-prepositional-phrase)))))
       (maybe-extend (parse-simple-noun-phrase)))

     ;; the data to be converted
     (define *unparsed* '())

     ;; parse input
     (define (parse input)
       (set! *unparsed* input)
       (let ((sent (parse-sentence)))
         ;; when parsing is done,
         ;; there shouldn't be anything remaining
         (require (null? *unparsed*))
         sent))
     ,src
     ))

(out (amb-eval-all
      (run-source-in-env
       `(parse
         '(the good new student eats nicely with the bad old cat)))
      (amb-init-env)))

(out (amb-eval-all
      (run-source-in-env
       `(parse
         '(the quick brown fox jumps over the lazy dog)))
      (amb-init-env)))

(end-script)

;; Local variables:
;; proc-entry: ""
;; End:
