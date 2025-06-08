#lang racket

(require "proinf-core.rkt")
(require "proinf-repl.rkt")
(require "proinf-script.rkt")

(module+ main
  (define script-file (make-parameter #f))

  (command-line
   #:program "proinf"
   #:once-each
   [("-f" "--file") file-path "ProInf script file to load before REPL"
    (script-file file-path)]
   #:args args
   (when (and (not (script-file)) (pair? args))
     (script-file (car args))))

  (when (script-file)
    (begin
      (run-script (script-file))
      (printf "\n")))

  (repl))
