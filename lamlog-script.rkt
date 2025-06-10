#lang racket

(require "lamlog-core.rkt")

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
      [(regexp-match #px"^(.*)\\.$" line)
       (define clause-str (regexp-match #px"^(.*)\\.$" line))
       (define clause-content (cadr clause-str))
       ;; Check for empty or malformed clause
       (if (or (string=? clause-content "")
               (regexp-match #px"^\\s*$" clause-content)
               (regexp-match #px"^\\s*\\(\\s*\\)\\s*$" clause-content))
           (begin
             (printf "Error: Empty clause.\n")
             #f)
           (let ([new-clause (parse-clause clause-content)])
                   (cond
                     [(null? new-clause)
                      (printf "Error: Empty clause.\n") #f]
                     [(and (fact? new-clause) (void? (fact-head new-clause)))
                      (printf "Error: Malformed clause.\n") #f]
                     [(clause-exists? new-clause (kb-param))
                      (printf "Error: Clause already exists in the knowledge base.\n") #f]
                     [else
                      (kb-param (append (kb-param) (list new-clause))) #t])))]
      
      ;; Handle queries
      [(regexp-match #px"^(.*)\\?$" line)
       (define query-str (cadr (regexp-match #px"^(.*)\\?$" line)))
       (define goals (parse-query query-str))
       (define results (resolve (kb-param) goals '()))
       (if (null? results)
        (printf "false.\n")
        (let ([outputs
              (remove-duplicates
                (map (lambda (r) (pretty-print-subst r goals))
                    results))])
          (printf "true.\n")
          (for-each (lambda (s) (printf "~a\n" s)) outputs)))
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
