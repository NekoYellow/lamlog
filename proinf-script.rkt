#lang racket

(require "proinf-core.rkt")

(provide run-script)

;; ----------------------
;; Script Parser and Executor
;; ----------------------

;; Process a single line from a script file
(define (process-script-line line)
  (with-handlers ([exn:fail? (lambda (e)
                               (printf "Error: ~a\n" (exn-message e))
                               #f)])
    (cond
      ;; Skip empty lines and comments
      [(regexp-match #px"^\\s*$" line) #t]
      [(regexp-match #px"^\\s*;;" line) #t]
      
      ;; Handle assertz command
      [(regexp-match #px"^assertz\\((.*)\\)\\.$" line)
       (define clause-str (regexp-match #px"^assertz\\((.*)\\)\\.$" line))
       (define new-clause (parse-clause (cadr clause-str)))
       (if (clause-exists? new-clause (kb-param))
           (begin
             (printf "Error: Clause already exists in the knowledge base.\n")
             #f)
           (begin
             (kb-param (append (kb-param) (list new-clause)))
             (printf "true.\n")
             #t))]
      
      ;; Handle retract command
      [(regexp-match #px"^retract\\((.*)\\)\\.$" line)
       (define clause-str (regexp-match #px"^retract\\((.*)\\)\\.$" line))
       (define clause-to-remove (parse-clause (cadr clause-str)))
       (define original-kb (kb-param))
       (define new-kb (filter (lambda (c) (not (equal? c clause-to-remove))) original-kb))
       (if (= (length original-kb) (length new-kb))
           (begin
             (printf "Error: Clause does not exist in the knowledge base.\n")
             #f)
           (begin
             (kb-param new-kb)
             (printf "true.\n")
             #t))]
      
      ;; Handle list command
      [(regexp-match #px"^list\\.$" line)
       (if (null? (kb-param))
           (printf "Knowledge base is empty.\n")
           (begin
             (printf "Current clauses in KB:\n")
             (for-each (lambda (c) (printf "  ~a\n" (pretty-print-clause c))) (kb-param))))
       #t]
      
      ;; Handle queries
      [(regexp-match #px"^\\?-\\s+(.*)\\.$" line)
       (define query-str (cadr (regexp-match #px"^\\?-\\s+(.*)\\.$" line)))
       (define goals (parse-query query-str))
       (define results (resolve (kb-param) goals '()))
       (if (null? results)
           (printf "false.\n")
           (for-each print-subst results))
       #t]
      
      ;; Unrecognized command
      [else
       (printf "Unrecognized command: ~a\n" line)
       #f])))

;; Execute a script file line by line
(define (execute-script file-path)
  (define line-count 0)
  (define success-count 0)
  
  (call-with-input-file file-path
    (lambda (port)
      (let loop ()
        (define line (read-line port))
        (unless (eof-object? line)
          (set! line-count (add1 line-count))
          (when (process-script-line line)
            (set! success-count (add1 success-count)))
          (loop)))))
  
  (printf "Executed ~a of ~a lines from ~a\n"
          success-count
          line-count
          file-path))

;; Run a script file and then optionally execute a query
(define (run-script path)
  ;; Reset knowledge base to empty
  (kb-param '())
  
  ;; Execute the script file line by line
  (execute-script path))
