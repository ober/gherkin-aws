#!chezscheme
;;; aws-xml.sls -- AWS XML parsing utilities (manually ported)
;;; Converts SXML to nested hash tables

(library (gerbil-aws aws-xml)
  (export aws-parse-xml sxml->hash strip-ns sxml-items sxml-text aws-response->hash
          sxml-find sxml-e?)
  (import
    (except (chezscheme) hash-table? make-hash-table iota path-extension filter remove partition fold-right)
    (runtime hash)
    (compat misc))

  ;; Parse an XML response body string into SXML
  ;; TODO: needs a real XML->SXML parser (read-xml from :std/markup/xml)
  (define (aws-parse-xml body . args)
    (error "aws-parse-xml" "XML parsing not yet implemented - needs SXML parser"))

  ;; Strip namespace prefix from a symbol (ns:foo -> foo)
  (define (strip-ns sym)
    (let* ((s (symbol->string sym))
           (len (string-length s)))
      (let loop ((i (- len 1)))
        (cond
          ((< i 0) sym)
          ((char=? (string-ref s i) #\:)
           (string->symbol (substring s (+ i 1) len)))
          (else (loop (- i 1)))))))

  ;; Get text content of an SXML element
  (define (sxml-text element)
    (and (pair? element)
         (= (length element) 2)
         (string? (cadr element))
         (cadr element)))

  ;; Check if an element name looks like a set/list container
  (define (set-element? name)
    (let ((s (symbol->string name)))
      (or (string-suffix? "Set" s)
          (string-suffix? "set" s)
          (string-suffix? "Addresses" s)
          (string-suffix? "Groups" s))))

  ;; Extract children matching a given tag name
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

  ;; Convert an SXML element to a hash table recursively
  (define (sxml->hash element)
    (cond
      ((string? element) element)
      ((not (pair? element)) #f)
      ((memq (car element) '(@ *TOP* *NAMESPACES* *PI*)) #f)
      ((sxml-text element) => (lambda (text) text))
      ((null? (cdr element)) "")
      (else
       (let* ((children (filter (lambda (c)
                                  (and (pair? c)
                                       (symbol? (car c))
                                       (not (eq? (car c) '@))))
                                (cdr element)))
              (items (sxml-items element)))
         (cond
           ((not (null? items))
            (map sxml->hash items))
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

  ;; Convert a full AWS XML response
  (define (aws-response->hash xml)
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
                 (loop (cdr children)))))))))

  ;; Find first SXML node matching predicate (depth-first)
  (define (sxml-find tree pred)
    (cond
      [(not (pair? tree)) #f]
      [(pred tree) tree]
      [else
       (let loop ([children (cdr tree)])
         (if (null? children) #f
             (or (sxml-find (car children) pred)
                 (loop (cdr children)))))]))

  ;; Create predicate matching element by tag name
  (define (sxml-e? tag)
    (lambda (node)
      (and (pair? node) (symbol? (car node)) (eq? (car node) tag))))
)
