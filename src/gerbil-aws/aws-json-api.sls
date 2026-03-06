#!chezscheme
(library (gerbil-aws aws-json-api)
  (export aws-json-client aws-json-client? aws-json-client-endpoint
    aws-json-client-access-key aws-json-client-secret-key
    aws-json-client-region aws-json-client-token
    aws-json-client-service AWSJsonClient AWSJsonClientError
    aws-json-client-error? aws-json-request aws-json-action)
  (import
    (except (chezscheme) box box? unbox set-box! andmap ormap
     iota last-pair find \x31;+ \x31;- fx/ fx1+ fx1- error error?
     raise with-exception-handler identifier? hash-table?
     make-hash-table sort sort! path-extension printf fprintf
     file-directory? file-exists? getenv close-port void
     open-output-file open-input-file)
    (compat types)
    (except (runtime util) string->bytes bytes->string
      string-split string-join find pgetq pgetv pget)
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
    (compat json) (compat format) (compat sugar)
    (compat request) (compat sigv4)
    (except (compat std-srfi-19) time->seconds)
    (gerbil-aws aws-creds))
  (begin
    (define aws-json-client::t
      (make-class-type 'gerbil\x23;aws-json-client::t 'aws-json-client
        (list object::t)
        '(endpoint access-key secret-key region token service
           target-prefix content-type)
        '((struct: . #t)) #f))
    (define (make-aws-json-client . args)
      (let* ([type aws-json-client::t]
             [all-slots (cdr (vector->list
                               (class-type-slot-vector type)))]
             [obj (make-class-instance type)])
        (let lp ([slots all-slots] [rest args] [i 1])
          (when (and (pair? slots) (pair? rest))
            (\x23;\x23;structure-set! obj i (car rest))
            (lp (cdr slots) (cdr rest) (+ i 1))))
        obj))
    (define (aws-json-client? obj)
      (\x23;\x23;structure-instance-of?
        obj
        'gerbil\x23;aws-json-client::t))
    (define (aws-json-client-endpoint obj)
      (slot-ref obj 'endpoint))
    (define (aws-json-client-access-key obj)
      (slot-ref obj 'access-key))
    (define (aws-json-client-secret-key obj)
      (slot-ref obj 'secret-key))
    (define (aws-json-client-region obj) (slot-ref obj 'region))
    (define (aws-json-client-token obj) (slot-ref obj 'token))
    (define (aws-json-client-service obj)
      (slot-ref obj 'service))
    (define (aws-json-client-target-prefix obj)
      (slot-ref obj 'target-prefix))
    (define (aws-json-client-content-type obj)
      (slot-ref obj 'content-type))
    (define (aws-json-client-endpoint-set! obj val)
      (slot-set! obj 'endpoint val))
    (define (aws-json-client-access-key-set! obj val)
      (slot-set! obj 'access-key val))
    (define (aws-json-client-secret-key-set! obj val)
      (slot-set! obj 'secret-key val))
    (define (aws-json-client-region-set! obj val)
      (slot-set! obj 'region val))
    (define (aws-json-client-token-set! obj val)
      (slot-set! obj 'token val))
    (define (aws-json-client-service-set! obj val)
      (slot-set! obj 'service val))
    (define (aws-json-client-target-prefix-set! obj val)
      (slot-set! obj 'target-prefix val))
    (define (aws-json-client-content-type-set! obj val)
      (slot-set! obj 'content-type val)))
  (define aws-json-client make-aws-json-client)
  (define emptySHA256 (sha256 #vu8()))
  (define (AWSJsonClient . args)
    (let* ([service (pgetq 'service: args)]
           [endpoint (pgetq 'endpoint: args)]
           [target-prefix (pgetq 'target-prefix: args)]
           [content-type (or (pgetq 'content-type: args) "application/x-amz-json-1.1")]
           [profile (pgetq 'profile: args)]
           [access-key (pgetq 'access-key: args)]
           [secret-key (pgetq 'secret-key: args)]
           [region (pgetq 'region: args)]
           [token (pgetq 'token: args)])
      (unless service
        (raise-aws-json-error 'AWSJsonClient "Must provide service" "service"))
      (let-values ([(resolved-access-key resolved-secret-key resolved-region resolved-token)
                    (aws-resolve-credentials profile)])
        (let ([access-key (or access-key resolved-access-key)]
              [secret-key (or secret-key resolved-secret-key)]
              [region (or region resolved-region)]
              [token (or token resolved-token)])
          (unless access-key
            (raise-aws-json-error 'AWSJsonClient "Must provide access key" "access-key"))
          (unless secret-key
            (raise-aws-json-error 'AWSJsonClient "Must provide secret key" "secret-key"))
          (make-aws-json-client
            (or endpoint
                (string-append service "." region ".amazonaws.com"))
            access-key secret-key region token service
            (or target-prefix "")
            content-type)))))
  ;; Original case-lambda removed
  #|
  (define AWSJsonClient-original
    (case-lambda
      [()
       (let* ([endpoint #f]
              [target-prefix #f]
              [content-type "application/x-amz-json-1.0"]
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
                 [token (or token resolved-token)])
             (unless access-key
               (raise-aws-json-error
                 AWSJsonClient
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-aws-json-error
                 AWSJsonClient
                 "Must provide secret key"
                 "secret-key"))
             (make-aws-json-client
               (or endpoint
                   (string-append service "." region ".amazonaws.com"))
               access-key secret-key region token service
               (or target-prefix "") content-type))))]
      [(endpoint)
       (let* ([target-prefix #f]
              [content-type "application/x-amz-json-1.0"]
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
                 [token (or token resolved-token)])
             (unless access-key
               (raise-aws-json-error
                 AWSJsonClient
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-aws-json-error
                 AWSJsonClient
                 "Must provide secret key"
                 "secret-key"))
             (make-aws-json-client
               (or endpoint
                   (string-append service "." region ".amazonaws.com"))
               access-key secret-key region token service
               (or target-prefix "") content-type))))]
      [(endpoint target-prefix)
       (let* ([content-type "application/x-amz-json-1.0"]
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
                 [token (or token resolved-token)])
             (unless access-key
               (raise-aws-json-error
                 AWSJsonClient
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-aws-json-error
                 AWSJsonClient
                 "Must provide secret key"
                 "secret-key"))
             (make-aws-json-client
               (or endpoint
                   (string-append service "." region ".amazonaws.com"))
               access-key secret-key region token service
               (or target-prefix "") content-type))))]
      [(endpoint target-prefix content-type)
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
                 [token (or token resolved-token)])
             (unless access-key
               (raise-aws-json-error
                 AWSJsonClient
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-aws-json-error
                 AWSJsonClient
                 "Must provide secret key"
                 "secret-key"))
             (make-aws-json-client
               (or endpoint
                   (string-append service "." region ".amazonaws.com"))
               access-key secret-key region token service
               (or target-prefix "") content-type))))]
      [(endpoint target-prefix content-type profile)
       (let* ([access-key #f]
              [secret-key #f]
              [region #f]
              [token #f])
         (let-values ([(resolved-access-key resolved-secret-key resolved-region resolved-token)
                       (aws-resolve-credentials profile)])
           (let ([access-key (or access-key resolved-access-key)]
                 [secret-key (or secret-key resolved-secret-key)]
                 [region (or region resolved-region)]
                 [token (or token resolved-token)])
             (unless access-key
               (raise-aws-json-error
                 AWSJsonClient
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-aws-json-error
                 AWSJsonClient
                 "Must provide secret key"
                 "secret-key"))
             (make-aws-json-client
               (or endpoint
                   (string-append service "." region ".amazonaws.com"))
               access-key secret-key region token service
               (or target-prefix "") content-type))))]
      [(endpoint target-prefix content-type profile access-key)
       (let* ([secret-key #f] [region #f] [token #f])
         (let-values ([(resolved-access-key resolved-secret-key resolved-region resolved-token)
                       (aws-resolve-credentials profile)])
           (let ([access-key (or access-key resolved-access-key)]
                 [secret-key (or secret-key resolved-secret-key)]
                 [region (or region resolved-region)]
                 [token (or token resolved-token)])
             (unless access-key
               (raise-aws-json-error
                 AWSJsonClient
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-aws-json-error
                 AWSJsonClient
                 "Must provide secret key"
                 "secret-key"))
             (make-aws-json-client
               (or endpoint
                   (string-append service "." region ".amazonaws.com"))
               access-key secret-key region token service
               (or target-prefix "") content-type))))]
      [(endpoint target-prefix content-type profile access-key
        secret-key)
       (let* ([region #f] [token #f])
         (let-values ([(resolved-access-key resolved-secret-key resolved-region resolved-token)
                       (aws-resolve-credentials profile)])
           (let ([access-key (or access-key resolved-access-key)]
                 [secret-key (or secret-key resolved-secret-key)]
                 [region (or region resolved-region)]
                 [token (or token resolved-token)])
             (unless access-key
               (raise-aws-json-error
                 AWSJsonClient
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-aws-json-error
                 AWSJsonClient
                 "Must provide secret key"
                 "secret-key"))
             (make-aws-json-client
               (or endpoint
                   (string-append service "." region ".amazonaws.com"))
               access-key secret-key region token service
               (or target-prefix "") content-type))))]
      [(endpoint target-prefix content-type profile access-key
        secret-key region)
       (let* ([token #f])
         (let-values ([(resolved-access-key resolved-secret-key resolved-region resolved-token)
                       (aws-resolve-credentials profile)])
           (let ([access-key (or access-key resolved-access-key)]
                 [secret-key (or secret-key resolved-secret-key)]
                 [region (or region resolved-region)]
                 [token (or token resolved-token)])
             (unless access-key
               (raise-aws-json-error
                 AWSJsonClient
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-aws-json-error
                 AWSJsonClient
                 "Must provide secret key"
                 "secret-key"))
             (make-aws-json-client
               (or endpoint
                   (string-append service "." region ".amazonaws.com"))
               access-key secret-key region token service
               (or target-prefix "") content-type))))]
      [(endpoint target-prefix content-type profile access-key
        secret-key region token)
       (let-values ([(resolved-access-key resolved-secret-key resolved-region resolved-token)
                     (aws-resolve-credentials profile)])
         (let ([access-key (or access-key resolved-access-key)]
               [secret-key (or secret-key resolved-secret-key)]
               [region (or region resolved-region)]
               [token (or token resolved-token)])
           (unless access-key
             (raise-aws-json-error
               AWSJsonClient
               "Must provide access key"
               "access-key"))
           (unless secret-key
             (raise-aws-json-error
               AWSJsonClient
               "Must provide secret key"
               "secret-key"))
           (make-aws-json-client
             (or endpoint
                 (string-append service "." region ".amazonaws.com"))
             access-key secret-key region token service
             (or target-prefix "") content-type)))]))
  |#
  (define (aws-json-request client target payload)
    (let ([client client])
      (let* ([body-str (if payload
                           (call-with-output-string
                             (lambda (p) (write-json payload p)))
                           "{}")]
             [body-bytes (string->bytes body-str)]
             [body-hash (sha256 body-bytes)]
             [now (current-date)]
             [ts (date->string now "~Y~m~dT~H~M~SZ")]
             [scopets (date->string now "~Y~m~d")]
             [scope (string-append scopets "/" (slot-ref client 'region)
                      "/" (slot-ref client 'service))]
             [host (slot-ref client 'endpoint)]
             [headers (list
                        (list "Host" ':: host)
                        (list "x-amz-date" ':: ts)
                        (list
                          "Content-Type"
                          '::
                          (slot-ref client 'content-type))
                        (list "X-Amz-Target" ':: target))]
             [headers (if (slot-ref client 'token)
                          (append
                            headers
                            (list
                              (list
                                "X-Amz-Security-Token"
                                '::
                                (slot-ref client 'token))))
                          headers)]
             [creq (aws4-canonical-request 'verb: 'POST 'uri: "/" 'query:
                     #f 'headers: headers 'hash: body-hash)]
             [auth (aws4-auth scope creq ts headers
                     (slot-ref client 'secret-key)
                     (slot-ref client 'access-key))]
             [headers (list (list "Authorization" ':: auth) ':: headers)]
             [url (string-append "https://" host "/")]
             [req (http-post url 'headers: headers 'data: body-str)]
             [status (request-status req)])
        (if (and (fx>= status 200) (fx< status 300))
            (let* ([content (request-text req)])
              (request-close req)
              (if (and content (not (equal? content "")))
                  (call-with-input-string content read-json)
                  (make-hash-table)))
            (let ([content (request-text req)])
              (request-close req)
              (let ([json (guard (exn [#t (let ([_ exn]) #f)])
                            (call-with-input-string content read-json))])
                (if json
                    (let* ([type-raw (or (hash-get json '__type)
                                         (hash-get json 'code)
                                         (hash-get json "code")
                                         (hash-get json "__type")
                                         "Unknown")]
                           [type-str (if (string? type-raw)
                                         (let ([pos (string-index
                                                      type-raw
                                                      #\#)])
                                           (if pos
                                               (substring
                                                 type-raw
                                                 (+ pos 1)
                                                 (string-length type-raw))
                                               type-raw))
                                         (format "~a" type-raw))]
                           [msg-str (or (hash-get json 'message)
                                        (hash-get json 'Message)
                                        (hash-get json "message")
                                        (hash-get json "Message")
                                        content)])
                      (raise-aws-json-error
                        aws-json-request
                        msg-str
                        type-str
                        status))
                    (raise-aws-json-error
                      aws-json-request
                      (string-append "HTTP " (number->string status))
                      content))))))))
  (define aws-json-action
    (case-lambda
      [(client action)
       (let* ([payload #f])
         (let ([target (string-append
                         (aws-json-client-target-prefix client)
                         "."
                         action)])
           (aws-json-request client target payload)))]
      [(client action payload)
       (let ([target (string-append
                       (aws-json-client-target-prefix client)
                       "."
                       action)])
         (aws-json-request client target payload))]))
  (define (AWSJsonClientError message . irritants)
    (error "AWSJsonClientError" message irritants))
  (define (aws-json-client-error? x)
    (and (condition? x) (message-condition? x)))
  (define (raise-aws-json-error context message . irritants)
    (apply error (symbol->string context) message irritants)))
