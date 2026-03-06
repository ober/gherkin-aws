#!chezscheme
;;; s3-xml.sls -- S3 XML response parsing (manually ported)

(library (gerbil-aws s3-xml)
  (export s3-parse-xml sxml->hash strip-ns sxml-items sxml-text s3-response->hash)
  (import
    (except (chezscheme) hash-table? make-hash-table iota path-extension)
    (runtime hash)
    (compat misc))

  (define s3-namespaces
    '(("http://s3.amazonaws.com/doc/2006-03-01/" . "s3")
      ("http://doc.s3.amazonaws.com/2006-03-01" . "s3")))

  ;; TODO: needs a real XML->SXML parser
  (define (s3-parse-xml body)
    (error "s3-parse-xml" "XML parsing not yet implemented - needs SXML parser"))

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
