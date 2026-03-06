#!chezscheme
(library (gerbil-aws aws-api)
  (export aws-client aws-client? aws-client-endpoint
    aws-client-access-key aws-client-secret-key
    aws-client-region aws-client-token aws-client-service
    AWSClient AWSClientError aws-client-error? aws-query-request
    aws-query-action aws-query-action/items
    aws-query-action/hash)
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
    (except (compat misc) read-line call-with-output-string last
      iota)
    (compat sugar) (compat request) (compat uri) (compat sigv4)
    (except (compat std-srfi-19) time->seconds)
    (gerbil-aws aws-creds) (gerbil-aws aws-xml))
  (define (raise-aws-error context message . irritants)
    (apply error (symbol->string context) message irritants))
  (begin
    (define aws-client::t
      (make-class-type 'gerbil\x23;aws-client::t 'aws-client (list object::t)
        '(endpoint access-key secret-key region token service
           api-version namespaces)
        '((struct: . #t)) #f))
    (define (make-aws-client . args)
      (let* ([type aws-client::t]
             [all-slots (cdr (vector->list
                               (class-type-slot-vector type)))]
             [obj (make-class-instance type)])
        (let lp ([slots all-slots] [rest args] [i 1])
          (when (and (pair? slots) (pair? rest))
            (\x23;\x23;structure-set! obj i (car rest))
            (lp (cdr slots) (cdr rest) (+ i 1))))
        obj))
    (define (aws-client? obj)
      (\x23;\x23;structure-instance-of?
        obj
        'gerbil\x23;aws-client::t))
    (define (aws-client-endpoint obj) (slot-ref obj 'endpoint))
    (define (aws-client-access-key obj)
      (slot-ref obj 'access-key))
    (define (aws-client-secret-key obj)
      (slot-ref obj 'secret-key))
    (define (aws-client-region obj) (slot-ref obj 'region))
    (define (aws-client-token obj) (slot-ref obj 'token))
    (define (aws-client-service obj) (slot-ref obj 'service))
    (define (aws-client-api-version obj)
      (slot-ref obj 'api-version))
    (define (aws-client-namespaces obj)
      (slot-ref obj 'namespaces))
    (define (aws-client-endpoint-set! obj val)
      (slot-set! obj 'endpoint val))
    (define (aws-client-access-key-set! obj val)
      (slot-set! obj 'access-key val))
    (define (aws-client-secret-key-set! obj val)
      (slot-set! obj 'secret-key val))
    (define (aws-client-region-set! obj val)
      (slot-set! obj 'region val))
    (define (aws-client-token-set! obj val)
      (slot-set! obj 'token val))
    (define (aws-client-service-set! obj val)
      (slot-set! obj 'service val))
    (define (aws-client-api-version-set! obj val)
      (slot-set! obj 'api-version val))
    (define (aws-client-namespaces-set! obj val)
      (slot-set! obj 'namespaces val)))
  (define aws-client make-aws-client)
  (define (AWSClient . args)
    (let* ([service (pgetq 'service: args)]
           [endpoint (pgetq 'endpoint: args)]
           [api-version (pgetq 'api-version: args)]
           [namespaces (or (pgetq 'namespaces: args) '())]
           [profile (pgetq 'profile: args)]
           [access-key (pgetq 'access-key: args)]
           [secret-key (pgetq 'secret-key: args)]
           [region (pgetq 'region: args)]
           [token (pgetq 'token: args)])
      (unless service
        (raise-aws-error 'AWSClient "Must provide service" "service"))
      (let-values ([(resolved-access-key resolved-secret-key resolved-region resolved-token)
                    (aws-resolve-credentials profile)])
        (let ([access-key (or access-key resolved-access-key)]
              [secret-key (or secret-key resolved-secret-key)]
              [region (or region resolved-region)]
              [token (or token resolved-token)])
          (unless access-key
            (raise-aws-error 'AWSClient "Must provide access key" "access-key"))
          (unless secret-key
            (raise-aws-error 'AWSClient "Must provide secret key" "secret-key"))
          (make-aws-client
            (or endpoint
                (string-append service "." region ".amazonaws.com"))
            access-key secret-key region token service
            (or api-version "") namespaces)))))
  ;; [DELETED: original case-lambda with 9 clauses - keyword dispatch doesn't translate to R6RS]
  ;; The following block is commented out via block-comment:
  #|
  (define AWSClient-original
    (case-lambda
      [()
       (let* ([endpoint #f]
              [api-version #f]
              [namespaces (list)]
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
               (raise-aws-error
                 AWSClient
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-aws-error
                 AWSClient
                 "Must provide secret key"
                 "secret-key"))
             (make-aws-client
               (or endpoint
                   (string-append service "." region ".amazonaws.com"))
               access-key secret-key region token service
               (or api-version "") namespaces))))]
      [(endpoint)
       (let* ([api-version #f]
              [namespaces (list)]
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
               (raise-aws-error
                 AWSClient
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-aws-error
                 AWSClient
                 "Must provide secret key"
                 "secret-key"))
             (make-aws-client
               (or endpoint
                   (string-append service "." region ".amazonaws.com"))
               access-key secret-key region token service
               (or api-version "") namespaces))))]
      [(endpoint api-version)
       (let* ([namespaces (list)]
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
               (raise-aws-error
                 AWSClient
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-aws-error
                 AWSClient
                 "Must provide secret key"
                 "secret-key"))
             (make-aws-client
               (or endpoint
                   (string-append service "." region ".amazonaws.com"))
               access-key secret-key region token service
               (or api-version "") namespaces))))]
      [(endpoint api-version namespaces)
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
               (raise-aws-error
                 AWSClient
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-aws-error
                 AWSClient
                 "Must provide secret key"
                 "secret-key"))
             (make-aws-client
               (or endpoint
                   (string-append service "." region ".amazonaws.com"))
               access-key secret-key region token service
               (or api-version "") namespaces))))]
      [(endpoint api-version namespaces profile)
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
               (raise-aws-error
                 AWSClient
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-aws-error
                 AWSClient
                 "Must provide secret key"
                 "secret-key"))
             (make-aws-client
               (or endpoint
                   (string-append service "." region ".amazonaws.com"))
               access-key secret-key region token service
               (or api-version "") namespaces))))]
      [(endpoint api-version namespaces profile access-key)
       (let* ([secret-key #f] [region #f] [token #f])
         (let-values ([(resolved-access-key resolved-secret-key resolved-region resolved-token)
                       (aws-resolve-credentials profile)])
           (let ([access-key (or access-key resolved-access-key)]
                 [secret-key (or secret-key resolved-secret-key)]
                 [region (or region resolved-region)]
                 [token (or token resolved-token)])
             (unless access-key
               (raise-aws-error
                 AWSClient
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-aws-error
                 AWSClient
                 "Must provide secret key"
                 "secret-key"))
             (make-aws-client
               (or endpoint
                   (string-append service "." region ".amazonaws.com"))
               access-key secret-key region token service
               (or api-version "") namespaces))))]
      [(endpoint api-version namespaces profile access-key
        secret-key)
       (let* ([region #f] [token #f])
         (let-values ([(resolved-access-key resolved-secret-key resolved-region resolved-token)
                       (aws-resolve-credentials profile)])
           (let ([access-key (or access-key resolved-access-key)]
                 [secret-key (or secret-key resolved-secret-key)]
                 [region (or region resolved-region)]
                 [token (or token resolved-token)])
             (unless access-key
               (raise-aws-error
                 AWSClient
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-aws-error
                 AWSClient
                 "Must provide secret key"
                 "secret-key"))
             (make-aws-client
               (or endpoint
                   (string-append service "." region ".amazonaws.com"))
               access-key secret-key region token service
               (or api-version "") namespaces))))]
      [(endpoint api-version namespaces profile access-key
        secret-key region)
       (let* ([token #f])
         (let-values ([(resolved-access-key resolved-secret-key resolved-region resolved-token)
                       (aws-resolve-credentials profile)])
           (let ([access-key (or access-key resolved-access-key)]
                 [secret-key (or secret-key resolved-secret-key)]
                 [region (or region resolved-region)]
                 [token (or token resolved-token)])
             (unless access-key
               (raise-aws-error
                 AWSClient
                 "Must provide access key"
                 "access-key"))
             (unless secret-key
               (raise-aws-error
                 AWSClient
                 "Must provide secret key"
                 "secret-key"))
             (make-aws-client
               (or endpoint
                   (string-append service "." region ".amazonaws.com"))
               access-key secret-key region token service
               (or api-version "") namespaces))))]
      [(endpoint api-version namespaces profile access-key
        secret-key region token)
       (let-values ([(resolved-access-key resolved-secret-key resolved-region resolved-token)
                     (aws-resolve-credentials profile)])
         (let ([access-key (or access-key resolved-access-key)]
               [secret-key (or secret-key resolved-secret-key)]
               [region (or region resolved-region)]
               [token (or token resolved-token)])
           (unless access-key
             (raise-aws-error
               AWSClient
               "Must provide access key"
               "access-key"))
           (unless secret-key
             (raise-aws-error
               AWSClient
               "Must provide secret key"
               "secret-key"))
           (make-aws-client
             (or endpoint
                 (string-append service "." region ".amazonaws.com"))
             access-key secret-key region token service
             (or api-version "") namespaces)))]))
  |#
  (define (aws-query-request client params)
    (let ([client client])
      (let* ([body-str (form-url-encode params)]
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
                          "application/x-www-form-urlencoded; charset=utf-8"))]
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
            (let* ([content (request-text req)]
                   [xml (aws-parse-xml
                          content
                          'namespaces:
                          (slot-ref client 'namespaces))])
              (request-close req)
              xml)
            (let ([content (request-text req)])
              (request-close req)
              (let ([xml (guard (exn [#t (let ([_ exn]) #f)])
                           (aws-parse-xml
                             content
                             'namespaces:
                             (slot-ref client 'namespaces)))])
                (if xml
                    (let* ([hash (aws-response->hash xml)]
                           [err (and (hash-table? hash)
                                     (hash-get hash 'Error))]
                           [code-str (if (and (hash-table? err)
                                              (hash-get err 'Code))
                                         (hash-get err 'Code)
                                         "Unknown")]
                           [msg-str (if (and (hash-table? err)
                                             (hash-get err 'Message))
                                        (hash-get err 'Message)
                                        content)])
                      (raise-aws-error
                        aws-query-request
                        msg-str
                        code-str
                        status))
                    (raise-aws-error
                      aws-query-request
                      (string-append "HTTP " (number->string status))
                      content))))))))
  (define aws-query-action
    (case-lambda
      [(client action)
       (let* ([extra-params (list)])
         (aws-query-request
           client
           (append
             (list
               (list "Action" ':: action)
               (list "Version" ':: (aws-client-api-version client)))
             extra-params)))]
      [(client action extra-params)
       (aws-query-request
         client
         (append
           (list
             (list "Action" ':: action)
             (list "Version" ':: (aws-client-api-version client)))
           extra-params))]))
  (define aws-query-action/items
    (case-lambda
      [(client action response-tag)
       (let* ([extra-params (list)] [item-tag #f] [ns-prefix #f])
         (let* ([xml (aws-query-action client action extra-params)]
                [ns-tag (if ns-prefix
                            (string->symbol
                              (string-append
                                ns-prefix
                                (symbol->string response-tag)))
                            response-tag)]
                [set-elem (sxml-find xml (sxml-e? ns-tag))])
           (if set-elem
               (let ([items (if item-tag
                                (sxml-items set-elem item-tag)
                                (sxml-items set-elem))])
                 (map sxml->hash items))
               (let ([set-elem (sxml-find
                                 xml
                                 (lambda (node)
                                   (and (pair? node)
                                        (symbol? (car node))
                                        (eq? (strip-ns (car node))
                                             response-tag))))])
                 (if set-elem
                     (let ([items (if item-tag
                                      (sxml-items set-elem item-tag)
                                      (sxml-items set-elem))])
                       (map sxml->hash items))
                     (list))))))]
      [(client action response-tag extra-params)
       (let* ([item-tag #f] [ns-prefix #f])
         (let* ([xml (aws-query-action client action extra-params)]
                [ns-tag (if ns-prefix
                            (string->symbol
                              (string-append
                                ns-prefix
                                (symbol->string response-tag)))
                            response-tag)]
                [set-elem (sxml-find xml (sxml-e? ns-tag))])
           (if set-elem
               (let ([items (if item-tag
                                (sxml-items set-elem item-tag)
                                (sxml-items set-elem))])
                 (map sxml->hash items))
               (let ([set-elem (sxml-find
                                 xml
                                 (lambda (node)
                                   (and (pair? node)
                                        (symbol? (car node))
                                        (eq? (strip-ns (car node))
                                             response-tag))))])
                 (if set-elem
                     (let ([items (if item-tag
                                      (sxml-items set-elem item-tag)
                                      (sxml-items set-elem))])
                       (map sxml->hash items))
                     (list))))))]
      [(client action response-tag extra-params item-tag)
       (let* ([ns-prefix #f])
         (let* ([xml (aws-query-action client action extra-params)]
                [ns-tag (if ns-prefix
                            (string->symbol
                              (string-append
                                ns-prefix
                                (symbol->string response-tag)))
                            response-tag)]
                [set-elem (sxml-find xml (sxml-e? ns-tag))])
           (if set-elem
               (let ([items (if item-tag
                                (sxml-items set-elem item-tag)
                                (sxml-items set-elem))])
                 (map sxml->hash items))
               (let ([set-elem (sxml-find
                                 xml
                                 (lambda (node)
                                   (and (pair? node)
                                        (symbol? (car node))
                                        (eq? (strip-ns (car node))
                                             response-tag))))])
                 (if set-elem
                     (let ([items (if item-tag
                                      (sxml-items set-elem item-tag)
                                      (sxml-items set-elem))])
                       (map sxml->hash items))
                     (list))))))]
      [(client action response-tag extra-params item-tag
        ns-prefix)
       (let* ([xml (aws-query-action client action extra-params)]
              [ns-tag (if ns-prefix
                          (string->symbol
                            (string-append
                              ns-prefix
                              (symbol->string response-tag)))
                          response-tag)]
              [set-elem (sxml-find xml (sxml-e? ns-tag))])
         (if set-elem
             (let ([items (if item-tag
                              (sxml-items set-elem item-tag)
                              (sxml-items set-elem))])
               (map sxml->hash items))
             (let ([set-elem (sxml-find
                               xml
                               (lambda (node)
                                 (and (pair? node)
                                      (symbol? (car node))
                                      (eq? (strip-ns (car node))
                                           response-tag))))])
               (if set-elem
                   (let ([items (if item-tag
                                    (sxml-items set-elem item-tag)
                                    (sxml-items set-elem))])
                     (map sxml->hash items))
                   (list)))))]))
  (define aws-query-action/hash
    (case-lambda
      [(client action)
       (let* ([extra-params (list)])
         (let ([xml (aws-query-action client action extra-params)])
           (aws-response->hash xml)))]
      [(client action extra-params)
       (let ([xml (aws-query-action client action extra-params)])
         (aws-response->hash xml))]))
  ;; AWSClientError - simple error condition (replaces deferror-class)
  (define (AWSClientError message . irritants)
    (error "AWSClientError" message irritants))
  (define (aws-client-error? x)
    (and (condition? x) (message-condition? x))))
