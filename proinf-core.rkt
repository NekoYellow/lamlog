#lang racket

(provide var var? var-name
         atom atom? atom-name
         compound compound? compound-functor compound-args
         variable?
         lookup-subst apply-subst unify
         fact fact? fact-head
         rule rule? rule-head rule-body
         resolve
         symbol->term parse-term parse-query parse-clause
         pretty-print-term print-subst pretty-print-clause
         kb-param
         clause-exists? clause-conflicts?)

;; ----------------------
;; Term definitions
;; ----------------------

(struct var (name) #:transparent)
(struct atom (name) #:transparent)
(struct compound (functor args) #:transparent)

(define (variable? x) (regexp-match #px"^[A-Z]" (symbol->string x)))

;; ----------------------
;; Substitution & Unification
;; ----------------------

(define (lookup-subst x subst)
  (assoc x subst))

(define (apply-subst subst t)
  (cond
    [(var? t)
     (define entry (lookup-subst (var-name t) subst))
     (if entry (apply-subst subst (cdr entry)) t)]
    [(compound? t)
     (compound (compound-functor t)
               (map (lambda (arg) (apply-subst subst arg))
                    (compound-args t)))]
    [else t]))

;; Helper functions for variable renaming
(define (collect-vars term)
  (cond
    [(var? term) (list (var-name term))]
    [(compound? term)
     (apply append (map collect-vars (compound-args term)))]
    [else '()]))

(define (collect-vars-clause clause)
  (match clause
    [(fact h) (collect-vars h)]
    [(rule h body)
     (append (collect-vars h)
             (apply append (map collect-vars body)))]))

(define var-counter 0)

(define (fresh-var-name var-name)
  (set! var-counter (add1 var-counter))
  (string->symbol (format "~a_~a" var-name var-counter)))

(define (rename-vars-in-term term var-map)
  (cond
    [(var? term)
     (define new-name (hash-ref var-map (var-name term) #f))
     (if new-name (var new-name) term)]
    [(compound? term)
     (compound (compound-functor term)
               (map (lambda (arg) (rename-vars-in-term arg var-map))
                    (compound-args term)))]
    [else term]))

(define (rename-vars-in-clause clause)
  (define vars (collect-vars-clause clause))
  (define var-map (make-hash (map (lambda (v) (cons v (fresh-var-name v))) vars)))
  
  (match clause
    [(fact h)
     (fact (rename-vars-in-term h var-map))]
    [(rule h body)
     (rule (rename-vars-in-term h var-map)
           (map (lambda (b) (rename-vars-in-term b var-map)) body))]))

(define (unify t1 t2 subst)
  (let ([t1 (apply-subst subst t1)]
        [t2 (apply-subst subst t2)])
    (cond
      [(equal? t1 t2) subst]
      [(var? t1) (cons (cons (var-name t1) t2) subst)]
      [(var? t2) (unify t2 t1 subst)]
      [(and (atom? t1) (atom? t2))
       (if (equal? (atom-name t1) (atom-name t2)) subst #f)]
      [(and (compound? t1) (compound? t2)
            (equal? (compound-functor t1) (compound-functor t2))
            (= (length (compound-args t1)) (length (compound-args t2))))
       (foldl (lambda (p acc)
                (if acc (unify (car p) (cdr p) acc) #f))
              subst
              (map cons (compound-args t1) (compound-args t2)))]
      [else #f])))

;; ----------------------
;; Clause definitions
;; ----------------------

(struct fact (head) #:transparent)
(struct rule (head body) #:transparent)

;; ----------------------
;; Resolution
;; ----------------------

(define (resolve kb goals subst)
  (cond
    [(null? goals) (list subst)]
    [else
     (define g (car goals))
     (define rest (cdr goals))
     (apply append
            (for/list ([clause kb])
              (match clause
                [(fact h)
                 (define s (unify g h subst))
                 (if s (resolve kb rest s) '())]
                [(rule h body)
                 ;; Rename variables in the rule before unification
                 (define renamed-clause (rename-vars-in-clause clause))
                 (define renamed-h (rule-head renamed-clause))
                 (define renamed-body (rule-body renamed-clause))
                 (define s (unify g renamed-h subst))
                 (if s (resolve kb (append renamed-body rest) s) '())])))]))                 

;; ----------------------
;; Simple Parser (limited)
;; ----------------------

(define (symbol->term s)
  (cond
    [(symbol? s) (if (variable? s) (var s) (atom s))]
    [(number? s) (atom s)]
    [else (error "symbol->term: unsupported type" s)]))

(define (parse-term lst)
  (cond
    [(and (list? lst) (symbol? (car lst)))
     (compound (car lst) (map symbol->term (cdr lst)))]
    [(symbol? lst) (symbol->term lst)]))

(define (parse-query str)
  (define sexpr (with-input-from-string str read))
  (list (parse-term sexpr)))

(define (parse-clause str)
  (define sexpr (with-input-from-string str read))
  (cond
    ;; Case 1: (:- Head Body1 Body2 ...)
    [(and (list? sexpr) (equal? (car sexpr) ':-)) 
     (rule (parse-term (cadr sexpr))
           (map parse-term (cddr sexpr)))]
    ;; Case 2: (Head :- Body1 Body2 ...)
    [(and (list? sexpr) (>= (length sexpr) 3) (equal? (cadr sexpr) ':-))
     (rule (parse-term (car sexpr))
           (map parse-term (cddr sexpr)))]
    ;; Default: It's a fact
    [else (fact (parse-term sexpr))]))

;; ----------------------
;; Pretty Printer
;; ----------------------

(define (pretty-print-term t)
  (cond
    [(atom? t)
     (define n (atom-name t))
     (if (symbol? n)
         (symbol->string n)
         (format "~a" n))] ; handle numbers
    [(var? t) (symbol->string (var-name t))]
    [(compound? t)
     (string-append
      (symbol->string (compound-functor t))
      "("
      (string-join (map pretty-print-term (compound-args t)) ", ")
      ")")]))

(define (pretty-print-clause c)
  (cond
    [(fact? c) (string-append (pretty-print-term (fact-head c)) ".")]
    [(rule? c)
     (string-append
      (pretty-print-term (rule-head c))
      " :- "
      (string-join (map pretty-print-term (rule-body c)) ", ")
      ".")]
    [else "(unknown clause)"]))

(define (print-subst subst)
  (for-each (lambda (pair)
              (printf "~a = ~a\n"
                      (symbol->string (car pair))
                      (pretty-print-term (cdr pair))))
            subst))

;; ----------------------
;; Knowledge Base Parameter
;; ----------------------

;; Use a parameter for the knowledge base
(define kb-param
  (make-parameter
   '()))

;; After the kb-param definition, add this helper function

;; ----------------------
;; Knowledge Base Helpers
;; ----------------------

;; Check if a clause already exists in the knowledge base
(define (clause-exists? clause kb)
  (for/or ([existing-clause kb])
    (equal? clause existing-clause)))

;; Check if a clause conflicts with the current knowledge base
(define (clause-conflicts? clause kb)
  (define head
    (cond
      [(fact? clause) (fact-head clause)]
      [(rule? clause) (rule-head clause)]))
  (define result (resolve kb (list head) '()))
  (not (null? result)))
