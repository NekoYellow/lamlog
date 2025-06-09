#lang racket

(require "lamlog-core.rkt")
(require "lamlog-repl.rkt")
(require "lamlog-script.rkt")

(module+ main
  (define script-file (make-parameter #f))
  (define test-mode? (make-parameter #f))

  (command-line
   #:program "lamlog"
   #:once-each
   [("-f" "--file") file-path "LamLog script file to load before REPL"
    (script-file file-path)]
   [("-t" "--test") "Run in test mode (no REPL)"
    (test-mode? #t)]
   #:args args
   (when (and (not (script-file)) (pair? args))
     (script-file (car args))))

  (when (script-file)
    (begin
      (run-script (script-file))
      (printf "\n")))

  (unless (test-mode?)
    (repl)))
