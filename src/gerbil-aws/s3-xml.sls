#!chezscheme
;;; s3-xml.sls -- S3 XML response parsing (manually ported)

(library (gerbil-aws s3-xml)
  (export s3-parse-xml sxml->hash strip-ns sxml-items sxml-text s3-response->hash)
  (import
    (except (chezscheme) hash-table? make-hash-table iota path-extension
      filter remove partition fold-right)
    (runtime hash)
    (compat misc))

  (define s3-namespaces
    '(("http://s3.amazonaws.com/doc/2006-03-01/" . "s3")
      ("http://doc.s3.amazonaws.com/2006-03-01" . "s3")))

  ;; Simple XML -> SXML parser for S3 responses
  (define (s3-parse-xml body)
    (let ([len (string-length body)] [pos 0])
      (define (peek) (if (< pos len) (string-ref body pos) #\nul))
      (define (advance!) (set! pos (+ pos 1)))
      (define (skip-ws!) (let loop () (when (and (< pos len) (char-whitespace? (peek))) (advance!) (loop))))
      (define (read-until c)
        (let ([start pos]) (let loop () (cond [(>= pos len) (substring body start pos)] [(char=? (peek) c) (substring body start pos)] [else (advance!) (loop)]))))
      (define (read-name)
        (let ([start pos]) (let loop () (if (and (< pos len) (let ([c (peek)]) (or (char-alphabetic? c) (char-numeric? c) (memv c '(#\- #\_ #\: #\.))))) (begin (advance!) (loop)) (substring body start pos)))))
      (define (read-text)
        (let ([out (open-output-string)])
          (let loop () (cond [(>= pos len) (get-output-string out)] [(char=? (peek) #\<) (get-output-string out)]
            [(char=? (peek) #\&) (advance!) (let ([ent (read-until #\;)]) (advance!) (cond [(string=? ent "amp") (write-char #\& out)] [(string=? ent "lt") (write-char #\< out)] [(string=? ent "gt") (write-char #\> out)] [(string=? ent "quot") (write-char #\" out)] [(string=? ent "apos") (write-char #\' out)] [else (display "&" out) (display ent out) (display ";" out)]) (loop))]
            [else (write-char (peek) out) (advance!) (loop)]))))
      (define (skip-pi!)
        (cond
          [(and (< (+ pos 1) len) (char=? (string-ref body (+ pos 1)) #\?))
           (let loop () (cond [(>= pos len) (void)] [(and (char=? (peek) #\?) (< (+ pos 1) len) (char=? (string-ref body (+ pos 1)) #\>)) (advance!) (advance!)] [else (advance!) (loop)]))]
          [(and (< (+ pos 1) len) (char=? (string-ref body (+ pos 1)) #\!))
           (advance!) (advance!)
           (if (and (< (+ pos 1) len) (char=? (peek) #\-) (char=? (string-ref body (+ pos 1)) #\-))
               (begin (advance!) (advance!) (let loop () (cond [(>= pos len) (void)] [(and (char=? (peek) #\-) (< (+ pos 2) len) (char=? (string-ref body (+ pos 1)) #\-) (char=? (string-ref body (+ pos 2)) #\>)) (advance!) (advance!) (advance!)] [else (advance!) (loop)])))
               (let loop ([d 1]) (cond [(>= pos len) (void)] [(char=? (peek) #\>) (advance!) (when (> d 1) (loop (- d 1)))] [(char=? (peek) #\<) (advance!) (loop (+ d 1))] [else (advance!) (loop d)])))]))
      (define (parse-element)
        (skip-ws!)
        (cond [(>= pos len) #f] [(not (char=? (peek) #\<)) #f]
          [(and (< (+ pos 1) len) (or (char=? (string-ref body (+ pos 1)) #\?) (char=? (string-ref body (+ pos 1)) #\!))) (skip-pi!) (parse-element)]
          [(and (< (+ pos 1) len) (char=? (string-ref body (+ pos 1)) #\/)) #f]
          [else (advance!) (let ([name (read-name)]) (skip-ws!)
            (let ([attrs '()])
              (let attr-loop () (skip-ws!) (cond [(>= pos len) (void)] [(or (char=? (peek) #\>) (char=? (peek) #\/)) (void)]
                [else (let ([an (read-name)]) (skip-ws!) (when (and (< pos len) (char=? (peek) #\=)) (advance!) (skip-ws!) (when (and (< pos len) (char=? (peek) #\")) (advance!) (let ([v (read-until #\")]) (advance!) (set! attrs (cons (list (string->symbol an) v) attrs))))) (attr-loop))]))
              (cond [(and (< pos len) (char=? (peek) #\/)) (advance!) (when (and (< pos len) (char=? (peek) #\>)) (advance!))
                     (if (null? attrs) (list (string->symbol name)) (list (string->symbol name) (cons '@ (reverse attrs))))]
                [else (when (and (< pos len) (char=? (peek) #\>)) (advance!))
                  (let ([children '()])
                    (let child-loop () (cond [(>= pos len) (void)]
                      [(and (char=? (peek) #\<) (< (+ pos 1) len) (char=? (string-ref body (+ pos 1)) #\/))
                       (advance!) (advance!) (read-name) (skip-ws!) (when (and (< pos len) (char=? (peek) #\>)) (advance!))]
                      [(char=? (peek) #\<) (let ([ch (parse-element)]) (when ch (set! children (cons ch children))) (child-loop))]
                      [else (let ([t (read-text)]) (when (not (string=? (strim t) "")) (set! children (cons t children))) (child-loop))]))
                    (let ([nc (reverse children)])
                      (if (null? attrs) (cons (string->symbol name) nc)
                          (cons (string->symbol name) (cons (cons '@ (reverse attrs)) nc)))))])))]))
      (define (strim s)
        (let* ([len (string-length s)]
               [start (let loop ([i 0]) (if (and (< i len) (char-whitespace? (string-ref s i))) (loop (+ i 1)) i))]
               [end (let loop ([i (- len 1)]) (if (and (>= i start) (char-whitespace? (string-ref s i))) (loop (- i 1)) (+ i 1)))])
          (substring s start end)))
      (let ([root (parse-element)]) (if root (list '*TOP* root) (list '*TOP*)))))

  (define (strip-ns sym)
    (let* ((s (symbol->string sym))
           (pos (string-contains s ":")))
      (if pos
        (string->symbol (substring s (+ pos 1) (string-length s)))
        sym)))

  (define (sxml-text element)
    (and (pair? element)
         (= (length element) 2)
         (string? (cadr element))
         (cadr element)))

  (define sxml-items
    (case-lambda
      ((element) (sxml-items element #f))
      ((element tag)
       (if (pair? element)
         (filter (lambda (child)
                   (and (pair? child)
                        (symbol? (car child))
                        (if tag
                          (eq? (strip-ns (car child)) tag)
                          (eq? (strip-ns (car child)) 'item))))
                 (cdr element))
         '()))))

  (define (sxml->hash element)
    (cond
      ((string? element) element)
      ((not (pair? element)) #f)
      ((memq (car element) '(@ *TOP* *NAMESPACES*)) #f)
      ((sxml-text element) => (lambda (text) text))
      ((null? (cdr element)) "")
      (else
       (let* ((children (filter (lambda (c)
                                  (and (pair? c)
                                       (symbol? (car c))
                                       (not (eq? (car c) '@))))
                                (cdr element))))
         (cond
           ((null? children) "")
           ((and (= (length (cdr element)) 1)
                 (string? (cadr element)))
            (cadr element))
           (else
            (let ((ht (make-hash-table)))
              (for-each
                (lambda (child)
                  (let* ((key (strip-ns (car child)))
                         (val (sxml->hash child)))
                    (when val
                      (let ((existing (hash-get ht key)))
                        (if existing
                          (if (list? existing)
                            (hash-put! ht key (append existing (list val)))
                            (hash-put! ht key (list existing val)))
                          (hash-put! ht key val))))))
                children)
              ht)))))))

  (define (s3-response->hash xml)
    (let find ((node xml))
      (cond
        ((not (pair? node)) #f)
        ((and (pair? node) (symbol? (car node))
              (memq (car node) '(@ *NAMESPACES* *PI*)))
         #f)
        ((and (pair? node) (symbol? (car node))
              (not (eq? (car node) '*TOP*)))
         (sxml->hash node))
        (else
         (let loop ((children (if (pair? node) (cdr node) '())))
           (if (null? children)
             #f
             (or (find (car children))
                 (loop (cdr children))))))))))
