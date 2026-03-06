#!chezscheme
(library (gerbil-aws s3-api)
  (export s3-client s3-client? s3-client-endpoint
    s3-client-access-key s3-client-secret-key s3-client-region
    s3-client-token S3Client S3ClientError s3-client-error?
    s3-request s3-request/xml s3-request/check)
  (import
    (except (chezscheme) box box? unbox set-box! andmap ormap
     iota last-pair find \x31;+ \x31;- fx/ fx1+ fx1- error error?
     raise with-exception-handler identifier? hash-table?
     make-hash-table sort sort! path-extension printf fprintf
     file-directory? file-exists? getenv close-port void
     open-output-file open-input-file)
    (compat types)
    (except (runtime util) string->bytes bytes->string
      string-split string-join find string-index pgetq pgetv pget)
    (except (runtime table) string-hash)
    (except (runtime mop) class-type-flag-system
     class-type-flag-metaclass class-type-flag-sealed
     class-type-flag-struct type-flag-id type-flag-concrete
     type-flag-macros type-flag-extensible type-flag-opaque
     \x23;\x23;type-fields \x23;\x23;type-super
     \x23;\x23;type-flags \x23;\x23;type-name \x23;\x23;type-id
     \x23;\x23;structure-copy
     \x23;\x23;structure-direct-instance-of?
     \x23;\x23;structure-instance-of?
     \x23;\x23;unchecked-structure-set!
     \x23;\x23;unchecked-structure-ref \x23;\x23;structure-set!
     \x23;\x23;structure-ref \x23;\x23;structure-type-set!
     \x23;\x23;structure-type \x23;\x23;structure?
     \x23;\x23;structure)
    (except (runtime error) with-catch with-exception-catcher)
    (runtime hash)
    (except
      (compat gambit)
      number->string
      make-mutex
      with-output-to-string)
    (except (compat misc) last iota string-empty?
      fold-right remove partition filter)
    (compat sugar) (compat request) (compat uri) (compat sigv4)
    (except (compat std-srfi-19) time->seconds)
    (gerbil-aws aws-creds) (gerbil-aws s3-xml))
  (begin
    (define s3-client::t
      (make-class-type 'gerbil\x23;s3-client::t 's3-client (list object::t)
        '(endpoint access-key secret-key region token)
        '((struct: . #t)) #f))
    (define (make-s3-client . args)
      (let* ([type s3-client::t]
             [all-slots (cdr (vector->list
                               (class-type-slot-vector type)))]
             [obj (make-class-instance type)])
        (let lp ([slots all-slots] [rest args] [i 1])
          (when (and (pair? slots) (pair? rest))
            (\x23;\x23;structure-set! obj i (car rest))
            (lp (cdr slots) (cdr rest) (+ i 1))))
        obj))
    (define (s3-client? obj)
      (\x23;\x23;structure-instance-of?
        obj
        'gerbil\x23;s3-client::t))
    (define (s3-client-endpoint obj) (slot-ref obj 'endpoint))
    (define (s3-client-access-key obj)
      (slot-ref obj 'access-key))
    (define (s3-client-secret-key obj)
      (slot-ref obj 'secret-key))
    (define (s3-client-region obj) (slot-ref obj 'region))
    (define (s3-client-token obj) (slot-ref obj 'token))
    (define (s3-client-endpoint-set! obj val)
      (slot-set! obj 'endpoint val))
    (define (s3-client-access-key-set! obj val)
      (slot-set! obj 'access-key val))
    (define (s3-client-secret-key-set! obj val)
      (slot-set! obj 'secret-key val))
    (define (s3-client-region-set! obj val)
      (slot-set! obj 'region val))
    (define (s3-client-token-set! obj val)
      (slot-set! obj 'token val)))
  (define s3-client make-s3-client)
  (define emptySHA256 (sha256 #vu8()))
  (define (S3Client . args)
    (let* ([endpoint (pgetq 'endpoint: args)]
           [profile (pgetq 'profile: args)]
           [access-key (pgetq 'access-key: args)]
           [secret-key (pgetq 'secret-key: args)]
           [region (pgetq 'region: args)]
           [token (pgetq 'token: args)])
      (let-values ([(resolved-access-key resolved-secret-key resolved-region resolved-token)
                    (aws-resolve-credentials profile)])
        (let ([access-key (or access-key resolved-access-key)]
              [secret-key (or secret-key resolved-secret-key)]
              [region (or region resolved-region)]
              [token (or token resolved-token)])
          (unless access-key
            (raise-s3-error 'S3Client "Must provide access key" "access-key"))
          (unless secret-key
            (raise-s3-error 'S3Client "Must provide secret key" "secret-key"))
          (make-s3-client (or endpoint "s3.amazonaws.com") access-key secret-key region token)))))
  #|
  ;; Original case-lambda removed
  (define S3Client-original
    (case-lambda
      [()
       (let* ([endpoint #f]
              [profile #f]
              [access-key #f]
              [secret-key #f]
              [region #f]
              [token #f])
         (let-values ([(resolved-access-key resolved-secret-key resolved-region resolved-token)
                       (aws-resolve-credentials profile)])
           (let ([access-key (or access-key resolved-access-key)]
                 [secret-key (or secret-key resolved-secret-key)]
                 [region (or region resolved-region)]
                 [token (or token resolved-token)]
                 [endpoint (or endpoint "s3.amazonaws.com")])
             (unless access-key
               (raise-s3-error
                 S3Client
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-s3-error
                 S3Client
                 "Must provide secret key"
                 "secret-key"))
             (make-s3-client (or endpoint "s3.amazonaws.com") access-key secret-key region
               token))))]
      [(endpoint)
       (let* ([profile #f]
              [access-key #f]
              [secret-key #f]
              [region #f]
              [token #f])
         (let-values ([(resolved-access-key resolved-secret-key resolved-region resolved-token)
                       (aws-resolve-credentials profile)])
           (let ([access-key (or access-key resolved-access-key)]
                 [secret-key (or secret-key resolved-secret-key)]
                 [region (or region resolved-region)]
                 [token (or token resolved-token)]
                 [endpoint (or endpoint "s3.amazonaws.com")])
             (unless access-key
               (raise-s3-error
                 S3Client
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-s3-error
                 S3Client
                 "Must provide secret key"
                 "secret-key"))
             (make-s3-client (or endpoint "s3.amazonaws.com") access-key secret-key region
               token))))]
      [(endpoint profile)
       (let* ([access-key #f]
              [secret-key #f]
              [region #f]
              [token #f])
         (let-values ([(resolved-access-key resolved-secret-key resolved-region resolved-token)
                       (aws-resolve-credentials profile)])
           (let ([access-key (or access-key resolved-access-key)]
                 [secret-key (or secret-key resolved-secret-key)]
                 [region (or region resolved-region)]
                 [token (or token resolved-token)]
                 [endpoint (or endpoint "s3.amazonaws.com")])
             (unless access-key
               (raise-s3-error
                 S3Client
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-s3-error
                 S3Client
                 "Must provide secret key"
                 "secret-key"))
             (make-s3-client (or endpoint "s3.amazonaws.com") access-key secret-key region
               token))))]
      [(endpoint profile access-key)
       (let* ([secret-key #f] [region #f] [token #f])
         (let-values ([(resolved-access-key resolved-secret-key resolved-region resolved-token)
                       (aws-resolve-credentials profile)])
           (let ([access-key (or access-key resolved-access-key)]
                 [secret-key (or secret-key resolved-secret-key)]
                 [region (or region resolved-region)]
                 [token (or token resolved-token)]
                 [endpoint (or endpoint "s3.amazonaws.com")])
             (unless access-key
               (raise-s3-error
                 S3Client
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-s3-error
                 S3Client
                 "Must provide secret key"
                 "secret-key"))
             (make-s3-client (or endpoint "s3.amazonaws.com") access-key secret-key region
               token))))]
      [(endpoint profile access-key secret-key)
       (let* ([region #f] [token #f])
         (let-values ([(resolved-access-key resolved-secret-key resolved-region resolved-token)
                       (aws-resolve-credentials profile)])
           (let ([access-key (or access-key resolved-access-key)]
                 [secret-key (or secret-key resolved-secret-key)]
                 [region (or region resolved-region)]
                 [token (or token resolved-token)]
                 [endpoint (or endpoint "s3.amazonaws.com")])
             (unless access-key
               (raise-s3-error
                 S3Client
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-s3-error
                 S3Client
                 "Must provide secret key"
                 "secret-key"))
             (make-s3-client (or endpoint "s3.amazonaws.com") access-key secret-key region
               token))))]
      [(endpoint profile access-key secret-key region)
       (let* ([token #f])
         (let-values ([(resolved-access-key resolved-secret-key resolved-region resolved-token)
                       (aws-resolve-credentials profile)])
           (let ([access-key (or access-key resolved-access-key)]
                 [secret-key (or secret-key resolved-secret-key)]
                 [region (or region resolved-region)]
                 [token (or token resolved-token)]
                 [endpoint (or endpoint "s3.amazonaws.com")])
             (unless access-key
               (raise-s3-error
                 S3Client
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-s3-error
                 S3Client
                 "Must provide secret key"
                 "secret-key"))
             (make-s3-client (or endpoint "s3.amazonaws.com") access-key secret-key region
               token))))]
      [(endpoint profile access-key secret-key region token)
       (let-values ([(resolved-access-key resolved-secret-key resolved-region resolved-token)
                     (aws-resolve-credentials profile)])
         (let ([access-key (or access-key resolved-access-key)]
               [secret-key (or secret-key resolved-secret-key)]
               [region (or region resolved-region)]
               [token (or token resolved-token)]
               [endpoint (or endpoint "s3.amazonaws.com")])
           (unless access-key
             (raise-s3-error
               S3Client
               "Must provide access key"
               "access-key"))
           (unless secret-key
             (raise-s3-error
               S3Client
               "Must provide secret key"
               "secret-key"))
           (make-s3-client endpoint access-key secret-key region
             token)))]))
  |#
  (define (s3-request client . args)
    (let* ([verb (or (pgetq 'verb: args) 'GET)]
           [bucket (pgetq 'bucket: args)]
           [key (pgetq 'key: args)]
           [query (pgetq 'query: args)]
           [body (pgetq 'body: args)]
           [content-type (pgetq 'content-type: args)]
           [extra-headers (or (pgetq 'extra-headers: args) (list))])
      (let* ([now (current-date 0)]
                  [ts (date->string now "~Y~m~dT~H~M~SZ")]
                  [scopets (date->string now "~Y~m~d")]
                  [scope (string-append
                           scopets
                           "/"
                           (slot-ref client 'region)
                           "/s3")]
                  [body-bytes (cond
                                [(not body) #f]
                                [(u8vector? body) body]
                                [(string? body) (string->bytes body)]
                                [else
                                 (error "body must be string or u8vector"
                                   body)])]
                  [body-hash (if body-bytes
                                 (sha256 body-bytes)
                                 emptySHA256)]
                  [host (if bucket
                            (string-append
                              bucket
                              "."
                              (slot-ref client 'endpoint))
                            (slot-ref client 'endpoint))]
                  [path (if key (string-append "/" key) "/")]
                  [headers (list
                             (list "Host" ':: host)
                             (list "x-amz-date" ':: ts)
                             (list
                               "x-amz-content-sha256"
                               '::
                               (hex-encode body-hash)))]
                  [headers (if content-type
                               (append
                                 headers
                                 (list
                                   (list "Content-Type" ':: content-type)))
                               headers)]
                  [headers (if (slot-ref client 'token)
                               (append
                                 headers
                                 (list
                                   (list
                                     "X-Amz-Security-Token"
                                     '::
                                     (slot-ref client 'token))))
                               headers)]
                  [headers (if (null? extra-headers)
                               headers
                               (append headers extra-headers))]
                  [creq (aws4-canonical-request 'verb: verb 'uri: path 'query: query 'headers:
                          headers 'hash: body-hash)]
                  [auth (aws4-auth scope creq ts headers
                          (slot-ref client 'secret-key)
                          (slot-ref client 'access-key))]
                  [headers (list
                             (list "Authorization" ':: auth)
                             '::
                             headers)]
                  [url (string-append "https://" host path)])
             (case verb
               [(GET) (http-get url 'headers: headers 'params: query)]
               [(PUT)
                (http-put url 'headers: headers 'params: query 'data:
                  (or body-bytes ""))]
               [(DELETE)
                (http-delete url 'headers: headers 'params: query)]
               [(HEAD) (http-head url 'headers: headers 'params: query)]
               [else (error "Bad request verb" verb)]))))
  #|
  ;; remaining case-lambda clauses removed (keyword dispatch)
      [(client verb)
       (let* ([bucket #f]
              [key #f]
              [query #f]
              [body #f]
              [content-type #f]
              [extra-headers (list)])
         (let ([client client])
           (let* ([now (current-date 0)]
                  [ts (date->string now "~Y~m~dT~H~M~SZ")]
                  [scopets (date->string now "~Y~m~d")]
                  [scope (string-append
                           scopets
                           "/"
                           (slot-ref client 'region)
                           "/s3")]
                  [body-bytes (cond
                                [(not body) #f]
                                [(u8vector? body) body]
                                [(string? body) (string->bytes body)]
                                [else
                                 (error "body must be string or u8vector"
                                   body)])]
                  [body-hash (if body-bytes
                                 (sha256 body-bytes)
                                 emptySHA256)]
                  [host (if bucket
                            (string-append
                              bucket
                              "."
                              (slot-ref client 'endpoint))
                            (slot-ref client 'endpoint))]
                  [path (if key (string-append "/" key) "/")]
                  [headers (list
                             (list "Host" ':: host)
                             (list "x-amz-date" ':: ts)
                             (list
                               "x-amz-content-sha256"
                               '::
                               (hex-encode body-hash)))]
                  [headers (if content-type
                               (append
                                 headers
                                 (list
                                   (list "Content-Type" ':: content-type)))
                               headers)]
                  [headers (if (slot-ref client 'token)
                               (append
                                 headers
                                 (list
                                   (list
                                     "X-Amz-Security-Token"
                                     '::
                                     (slot-ref client 'token))))
                               headers)]
                  [headers (if (null? extra-headers)
                               headers
                               (append headers extra-headers))]
                  [creq (aws4-canonical-request 'verb: verb 'uri: path 'query: query 'headers:
                          headers 'hash: body-hash)]
                  [auth (aws4-auth scope creq ts headers
                          (slot-ref client 'secret-key)
                          (slot-ref client 'access-key))]
                  [headers (list
                             (list "Authorization" ':: auth)
                             '::
                             headers)]
                  [url (string-append "https://" host path)])
             (case verb
               [(GET) (http-get url 'headers: headers 'params: query)]
               [(PUT)
                (http-put url 'headers: headers 'params: query 'data:
                  (or body-bytes ""))]
               [(DELETE)
                (http-delete url 'headers: headers 'params: query)]
               [(HEAD) (http-head url 'headers: headers 'params: query)]
               [else (error "Bad request verb" verb)]))))]
      [(client verb bucket)
       (let* ([key #f]
              [query #f]
              [body #f]
              [content-type #f]
              [extra-headers (list)])
         (let ([client client])
           (let* ([now (current-date 0)]
                  [ts (date->string now "~Y~m~dT~H~M~SZ")]
                  [scopets (date->string now "~Y~m~d")]
                  [scope (string-append
                           scopets
                           "/"
                           (slot-ref client 'region)
                           "/s3")]
                  [body-bytes (cond
                                [(not body) #f]
                                [(u8vector? body) body]
                                [(string? body) (string->bytes body)]
                                [else
                                 (error "body must be string or u8vector"
                                   body)])]
                  [body-hash (if body-bytes
                                 (sha256 body-bytes)
                                 emptySHA256)]
                  [host (if bucket
                            (string-append
                              bucket
                              "."
                              (slot-ref client 'endpoint))
                            (slot-ref client 'endpoint))]
                  [path (if key (string-append "/" key) "/")]
                  [headers (list
                             (list "Host" ':: host)
                             (list "x-amz-date" ':: ts)
                             (list
                               "x-amz-content-sha256"
                               '::
                               (hex-encode body-hash)))]
                  [headers (if content-type
                               (append
                                 headers
                                 (list
                                   (list "Content-Type" ':: content-type)))
                               headers)]
                  [headers (if (slot-ref client 'token)
                               (append
                                 headers
                                 (list
                                   (list
                                     "X-Amz-Security-Token"
                                     '::
                                     (slot-ref client 'token))))
                               headers)]
                  [headers (if (null? extra-headers)
                               headers
                               (append headers extra-headers))]
                  [creq (aws4-canonical-request 'verb: verb 'uri: path 'query: query 'headers:
                          headers 'hash: body-hash)]
                  [auth (aws4-auth scope creq ts headers
                          (slot-ref client 'secret-key)
                          (slot-ref client 'access-key))]
                  [headers (list
                             (list "Authorization" ':: auth)
                             '::
                             headers)]
                  [url (string-append "https://" host path)])
             (case verb
               [(GET) (http-get url 'headers: headers 'params: query)]
               [(PUT)
                (http-put url 'headers: headers 'params: query 'data:
                  (or body-bytes ""))]
               [(DELETE)
                (http-delete url 'headers: headers 'params: query)]
               [(HEAD) (http-head url 'headers: headers 'params: query)]
               [else (error "Bad request verb" verb)]))))]
      [(client verb bucket key)
       (let* ([query #f]
              [body #f]
              [content-type #f]
              [extra-headers (list)])
         (let ([client client])
           (let* ([now (current-date 0)]
                  [ts (date->string now "~Y~m~dT~H~M~SZ")]
                  [scopets (date->string now "~Y~m~d")]
                  [scope (string-append
                           scopets
                           "/"
                           (slot-ref client 'region)
                           "/s3")]
                  [body-bytes (cond
                                [(not body) #f]
                                [(u8vector? body) body]
                                [(string? body) (string->bytes body)]
                                [else
                                 (error "body must be string or u8vector"
                                   body)])]
                  [body-hash (if body-bytes
                                 (sha256 body-bytes)
                                 emptySHA256)]
                  [host (if bucket
                            (string-append
                              bucket
                              "."
                              (slot-ref client 'endpoint))
                            (slot-ref client 'endpoint))]
                  [path (if key (string-append "/" key) "/")]
                  [headers (list
                             (list "Host" ':: host)
                             (list "x-amz-date" ':: ts)
                             (list
                               "x-amz-content-sha256"
                               '::
                               (hex-encode body-hash)))]
                  [headers (if content-type
                               (append
                                 headers
                                 (list
                                   (list "Content-Type" ':: content-type)))
                               headers)]
                  [headers (if (slot-ref client 'token)
                               (append
                                 headers
                                 (list
                                   (list
                                     "X-Amz-Security-Token"
                                     '::
                                     (slot-ref client 'token))))
                               headers)]
                  [headers (if (null? extra-headers)
                               headers
                               (append headers extra-headers))]
                  [creq (aws4-canonical-request 'verb: verb 'uri: path 'query: query 'headers:
                          headers 'hash: body-hash)]
                  [auth (aws4-auth scope creq ts headers
                          (slot-ref client 'secret-key)
                          (slot-ref client 'access-key))]
                  [headers (list
                             (list "Authorization" ':: auth)
                             '::
                             headers)]
                  [url (string-append "https://" host path)])
             (case verb
               [(GET) (http-get url 'headers: headers 'params: query)]
               [(PUT)
                (http-put url 'headers: headers 'params: query 'data:
                  (or body-bytes ""))]
               [(DELETE)
                (http-delete url 'headers: headers 'params: query)]
               [(HEAD) (http-head url 'headers: headers 'params: query)]
               [else (error "Bad request verb" verb)]))))]
      [(client verb bucket key query)
       (let* ([body #f] [content-type #f] [extra-headers (list)])
         (let ([client client])
           (let* ([now (current-date 0)]
                  [ts (date->string now "~Y~m~dT~H~M~SZ")]
                  [scopets (date->string now "~Y~m~d")]
                  [scope (string-append
                           scopets
                           "/"
                           (slot-ref client 'region)
                           "/s3")]
                  [body-bytes (cond
                                [(not body) #f]
                                [(u8vector? body) body]
                                [(string? body) (string->bytes body)]
                                [else
                                 (error "body must be string or u8vector"
                                   body)])]
                  [body-hash (if body-bytes
                                 (sha256 body-bytes)
                                 emptySHA256)]
                  [host (if bucket
                            (string-append
                              bucket
                              "."
                              (slot-ref client 'endpoint))
                            (slot-ref client 'endpoint))]
                  [path (if key (string-append "/" key) "/")]
                  [headers (list
                             (list "Host" ':: host)
                             (list "x-amz-date" ':: ts)
                             (list
                               "x-amz-content-sha256"
                               '::
                               (hex-encode body-hash)))]
                  [headers (if content-type
                               (append
                                 headers
                                 (list
                                   (list "Content-Type" ':: content-type)))
                               headers)]
                  [headers (if (slot-ref client 'token)
                               (append
                                 headers
                                 (list
                                   (list
                                     "X-Amz-Security-Token"
                                     '::
                                     (slot-ref client 'token))))
                               headers)]
                  [headers (if (null? extra-headers)
                               headers
                               (append headers extra-headers))]
                  [creq (aws4-canonical-request 'verb: verb 'uri: path 'query: query 'headers:
                          headers 'hash: body-hash)]
                  [auth (aws4-auth scope creq ts headers
                          (slot-ref client 'secret-key)
                          (slot-ref client 'access-key))]
                  [headers (list
                             (list "Authorization" ':: auth)
                             '::
                             headers)]
                  [url (string-append "https://" host path)])
             (case verb
               [(GET) (http-get url 'headers: headers 'params: query)]
               [(PUT)
                (http-put url 'headers: headers 'params: query 'data:
                  (or body-bytes ""))]
               [(DELETE)
                (http-delete url 'headers: headers 'params: query)]
               [(HEAD) (http-head url 'headers: headers 'params: query)]
               [else (error "Bad request verb" verb)]))))]
      [(client verb bucket key query body)
       (let* ([content-type #f] [extra-headers (list)])
         (let ([client client])
           (let* ([now (current-date 0)]
                  [ts (date->string now "~Y~m~dT~H~M~SZ")]
                  [scopets (date->string now "~Y~m~d")]
                  [scope (string-append
                           scopets
                           "/"
                           (slot-ref client 'region)
                           "/s3")]
                  [body-bytes (cond
                                [(not body) #f]
                                [(u8vector? body) body]
                                [(string? body) (string->bytes body)]
                                [else
                                 (error "body must be string or u8vector"
                                   body)])]
                  [body-hash (if body-bytes
                                 (sha256 body-bytes)
                                 emptySHA256)]
                  [host (if bucket
                            (string-append
                              bucket
                              "."
                              (slot-ref client 'endpoint))
                            (slot-ref client 'endpoint))]
                  [path (if key (string-append "/" key) "/")]
                  [headers (list
                             (list "Host" ':: host)
                             (list "x-amz-date" ':: ts)
                             (list
                               "x-amz-content-sha256"
                               '::
                               (hex-encode body-hash)))]
                  [headers (if content-type
                               (append
                                 headers
                                 (list
                                   (list "Content-Type" ':: content-type)))
                               headers)]
                  [headers (if (slot-ref client 'token)
                               (append
                                 headers
                                 (list
                                   (list
                                     "X-Amz-Security-Token"
                                     '::
                                     (slot-ref client 'token))))
                               headers)]
                  [headers (if (null? extra-headers)
                               headers
                               (append headers extra-headers))]
                  [creq (aws4-canonical-request 'verb: verb 'uri: path 'query: query 'headers:
                          headers 'hash: body-hash)]
                  [auth (aws4-auth scope creq ts headers
                          (slot-ref client 'secret-key)
                          (slot-ref client 'access-key))]
                  [headers (list
                             (list "Authorization" ':: auth)
                             '::
                             headers)]
                  [url (string-append "https://" host path)])
             (case verb
               [(GET) (http-get url 'headers: headers 'params: query)]
               [(PUT)
                (http-put url 'headers: headers 'params: query 'data:
                  (or body-bytes ""))]
               [(DELETE)
                (http-delete url 'headers: headers 'params: query)]
               [(HEAD) (http-head url 'headers: headers 'params: query)]
               [else (error "Bad request verb" verb)]))))]
      [(client verb bucket key query body content-type)
       (let* ([extra-headers (list)])
         (let ([client client])
           (let* ([now (current-date 0)]
                  [ts (date->string now "~Y~m~dT~H~M~SZ")]
                  [scopets (date->string now "~Y~m~d")]
                  [scope (string-append
                           scopets
                           "/"
                           (slot-ref client 'region)
                           "/s3")]
                  [body-bytes (cond
                                [(not body) #f]
                                [(u8vector? body) body]
                                [(string? body) (string->bytes body)]
                                [else
                                 (error "body must be string or u8vector"
                                   body)])]
                  [body-hash (if body-bytes
                                 (sha256 body-bytes)
                                 emptySHA256)]
                  [host (if bucket
                            (string-append
                              bucket
                              "."
                              (slot-ref client 'endpoint))
                            (slot-ref client 'endpoint))]
                  [path (if key (string-append "/" key) "/")]
                  [headers (list
                             (list "Host" ':: host)
                             (list "x-amz-date" ':: ts)
                             (list
                               "x-amz-content-sha256"
                               '::
                               (hex-encode body-hash)))]
                  [headers (if content-type
                               (append
                                 headers
                                 (list
                                   (list "Content-Type" ':: content-type)))
                               headers)]
                  [headers (if (slot-ref client 'token)
                               (append
                                 headers
                                 (list
                                   (list
                                     "X-Amz-Security-Token"
                                     '::
                                     (slot-ref client 'token))))
                               headers)]
                  [headers (if (null? extra-headers)
                               headers
                               (append headers extra-headers))]
                  [creq (aws4-canonical-request 'verb: verb 'uri: path 'query: query 'headers:
                          headers 'hash: body-hash)]
                  [auth (aws4-auth scope creq ts headers
                          (slot-ref client 'secret-key)
                          (slot-ref client 'access-key))]
                  [headers (list
                             (list "Authorization" ':: auth)
                             '::
                             headers)]
                  [url (string-append "https://" host path)])
             (case verb
               [(GET) (http-get url 'headers: headers 'params: query)]
               [(PUT)
                (http-put url 'headers: headers 'params: query 'data:
                  (or body-bytes ""))]
               [(DELETE)
                (http-delete url 'headers: headers 'params: query)]
               [(HEAD) (http-head url 'headers: headers 'params: query)]
               [else (error "Bad request verb" verb)]))))]
      [(client verb bucket key query body content-type
        extra-headers)
       (let ([client client])
         (let* ([now (current-date 0)]
                [ts (date->string now "~Y~m~dT~H~M~SZ")]
                [scopets (date->string now "~Y~m~d")]
                [scope (string-append
                         scopets
                         "/"
                         (slot-ref client 'region)
                         "/s3")]
                [body-bytes (cond
                              [(not body) #f]
                              [(u8vector? body) body]
                              [(string? body) (string->bytes body)]
                              [else
                               (error "body must be string or u8vector"
                                 body)])]
                [body-hash (if body-bytes (sha256 body-bytes) emptySHA256)]
                [host (if bucket
                          (string-append
                            bucket
                            "."
                            (slot-ref client 'endpoint))
                          (slot-ref client 'endpoint))]
                [path (if key (string-append "/" key) "/")]
                [headers (list
                           (list "Host" ':: host)
                           (list "x-amz-date" ':: ts)
                           (list
                             "x-amz-content-sha256"
                             '::
                             (hex-encode body-hash)))]
                [headers (if content-type
                             (append
                               headers
                               (list
                                 (list "Content-Type" ':: content-type)))
                             headers)]
                [headers (if (slot-ref client 'token)
                             (append
                               headers
                               (list
                                 (list
                                   "X-Amz-Security-Token"
                                   '::
                                   (slot-ref client 'token))))
                             headers)]
                [headers (if (null? extra-headers)
                             headers
                             (append headers extra-headers))]
                [creq (aws4-canonical-request 'verb: verb 'uri: path 'query: query 'headers:
                        headers 'hash: body-hash)]
                [auth (aws4-auth scope creq ts headers
                        (slot-ref client 'secret-key)
                        (slot-ref client 'access-key))]
                [headers (list
                           (list "Authorization" ':: auth)
                           '::
                           headers)]
                [url (string-append "https://" host path)])
           (case verb
             [(GET) (http-get url 'headers: headers 'params: query)]
             [(PUT)
              (http-put url 'headers: headers 'params: query 'data:
                (or body-bytes ""))]
             [(DELETE)
              (http-delete url 'headers: headers 'params: query)]
             [(HEAD) (http-head url 'headers: headers 'params: query)]
             [else (error "Bad request verb" verb)])))]))
  |#
  (define (s3-request/xml client . args)
    (let* ([verb (or (pgetq 'verb: args) 'GET)]
           [bucket (pgetq 'bucket: args)]
           [key (pgetq 'key: args)]
           [query (pgetq 'query: args)]
           [body (pgetq 'body: args)]
           [content-type (pgetq 'content-type: args)]
           [extra-headers (or (pgetq 'extra-headers: args) (list))])
      (let* ([req (s3-request client 'verb: verb 'bucket: bucket 'key: key 'query:
                    query 'body: body 'content-type: content-type
                    'extra-headers: extra-headers)]
             [status (request-status req)])
        (if (and (fx>= status 200) (fx< status 300))
            (let* ([content (request-text req)]
                   [xml (s3-parse-xml content)]
                   [result (s3-response->hash xml)])
              (request-close req)
              result)
            (let ([content (request-text req)])
                 (request-close req)
                 (let ([xml (guard (exn [#t (let ([_ exn]) #f)])
                              (s3-parse-xml content))])
                   (if xml
                       (let* ([err (s3-response->hash xml)]
                              [code-str (if (and (hash-table? err)
                                                 (hash-get err 'Code))
                                            (hash-get err 'Code)
                                            "Unknown")]
                              [msg-str (if (and (hash-table? err)
                                                (hash-get err 'Message))
                                           (hash-get err 'Message)
                                           content)])
                         (raise-s3-error
                           s3-request/xml
                           msg-str
                           code-str
                           status))
                       (raise-s3-error
                         's3-request/xml
                         (string-append "HTTP " (number->string status))
                         content))))))))
  #|
  ;; remaining s3-request/xml case-lambda clauses removed
      [(client verb)
       (let* ([bucket #f]
              [key #f]
              [query #f]
              [body #f]
              [content-type #f]
              [extra-headers (list)])
         (let* ([req (s3-request client 'verb: verb 'bucket: bucket 'key: key 'query:
                       query 'body: body 'content-type: content-type
                       'extra-headers: extra-headers)]
                [status (request-status req)])
           (if (and (fx>= status 200) (fx< status 300))
               (let* ([content (request-text req)]
                      [xml (s3-parse-xml content)]
                      [result (s3-response->hash xml)])
                 (request-close req)
                 result)
               (let ([content (request-text req)])
                 (request-close req)
                 (let ([xml (guard (exn [#t (let ([_ exn]) #f)])
                              (s3-parse-xml content))])
                   (if xml
                       (let* ([err (s3-response->hash xml)]
                              [code-str (if (and (hash-table? err)
                                                 (hash-get err 'Code))
                                            (hash-get err 'Code)
                                            "Unknown")]
                              [msg-str (if (and (hash-table? err)
                                                (hash-get err 'Message))
                                           (hash-get err 'Message)
                                           content)])
                         (raise-s3-error
                           s3-request/xml
                           msg-str
                           code-str
                           status))
                       (raise-s3-error
                         s3-request/xml
                         (string-append "HTTP " (number->string status))
                         content)))))))]
      [(client verb bucket)
       (let* ([key #f]
              [query #f]
              [body #f]
              [content-type #f]
              [extra-headers (list)])
         (let* ([req (s3-request client 'verb: verb 'bucket: bucket 'key: key 'query:
                       query 'body: body 'content-type: content-type
                       'extra-headers: extra-headers)]
                [status (request-status req)])
           (if (and (fx>= status 200) (fx< status 300))
               (let* ([content (request-text req)]
                      [xml (s3-parse-xml content)]
                      [result (s3-response->hash xml)])
                 (request-close req)
                 result)
               (let ([content (request-text req)])
                 (request-close req)
                 (let ([xml (guard (exn [#t (let ([_ exn]) #f)])
                              (s3-parse-xml content))])
                   (if xml
                       (let* ([err (s3-response->hash xml)]
                              [code-str (if (and (hash-table? err)
                                                 (hash-get err 'Code))
                                            (hash-get err 'Code)
                                            "Unknown")]
                              [msg-str (if (and (hash-table? err)
                                                (hash-get err 'Message))
                                           (hash-get err 'Message)
                                           content)])
                         (raise-s3-error
                           s3-request/xml
                           msg-str
                           code-str
                           status))
                       (raise-s3-error
                         s3-request/xml
                         (string-append "HTTP " (number->string status))
                         content)))))))]
      [(client verb bucket key)
       (let* ([query #f]
              [body #f]
              [content-type #f]
              [extra-headers (list)])
         (let* ([req (s3-request client 'verb: verb 'bucket: bucket 'key: key 'query:
                       query 'body: body 'content-type: content-type
                       'extra-headers: extra-headers)]
                [status (request-status req)])
           (if (and (fx>= status 200) (fx< status 300))
               (let* ([content (request-text req)]
                      [xml (s3-parse-xml content)]
                      [result (s3-response->hash xml)])
                 (request-close req)
                 result)
               (let ([content (request-text req)])
                 (request-close req)
                 (let ([xml (guard (exn [#t (let ([_ exn]) #f)])
                              (s3-parse-xml content))])
                   (if xml
                       (let* ([err (s3-response->hash xml)]
                              [code-str (if (and (hash-table? err)
                                                 (hash-get err 'Code))
                                            (hash-get err 'Code)
                                            "Unknown")]
                              [msg-str (if (and (hash-table? err)
                                                (hash-get err 'Message))
                                           (hash-get err 'Message)
                                           content)])
                         (raise-s3-error
                           s3-request/xml
                           msg-str
                           code-str
                           status))
                       (raise-s3-error
                         s3-request/xml
                         (string-append "HTTP " (number->string status))
                         content)))))))]
      [(client verb bucket key query)
       (let* ([body #f] [content-type #f] [extra-headers (list)])
         (let* ([req (s3-request client 'verb: verb 'bucket: bucket 'key: key 'query:
                       query 'body: body 'content-type: content-type
                       'extra-headers: extra-headers)]
                [status (request-status req)])
           (if (and (fx>= status 200) (fx< status 300))
               (let* ([content (request-text req)]
                      [xml (s3-parse-xml content)]
                      [result (s3-response->hash xml)])
                 (request-close req)
                 result)
               (let ([content (request-text req)])
                 (request-close req)
                 (let ([xml (guard (exn [#t (let ([_ exn]) #f)])
                              (s3-parse-xml content))])
                   (if xml
                       (let* ([err (s3-response->hash xml)]
                              [code-str (if (and (hash-table? err)
                                                 (hash-get err 'Code))
                                            (hash-get err 'Code)
                                            "Unknown")]
                              [msg-str (if (and (hash-table? err)
                                                (hash-get err 'Message))
                                           (hash-get err 'Message)
                                           content)])
                         (raise-s3-error
                           s3-request/xml
                           msg-str
                           code-str
                           status))
                       (raise-s3-error
                         s3-request/xml
                         (string-append "HTTP " (number->string status))
                         content)))))))]
      [(client verb bucket key query body)
       (let* ([content-type #f] [extra-headers (list)])
         (let* ([req (s3-request client 'verb: verb 'bucket: bucket 'key: key 'query:
                       query 'body: body 'content-type: content-type
                       'extra-headers: extra-headers)]
                [status (request-status req)])
           (if (and (fx>= status 200) (fx< status 300))
               (let* ([content (request-text req)]
                      [xml (s3-parse-xml content)]
                      [result (s3-response->hash xml)])
                 (request-close req)
                 result)
               (let ([content (request-text req)])
                 (request-close req)
                 (let ([xml (guard (exn [#t (let ([_ exn]) #f)])
                              (s3-parse-xml content))])
                   (if xml
                       (let* ([err (s3-response->hash xml)]
                              [code-str (if (and (hash-table? err)
                                                 (hash-get err 'Code))
                                            (hash-get err 'Code)
                                            "Unknown")]
                              [msg-str (if (and (hash-table? err)
                                                (hash-get err 'Message))
                                           (hash-get err 'Message)
                                           content)])
                         (raise-s3-error
                           s3-request/xml
                           msg-str
                           code-str
                           status))
                       (raise-s3-error
                         s3-request/xml
                         (string-append "HTTP " (number->string status))
                         content)))))))]
      [(client verb bucket key query body content-type)
       (let* ([extra-headers (list)])
         (let* ([req (s3-request client 'verb: verb 'bucket: bucket 'key: key 'query:
                       query 'body: body 'content-type: content-type
                       'extra-headers: extra-headers)]
                [status (request-status req)])
           (if (and (fx>= status 200) (fx< status 300))
               (let* ([content (request-text req)]
                      [xml (s3-parse-xml content)]
                      [result (s3-response->hash xml)])
                 (request-close req)
                 result)
               (let ([content (request-text req)])
                 (request-close req)
                 (let ([xml (guard (exn [#t (let ([_ exn]) #f)])
                              (s3-parse-xml content))])
                   (if xml
                       (let* ([err (s3-response->hash xml)]
                              [code-str (if (and (hash-table? err)
                                                 (hash-get err 'Code))
                                            (hash-get err 'Code)
                                            "Unknown")]
                              [msg-str (if (and (hash-table? err)
                                                (hash-get err 'Message))
                                           (hash-get err 'Message)
                                           content)])
                         (raise-s3-error
                           s3-request/xml
                           msg-str
                           code-str
                           status))
                       (raise-s3-error
                         s3-request/xml
                         (string-append "HTTP " (number->string status))
                         content)))))))]
      [(client verb bucket key query body content-type
        extra-headers)
       (let* ([req (s3-request client 'verb: verb 'bucket: bucket 'key: key 'query:
                     query 'body: body 'content-type: content-type
                     'extra-headers: extra-headers)]
              [status (request-status req)])
         (if (and (fx>= status 200) (fx< status 300))
             (let* ([content (request-text req)]
                    [xml (s3-parse-xml content)]
                    [result (s3-response->hash xml)])
               (request-close req)
               result)
             (let ([content (request-text req)])
               (request-close req)
               (let ([xml (guard (exn [#t (let ([_ exn]) #f)])
                            (s3-parse-xml content))])
                 (if xml
                     (let* ([err (s3-response->hash xml)]
                            [code-str (if (and (hash-table? err)
                                               (hash-get err 'Code))
                                          (hash-get err 'Code)
                                          "Unknown")]
                            [msg-str (if (and (hash-table? err)
                                              (hash-get err 'Message))
                                         (hash-get err 'Message)
                                         content)])
                       (raise-s3-error
                         s3-request/xml
                         msg-str
                         code-str
                         status))
                     (raise-s3-error
                       s3-request/xml
                       (string-append "HTTP " (number->string status))
                       content))))))]))
  |#
  (define (s3-request/check client . args)
    (let* ([verb (or (pgetq 'verb: args) 'GET)]
           [bucket (pgetq 'bucket: args)]
           [key (pgetq 'key: args)]
           [query (pgetq 'query: args)]
           [body (pgetq 'body: args)]
           [content-type (pgetq 'content-type: args)]
           [extra-headers (or (pgetq 'extra-headers: args) (list))])
      (let* ([req (s3-request client 'verb: verb 'bucket: bucket 'key: key 'query:
                    query 'body: body 'content-type: content-type
                    'extra-headers: extra-headers)]
             [status (request-status req)])
        (if (and (fx>= status 200) (fx< status 300))
            req
            (let ([content (request-text req)])
              (request-close req)
              (let ([xml (guard (exn [#t (let ([_ exn]) #f)])
                           (s3-parse-xml content))])
                (if xml
                    (let* ([err (s3-response->hash xml)]
                           [code-str (if (and (hash-table? err) (hash-get err 'Code))
                                        (hash-get err 'Code) "Unknown")]
                           [msg-str (if (and (hash-table? err) (hash-get err 'Message))
                                       (hash-get err 'Message) content)])
                      (raise-s3-error 's3-request/check msg-str code-str status))
                    (raise-s3-error 's3-request/check
                      (string-append "HTTP " (number->string status)) content))))))))
  #|
  ;; remaining s3-request/check case-lambda clauses removed
  (define s3-request/check-original
    (case-lambda
      [(client)
       (let* ([verb 'GET]
              [bucket #f]
              [key #f]
              [query #f]
              [body #f]
              [content-type #f]
              [extra-headers (list)])
         (let* ([req (s3-request client 'verb: verb 'bucket: bucket 'key: key 'query:
                       query 'body: body 'content-type: content-type
                       'extra-headers: extra-headers)]
                [status (request-status req)])
           (if (and (fx>= status 200) (fx< status 300))
               req
               (let ([content (request-text req)])
                 (request-close req)
                 (let ([xml (guard (exn [#t (let ([_ exn]) #f)])
                              (s3-parse-xml content))])
                   (if xml
                       (let* ([err (s3-response->hash xml)]
                              [code-str (if (and (hash-table? err)
                                                 (hash-get err 'Code))
                                            (hash-get err 'Code)
                                            "Unknown")]
                              [msg-str (if (and (hash-table? err)
                                                (hash-get err 'Message))
                                           (hash-get err 'Message)
                                           content)])
                         (raise-s3-error
                           s3-request/check
                           msg-str
                           code-str
                           status))
                       (raise-s3-error
                         s3-request/check
                         (string-append "HTTP " (number->string status))
                         content)))))))]
      [(client verb)
       (let* ([bucket #f]
              [key #f]
              [query #f]
              [body #f]
              [content-type #f]
              [extra-headers (list)])
         (let* ([req (s3-request client 'verb: verb 'bucket: bucket 'key: key 'query:
                       query 'body: body 'content-type: content-type
                       'extra-headers: extra-headers)]
                [status (request-status req)])
           (if (and (fx>= status 200) (fx< status 300))
               req
               (let ([content (request-text req)])
                 (request-close req)
                 (let ([xml (guard (exn [#t (let ([_ exn]) #f)])
                              (s3-parse-xml content))])
                   (if xml
                       (let* ([err (s3-response->hash xml)]
                              [code-str (if (and (hash-table? err)
                                                 (hash-get err 'Code))
                                            (hash-get err 'Code)
                                            "Unknown")]
                              [msg-str (if (and (hash-table? err)
                                                (hash-get err 'Message))
                                           (hash-get err 'Message)
                                           content)])
                         (raise-s3-error
                           s3-request/check
                           msg-str
                           code-str
                           status))
                       (raise-s3-error
                         s3-request/check
                         (string-append "HTTP " (number->string status))
                         content)))))))]
      [(client verb bucket)
       (let* ([key #f]
              [query #f]
              [body #f]
              [content-type #f]
              [extra-headers (list)])
         (let* ([req (s3-request client 'verb: verb 'bucket: bucket 'key: key 'query:
                       query 'body: body 'content-type: content-type
                       'extra-headers: extra-headers)]
                [status (request-status req)])
           (if (and (fx>= status 200) (fx< status 300))
               req
               (let ([content (request-text req)])
                 (request-close req)
                 (let ([xml (guard (exn [#t (let ([_ exn]) #f)])
                              (s3-parse-xml content))])
                   (if xml
                       (let* ([err (s3-response->hash xml)]
                              [code-str (if (and (hash-table? err)
                                                 (hash-get err 'Code))
                                            (hash-get err 'Code)
                                            "Unknown")]
                              [msg-str (if (and (hash-table? err)
                                                (hash-get err 'Message))
                                           (hash-get err 'Message)
                                           content)])
                         (raise-s3-error
                           s3-request/check
                           msg-str
                           code-str
                           status))
                       (raise-s3-error
                         s3-request/check
                         (string-append "HTTP " (number->string status))
                         content)))))))]
      [(client verb bucket key)
       (let* ([query #f]
              [body #f]
              [content-type #f]
              [extra-headers (list)])
         (let* ([req (s3-request client 'verb: verb 'bucket: bucket 'key: key 'query:
                       query 'body: body 'content-type: content-type
                       'extra-headers: extra-headers)]
                [status (request-status req)])
           (if (and (fx>= status 200) (fx< status 300))
               req
               (let ([content (request-text req)])
                 (request-close req)
                 (let ([xml (guard (exn [#t (let ([_ exn]) #f)])
                              (s3-parse-xml content))])
                   (if xml
                       (let* ([err (s3-response->hash xml)]
                              [code-str (if (and (hash-table? err)
                                                 (hash-get err 'Code))
                                            (hash-get err 'Code)
                                            "Unknown")]
                              [msg-str (if (and (hash-table? err)
                                                (hash-get err 'Message))
                                           (hash-get err 'Message)
                                           content)])
                         (raise-s3-error
                           s3-request/check
                           msg-str
                           code-str
                           status))
                       (raise-s3-error
                         s3-request/check
                         (string-append "HTTP " (number->string status))
                         content)))))))]
      [(client verb bucket key query)
       (let* ([body #f] [content-type #f] [extra-headers (list)])
         (let* ([req (s3-request client 'verb: verb 'bucket: bucket 'key: key 'query:
                       query 'body: body 'content-type: content-type
                       'extra-headers: extra-headers)]
                [status (request-status req)])
           (if (and (fx>= status 200) (fx< status 300))
               req
               (let ([content (request-text req)])
                 (request-close req)
                 (let ([xml (guard (exn [#t (let ([_ exn]) #f)])
                              (s3-parse-xml content))])
                   (if xml
                       (let* ([err (s3-response->hash xml)]
                              [code-str (if (and (hash-table? err)
                                                 (hash-get err 'Code))
                                            (hash-get err 'Code)
                                            "Unknown")]
                              [msg-str (if (and (hash-table? err)
                                                (hash-get err 'Message))
                                           (hash-get err 'Message)
                                           content)])
                         (raise-s3-error
                           s3-request/check
                           msg-str
                           code-str
                           status))
                       (raise-s3-error
                         s3-request/check
                         (string-append "HTTP " (number->string status))
                         content)))))))]
      [(client verb bucket key query body)
       (let* ([content-type #f] [extra-headers (list)])
         (let* ([req (s3-request client 'verb: verb 'bucket: bucket 'key: key 'query:
                       query 'body: body 'content-type: content-type
                       'extra-headers: extra-headers)]
                [status (request-status req)])
           (if (and (fx>= status 200) (fx< status 300))
               req
               (let ([content (request-text req)])
                 (request-close req)
                 (let ([xml (guard (exn [#t (let ([_ exn]) #f)])
                              (s3-parse-xml content))])
                   (if xml
                       (let* ([err (s3-response->hash xml)]
                              [code-str (if (and (hash-table? err)
                                                 (hash-get err 'Code))
                                            (hash-get err 'Code)
                                            "Unknown")]
                              [msg-str (if (and (hash-table? err)
                                                (hash-get err 'Message))
                                           (hash-get err 'Message)
                                           content)])
                         (raise-s3-error
                           s3-request/check
                           msg-str
                           code-str
                           status))
                       (raise-s3-error
                         s3-request/check
                         (string-append "HTTP " (number->string status))
                         content)))))))]
      [(client verb bucket key query body content-type)
       (let* ([extra-headers (list)])
         (let* ([req (s3-request client 'verb: verb 'bucket: bucket 'key: key 'query:
                       query 'body: body 'content-type: content-type
                       'extra-headers: extra-headers)]
                [status (request-status req)])
           (if (and (fx>= status 200) (fx< status 300))
               req
               (let ([content (request-text req)])
                 (request-close req)
                 (let ([xml (guard (exn [#t (let ([_ exn]) #f)])
                              (s3-parse-xml content))])
                   (if xml
                       (let* ([err (s3-response->hash xml)]
                              [code-str (if (and (hash-table? err)
                                                 (hash-get err 'Code))
                                            (hash-get err 'Code)
                                            "Unknown")]
                              [msg-str (if (and (hash-table? err)
                                                (hash-get err 'Message))
                                           (hash-get err 'Message)
                                           content)])
                         (raise-s3-error
                           s3-request/check
                           msg-str
                           code-str
                           status))
                       (raise-s3-error
                         s3-request/check
                         (string-append "HTTP " (number->string status))
                         content)))))))]
      [(client verb bucket key query body content-type
        extra-headers)
       (let* ([req (s3-request client 'verb: verb 'bucket: bucket 'key: key 'query:
                     query 'body: body 'content-type: content-type
                     'extra-headers: extra-headers)]
              [status (request-status req)])
         (if (and (fx>= status 200) (fx< status 300))
             req
             (let ([content (request-text req)])
               (request-close req)
               (let ([xml (guard (exn [#t (let ([_ exn]) #f)])
                            (s3-parse-xml content))])
                 (if xml
                     (let* ([err (s3-response->hash xml)]
                            [code-str (if (and (hash-table? err)
                                               (hash-get err 'Code))
                                          (hash-get err 'Code)
                                          "Unknown")]
                            [msg-str (if (and (hash-table? err)
                                              (hash-get err 'Message))
                                         (hash-get err 'Message)
                                         content)])
                       (raise-s3-error
                         s3-request/check
                         msg-str
                         code-str
                         status))
                     (raise-s3-error
                       s3-request/check
                       (string-append "HTTP " (number->string status))
                       content))))))]))
  |#
  (define (S3ClientError message . irritants)
    (error "S3ClientError" message irritants))
  (define (s3-client-error? x)
    (and (condition? x) (message-condition? x)))
  (define (raise-s3-error context message . irritants)
    (apply error (symbol->string context) message irritants)))
