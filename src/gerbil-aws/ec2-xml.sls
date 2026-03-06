#!chezscheme
;;; ec2-xml.sls -- EC2 XML response parsing (manually ported)

(library (gerbil-aws ec2-xml)
  (export ec2-parse-xml sxml->hash strip-ns sxml-items sxml-text ec2-response->hash)
  (import
    (except (chezscheme) hash-table? make-hash-table iota path-extension filter remove partition fold-right)
    (runtime hash)
    (compat misc))

  (define ec2-namespaces
    '(("http://ec2.amazonaws.com/doc/2016-11-15/" . "ec2")))

  ;; TODO: needs a real XML->SXML parser
  (define (ec2-parse-xml body)
    (error "ec2-parse-xml" "XML parsing not yet implemented - needs SXML parser"))

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

  (define (set-element? name)
    (let ((s (symbol->string name)))
      (or (string-suffix? "Set" s)
          (string-suffix? "set" s)
          (string-suffix? "Addresses" s)
          (string-suffix? "Groups" s))))

  (define (sxml-items element)
    (if (pair? element)
      (filter (lambda (child)
                (and (pair? child)
                     (eq? (strip-ns (car child)) 'item)))
              (cdr element))
      '()))

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

  (define (ec2-response->hash xml)
    (let find ((node xml))
      (cond
        ((not (pair? node)) #f)
        ((and (pair? node) (symbol? (car node))
              (memq (car node) '(@ *NAMESPACES*)))
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
