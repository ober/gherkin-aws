#!chezscheme
;; AWS SigV4 signing compat module
;; Replaces Gerbil's :std/net/s3/sigv4
(library (compat sigv4)
  (export aws4-canonical-request aws4-auth)
  (import (chezscheme)
          (only (compat gambit) sha256 hex-encode)
          (only (compat uri) uri-encode))

  ;; Parse keyword args from a flat list: key1: val1 key2: val2 ...
  (define (kw-ref args key default)
    (let loop ([args args])
      (cond
        [(null? args) default]
        [(and (pair? (cdr args)) (eq? (car args) key))
         (cadr args)]
        [else (loop (cdr args))])))

  ;; Headers come as ((name :: value) ...) — extract name and value
  (define (header-name h)
    (if (pair? h) (car h) ""))

  (define (header-value h)
    (if (and (pair? h) (pair? (cdr h)) (pair? (cddr h)))
        (caddr h)  ;; (name :: value)
        ""))

  ;; Sort headers by lowercase name
  (define (sort-headers headers)
    ;; Flatten nested (... :: headers) structure
    (let ([flat (flatten-headers headers)])
      (list-sort
        (lambda (a b)
          (string<? (string-downcase (header-name a))
                    (string-downcase (header-name b))))
        flat)))

  (define (flatten-headers headers)
    (cond
      [(null? headers) '()]
      [(and (pair? headers) (eq? (car headers) '::))
       (flatten-headers (cdr headers))]
      [(and (pair? (car headers)) (pair? (cdar headers))
            (eq? (cadar headers) '::))
       ;; This is a header entry (name :: value)
       (cons (car headers) (flatten-headers (cdr headers)))]
      [(pair? (car headers))
       (append (flatten-headers (car headers))
               (flatten-headers (cdr headers)))]
      [else (flatten-headers (cdr headers))]))

  ;; Build canonical request per AWS SigV4 spec
  ;; aws4-canonical-request 'verb: 'POST 'uri: "/" 'query: #f 'headers: headers 'hash: body-hash
  (define (aws4-canonical-request . args)
    (let* ([verb (symbol->string (or (kw-ref args 'verb: 'GET) 'GET))]
           [uri (or (kw-ref args 'uri: "/") "/")]
           [query (kw-ref args 'query: #f)]
           [headers (or (kw-ref args 'headers: '()) '())]
           [body-hash (or (kw-ref args 'hash: #f) "")]
           [body-hash-hex (if (bytevector? body-hash)
                              (hex-encode body-hash)
                              (if (string? body-hash) body-hash ""))]
           [sorted (sort-headers headers)]
           [canonical-headers
            (apply string-append
              (map (lambda (h)
                     (string-append
                       (string-downcase (header-name h)) ":"
                       (string-trim (header-value h)) "\n"))
                   sorted))]
           [signed-headers
            (string-join
              (map (lambda (h) (string-downcase (header-name h))) sorted)
              ";")])
      (string-append
        verb "\n"
        uri "\n"
        (canonical-query-string query) "\n"
        canonical-headers "\n"
        signed-headers "\n"
        body-hash-hex)))

  ;; Build canonical query string from ((key :: value) ...) list
  (define (canonical-query-string query)
    (if (or (not query) (null? query) (equal? query ""))
        ""
        (let* ([pairs (map (lambda (p)
                             (let ([k (car p)]
                                   [v (if (and (pair? (cdr p)) (eq? (cadr p) '::))
                                          (caddr p)
                                          "")])
                               (cons (uri-encode k) (uri-encode (if (string? v) v "")))))
                           (if (list? query) query '()))]
               [sorted (list-sort (lambda (a b) (string<? (car a) (car b))) pairs)])
          (string-join
            (map (lambda (p) (string-append (car p) "=" (cdr p))) sorted)
            "&"))))

  ;; HMAC-SHA256
  (define (hmac-sha256 key data)
    (let* ([key-bv (if (string? key) (string->utf8 key) key)]
           [data-bv (if (string? data) (string->utf8 data) data)]
           [block-size 64]
           [key-bv (if (> (bytevector-length key-bv) block-size)
                       (sha256 key-bv)
                       key-bv)]
           [key-padded (make-bytevector block-size 0)])
      (bytevector-copy! key-bv 0 key-padded 0 (bytevector-length key-bv))
      (let ([o-key-pad (make-bytevector block-size)]
            [i-key-pad (make-bytevector block-size)])
        (do ([i 0 (+ i 1)])
            ((= i block-size))
          (bytevector-u8-set! o-key-pad i
            (fxlogxor (bytevector-u8-ref key-padded i) #x5c))
          (bytevector-u8-set! i-key-pad i
            (fxlogxor (bytevector-u8-ref key-padded i) #x36)))
        (sha256 (bytevector-append o-key-pad
                  (sha256 (bytevector-append i-key-pad data-bv)))))))

  (define (bytevector-append . bvs)
    (let* ([total (apply + (map bytevector-length bvs))]
           [result (make-bytevector total)])
      (let loop ([bvs bvs] [offset 0])
        (if (null? bvs) result
            (let ([bv (car bvs)])
              (bytevector-copy! bv 0 result offset (bytevector-length bv))
              (loop (cdr bvs) (+ offset (bytevector-length bv))))))))

  ;; Build AWS SigV4 Authorization header value
  ;; (aws4-auth scope creq ts headers secret-key access-key)
  (define (aws4-auth scope creq ts headers secret-key access-key)
    (let* ([sorted (sort-headers headers)]
           [signed-headers
            (string-join
              (map (lambda (h) (string-downcase (header-name h))) sorted)
              ";")]
           [string-to-sign
            (string-append
              "AWS4-HMAC-SHA256\n"
              ts "\n"
              scope "/aws4_request\n"
              (hex-encode (sha256 (string->utf8 creq))))]
           [date-key (hmac-sha256
                       (string->utf8 (string-append "AWS4" secret-key))
                       (string->utf8 (substring scope 0 8)))]
           [region-key (hmac-sha256 date-key
                         (string->utf8 (scope-part scope 1)))]
           [service-key (hmac-sha256 region-key
                          (string->utf8 (scope-part scope 2)))]
           [signing-key (hmac-sha256 service-key
                          (string->utf8 "aws4_request"))]
           [signature (hex-encode
                        (hmac-sha256 signing-key (string->utf8 string-to-sign)))])
      (string-append
        "AWS4-HMAC-SHA256 Credential=" access-key "/" scope "/aws4_request, "
        "SignedHeaders=" signed-headers ", "
        "Signature=" signature)))

  ;; Extract part of scope string "20230101/us-east-1/sts"
  ;; Split by / and return the idx-th part
  (define (scope-part scope idx)
    (let loop ([s scope] [i 0] [seg-start 0] [pos 0])
      (cond
        [(= pos (string-length s))
         (if (= i idx)
             (substring s seg-start pos)
             "")]
        [(char=? (string-ref s pos) #\/)
         (if (= i idx)
             (substring s seg-start pos)
             (loop s (+ i 1) (+ pos 1) (+ pos 1)))]
        [else (loop s i seg-start (+ pos 1))])))

  (define (string-trim s)
    (let* ([len (string-length s)]
           [start (let loop ([i 0])
                    (if (and (< i len) (char-whitespace? (string-ref s i)))
                        (loop (+ i 1)) i))]
           [end (let loop ([i (- len 1)])
                  (if (and (>= i start) (char-whitespace? (string-ref s i)))
                      (loop (- i 1)) (+ i 1)))])
      (substring s start end)))

  (define (string-join strs sep)
    (if (null? strs) ""
        (let loop ([rest (cdr strs)] [out (car strs)])
          (if (null? rest) out
              (loop (cdr rest) (string-append out sep (car rest)))))))
)
