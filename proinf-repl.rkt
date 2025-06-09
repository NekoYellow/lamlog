#lang racket

(require "proinf-core.rkt")

(provide repl)

;; ----------------------
;; REPL
;; ----------------------

(define (repl)
  (printf "ProInf REPL. Enter queries like: (grandparent X carol)\n")
  (printf "To add a fact: assertz((parent alice bob)).\n")
  (printf "To add a rule: assertz(((grandparent X Y) :- (parent X Z) (parent Z Y))).\n")
  (printf "To remove a clause: retract((parent alice bob)).\n")
  (printf "To list all clauses: list.\n")
  (printf "To exit: exit.\n")
  (let loop ()
    (display "\n?- ") (flush-output)
    (define line (read-line))
    (if (regexp-match #px"^exit\\.$" line)
        (begin (printf "Goodbye.\n") (exit))
        (with-handlers ([exn:fail? (lambda (e) (printf "Error: ~a\n" (exn-message e)) (loop))])
          (cond
            ;; Assertz command
            [(regexp-match #px"^assertz\\((.*)\\)\\.$" line)
             (define clause-str (regexp-match #px"^assertz\\((.*)\\)\\.$" line))
             (define clause-content (cadr clause-str))
             ;; Check for empty or malformed clause
             (if (or (string=? clause-content "")
                     (regexp-match #px"^\\s*$" clause-content)
                     (regexp-match #px"^\\s*\\(\\s*\\)\\s*$" clause-content))
                 (printf "Error: Empty or malformed clause in assertz command.\n")
                 (let ([new-clause (parse-clause clause-content)]) ;; Changed define to let
                   (cond
                     [(clause-exists? new-clause (kb-param))
                      (printf "Error: Clause already exists in the knowledge base.\n")]
                     [(clause-conflicts? new-clause (kb-param))
                      (printf "Error: Clause conflicts with existing clauses.\n")]
                     [else
                      (begin
                         (kb-param (append (kb-param) (list new-clause)))
                         (printf "true.\n"))])))]
            ;; Retract command
            [(regexp-match #px"^retract\\((.*)\\)\\.$" line)
             (define clause-str (regexp-match #px"^retract\\((.*)\\)\\.$" line))
             (define clause-content (cadr clause-str))
             ;; Check for empty or malformed clause
             (if (or (string=? clause-content "")
                     (regexp-match #px"^\\s*$" clause-content)
                     (regexp-match #px"^\\s*\\(\\s*\\)\\s*$" clause-content))
                 (printf "Error: Empty or malformed clause in retract command.\n")
                 (let ([clause-to-remove (parse-clause clause-content)]) ;; Changed define to let
                   (define original-kb (kb-param))
                   (define new-kb (filter (lambda (c) (not (equal? c clause-to-remove))) original-kb))
                   (if (= (length original-kb) (length new-kb))
                       (printf "Error: Clause does not exist in the knowledge base.\n")
                       (begin
                         (kb-param new-kb)
                         (printf "true.\n")))))]
            ;; List command
            [(regexp-match #px"^list\\.$" line)
             (if (null? (kb-param))
                 (printf "Knowledge base is empty.\n")
                 (begin
                   (printf "Current clauses in KB:\n")
                   (for-each (lambda (c) (printf "  ~a\n" (pretty-print-clause c))) (kb-param))))]
            ;; Query
            [else
             (define goals (parse-query line))
             (define results (resolve (kb-param) goals '()))
             (if (null? results)
                 (printf "false.\n")
                 (begin
                   (printf "true.\n")
                   (for-each
                    (lambda (s) (print-subst s goals))
                    results)))])
          (loop)))))

;; Start the REPL when this file is executed directly
(module+ main
  (repl))