#!chezscheme
(library (gerbil-aws s3-objects)
  (export list-objects get-object put-object delete-object
    head-object copy-object delete-objects list-object-versions
    get-object-tagging put-object-tagging delete-object-tagging
    list-multipart-uploads abort-multipart-upload)
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
    (except (compat misc) last
      iota)
    (compat request) (compat std-text-base64)
    (only (compat std-crypto-digest) md5)
    (gerbil-aws s3-api))
  (define (list-objects client bucket-name . args)
    (let* ([prefix (pgetq 'prefix: args)]
           [delimiter (pgetq 'delimiter: args)]
           [max-keys (pgetq 'max-keys: args)]
           [continuation-token (pgetq 'continuation-token: args)]
           [start-after (pgetq 'start-after: args)])
         (let* ([query (append (list (list "list-type" ':: "2"))
                         (if prefix
                             (list (list "prefix" ':: prefix))
                             (list))
                         (if delimiter
                             (list (list "delimiter" ':: delimiter))
                             (list))
                         (if max-keys
                             (list
                               (list
                                 "max-keys"
                                 '::
                                 (if (number? max-keys)
                                     (number->string max-keys)
                                     max-keys)))
                             (list))
                         (if continuation-token
                             (list
                               (list
                                 "continuation-token"
                                 '::
                                 continuation-token))
                             (list))
                         (if start-after
                             (list (list "start-after" ':: start-after))
                             (list)))])
           (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
             'query: query))))
  #|
  ;; remaining list-objects case-lambda clauses removed
      [(client bucket-name prefix)
       (let* ([delimiter #f]
              [max-keys #f]
              [continuation-token #f]
              [start-after #f])
         (let* ([query (append (list (list "list-type" ':: "2"))
                         (if prefix
                             (list (list "prefix" ':: prefix))
                             (list))
                         (if delimiter
                             (list (list "delimiter" ':: delimiter))
                             (list))
                         (if max-keys
                             (list
                               (list
                                 "max-keys"
                                 '::
                                 (if (number? max-keys)
                                     (number->string max-keys)
                                     max-keys)))
                             (list))
                         (if continuation-token
                             (list
                               (list
                                 "continuation-token"
                                 '::
                                 continuation-token))
                             (list))
                         (if start-after
                             (list (list "start-after" ':: start-after))
                             (list)))])
           (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
             'query: query)))]
      [(client bucket-name prefix delimiter)
       (let* ([max-keys #f]
              [continuation-token #f]
              [start-after #f])
         (let* ([query (append (list (list "list-type" ':: "2"))
                         (if prefix
                             (list (list "prefix" ':: prefix))
                             (list))
                         (if delimiter
                             (list (list "delimiter" ':: delimiter))
                             (list))
                         (if max-keys
                             (list
                               (list
                                 "max-keys"
                                 '::
                                 (if (number? max-keys)
                                     (number->string max-keys)
                                     max-keys)))
                             (list))
                         (if continuation-token
                             (list
                               (list
                                 "continuation-token"
                                 '::
                                 continuation-token))
                             (list))
                         (if start-after
                             (list (list "start-after" ':: start-after))
                             (list)))])
           (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
             'query: query)))]
      [(client bucket-name prefix delimiter max-keys)
       (let* ([continuation-token #f] [start-after #f])
         (let* ([query (append (list (list "list-type" ':: "2"))
                         (if prefix
                             (list (list "prefix" ':: prefix))
                             (list))
                         (if delimiter
                             (list (list "delimiter" ':: delimiter))
                             (list))
                         (if max-keys
                             (list
                               (list
                                 "max-keys"
                                 '::
                                 (if (number? max-keys)
                                     (number->string max-keys)
                                     max-keys)))
                             (list))
                         (if continuation-token
                             (list
                               (list
                                 "continuation-token"
                                 '::
                                 continuation-token))
                             (list))
                         (if start-after
                             (list (list "start-after" ':: start-after))
                             (list)))])
           (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
             'query: query)))]
      [(client bucket-name prefix delimiter max-keys
        continuation-token)
       (let* ([start-after #f])
         (let* ([query (append (list (list "list-type" ':: "2"))
                         (if prefix
                             (list (list "prefix" ':: prefix))
                             (list))
                         (if delimiter
                             (list (list "delimiter" ':: delimiter))
                             (list))
                         (if max-keys
                             (list
                               (list
                                 "max-keys"
                                 '::
                                 (if (number? max-keys)
                                     (number->string max-keys)
                                     max-keys)))
                             (list))
                         (if continuation-token
                             (list
                               (list
                                 "continuation-token"
                                 '::
                                 continuation-token))
                             (list))
                         (if start-after
                             (list (list "start-after" ':: start-after))
                             (list)))])
           (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
             'query: query)))]
      [(client bucket-name prefix delimiter max-keys
        continuation-token start-after)
       (let* ([query (append (list (list "list-type" ':: "2"))
                       (if prefix (list (list "prefix" ':: prefix)) (list))
                       (if delimiter
                           (list (list "delimiter" ':: delimiter))
                           (list))
                       (if max-keys
                           (list
                             (list
                               "max-keys"
                               '::
                               (if (number? max-keys)
                                   (number->string max-keys)
                                   max-keys)))
                           (list))
                       (if continuation-token
                           (list
                             (list
                               "continuation-token"
                               '::
                               continuation-token))
                           (list))
                       (if start-after
                           (list (list "start-after" ':: start-after))
                           (list)))])
         (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
           'query: query))]))
  |#
  (define (get-object client bucket-name key)
    (let* ([req (s3-request/check client 'verb: 'GET 'bucket:
                  bucket-name 'key: key)]
           [data (request-content req)])
      (request-close req)
      data))
  (define put-object
    (case-lambda
      [(client bucket-name key data)
       (let* ([content-type "application/octet-stream"])
         (let ([req (s3-request/check client 'verb: 'PUT 'bucket: bucket-name 'key: key
                      'body: data 'content-type: content-type)])
           (request-close req)
           (void)))]
      [(client bucket-name key data content-type)
       (let ([req (s3-request/check client 'verb: 'PUT 'bucket: bucket-name 'key: key
                    'body: data 'content-type: content-type)])
         (request-close req)
         (void))]))
  (define (delete-object client bucket-name key)
    (let ([req (s3-request/check client 'verb: 'DELETE 'bucket:
                 bucket-name 'key: key)])
      (request-close req)
      (void)))
  (define (head-object client bucket-name key)
    (let* ([req (s3-request/check client 'verb: 'HEAD 'bucket:
                  bucket-name 'key: key)]
           [headers (request-headers req)])
      (request-close req)
      (let ([ht (make-hash-table)])
        (for-each
          (lambda (h) (hash-put! ht (car h) (cdr h)))
          headers)
        ht)))
  (define (copy-object client bucket-name key source)
    (let ([req (s3-request/check client 'verb: 'PUT 'bucket: bucket-name 'key: key
                 'extra-headers:
                 (list (list "x-amz-copy-source" ':: source)))])
      (request-close req)
      (void)))
  (define delete-objects
    (case-lambda
      [(client bucket-name keys)
       (let* ([quiet #t])
         (let* ([objects-xml (apply
                               string-append
                               (map (lambda (k)
                                      (string-append
                                        "<Object><Key>"
                                        k
                                        "</Key></Object>"))
                                    keys))]
                [body (string-append
                        "<Delete>"
                        (if quiet "<Quiet>true</Quiet>" "")
                        objects-xml
                        "</Delete>")]
                [body-bytes (string->bytes body)]
                [md5-hash (md5 body-bytes)]
                [req (s3-request/check client 'verb: 'POST 'bucket: bucket-name 'query:
                       (list (list "delete" ':: "")) 'body: body
                       'content-type: "application/xml" 'extra-headers:
                       (list
                         (list
                           "Content-MD5"
                           '::
                           (u8vector->base64-string md5-hash))))])
           (request-close req)
           (void)))]
      [(client bucket-name keys quiet)
       (let* ([objects-xml (apply
                             string-append
                             (map (lambda (k)
                                    (string-append
                                      "<Object><Key>"
                                      k
                                      "</Key></Object>"))
                                  keys))]
              [body (string-append
                      "<Delete>"
                      (if quiet "<Quiet>true</Quiet>" "")
                      objects-xml
                      "</Delete>")]
              [body-bytes (string->bytes body)]
              [md5-hash (md5 body-bytes)]
              [req (s3-request/check client 'verb: 'POST 'bucket: bucket-name 'query:
                     (list (list "delete" ':: "")) 'body: body
                     'content-type: "application/xml" 'extra-headers:
                     (list
                       (list
                         "Content-MD5"
                         '::
                         (u8vector->base64-string md5-hash))))])
         (request-close req)
         (void))]))
  (define (list-object-versions client bucket-name . args)
    (let* ([prefix (pgetq 'prefix: args)]
           [delimiter (pgetq 'delimiter: args)]
           [max-keys (pgetq 'max-keys: args)]
           [key-marker (pgetq 'key-marker: args)]
           [version-id-marker (pgetq 'version-id-marker: args)])
         (let* ([query (append (list (list "versions" ':: ""))
                         (if prefix
                             (list (list "prefix" ':: prefix))
                             (list))
                         (if delimiter
                             (list (list "delimiter" ':: delimiter))
                             (list))
                         (if max-keys
                             (list
                               (list
                                 "max-keys"
                                 '::
                                 (if (number? max-keys)
                                     (number->string max-keys)
                                     max-keys)))
                             (list))
                         (if key-marker
                             (list (list "key-marker" ':: key-marker))
                             (list))
                         (if version-id-marker
                             (list
                               (list
                                 "version-id-marker"
                                 '::
                                 version-id-marker))
                             (list)))])
           (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
             'query: query))))
  #|
  ;; remaining list-object-versions case-lambda clauses removed
      [(client bucket-name prefix)
       (let* ([delimiter #f]
              [max-keys #f]
              [key-marker #f]
              [version-id-marker #f])
         (let* ([query (append (list (list "versions" ':: ""))
                         (if prefix
                             (list (list "prefix" ':: prefix))
                             (list))
                         (if delimiter
                             (list (list "delimiter" ':: delimiter))
                             (list))
                         (if max-keys
                             (list
                               (list
                                 "max-keys"
                                 '::
                                 (if (number? max-keys)
                                     (number->string max-keys)
                                     max-keys)))
                             (list))
                         (if key-marker
                             (list (list "key-marker" ':: key-marker))
                             (list))
                         (if version-id-marker
                             (list
                               (list
                                 "version-id-marker"
                                 '::
                                 version-id-marker))
                             (list)))])
           (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
             'query: query)))]
      [(client bucket-name prefix delimiter)
       (let* ([max-keys #f] [key-marker #f] [version-id-marker #f])
         (let* ([query (append (list (list "versions" ':: ""))
                         (if prefix
                             (list (list "prefix" ':: prefix))
                             (list))
                         (if delimiter
                             (list (list "delimiter" ':: delimiter))
                             (list))
                         (if max-keys
                             (list
                               (list
                                 "max-keys"
                                 '::
                                 (if (number? max-keys)
                                     (number->string max-keys)
                                     max-keys)))
                             (list))
                         (if key-marker
                             (list (list "key-marker" ':: key-marker))
                             (list))
                         (if version-id-marker
                             (list
                               (list
                                 "version-id-marker"
                                 '::
                                 version-id-marker))
                             (list)))])
           (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
             'query: query)))]
      [(client bucket-name prefix delimiter max-keys)
       (let* ([key-marker #f] [version-id-marker #f])
         (let* ([query (append (list (list "versions" ':: ""))
                         (if prefix
                             (list (list "prefix" ':: prefix))
                             (list))
                         (if delimiter
                             (list (list "delimiter" ':: delimiter))
                             (list))
                         (if max-keys
                             (list
                               (list
                                 "max-keys"
                                 '::
                                 (if (number? max-keys)
                                     (number->string max-keys)
                                     max-keys)))
                             (list))
                         (if key-marker
                             (list (list "key-marker" ':: key-marker))
                             (list))
                         (if version-id-marker
                             (list
                               (list
                                 "version-id-marker"
                                 '::
                                 version-id-marker))
                             (list)))])
           (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
             'query: query)))]
      [(client bucket-name prefix delimiter max-keys key-marker)
       (let* ([version-id-marker #f])
         (let* ([query (append (list (list "versions" ':: ""))
                         (if prefix
                             (list (list "prefix" ':: prefix))
                             (list))
                         (if delimiter
                             (list (list "delimiter" ':: delimiter))
                             (list))
                         (if max-keys
                             (list
                               (list
                                 "max-keys"
                                 '::
                                 (if (number? max-keys)
                                     (number->string max-keys)
                                     max-keys)))
                             (list))
                         (if key-marker
                             (list (list "key-marker" ':: key-marker))
                             (list))
                         (if version-id-marker
                             (list
                               (list
                                 "version-id-marker"
                                 '::
                                 version-id-marker))
                             (list)))])
           (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
             'query: query)))]
      [(client bucket-name prefix delimiter max-keys key-marker
        version-id-marker)
       (let* ([query (append (list (list "versions" ':: ""))
                       (if prefix (list (list "prefix" ':: prefix)) (list))
                       (if delimiter
                           (list (list "delimiter" ':: delimiter))
                           (list))
                       (if max-keys
                           (list
                             (list
                               "max-keys"
                               '::
                               (if (number? max-keys)
                                   (number->string max-keys)
                                   max-keys)))
                           (list))
                       (if key-marker
                           (list (list "key-marker" ':: key-marker))
                           (list))
                       (if version-id-marker
                           (list
                             (list
                               "version-id-marker"
                               '::
                               version-id-marker))
                           (list)))])
         (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
           'query: query))]))
  |#
  (define (get-object-tagging client bucket-name key)
    (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
      'key: key 'query: (list (list "tagging" ':: ""))))
  (define (put-object-tagging client bucket-name key tags)
    (let* ([tag-xml (apply
                      string-append
                      (map (lambda (t)
                             (string-append "<Tag><Key>" (car t)
                               "</Key><Value>" (cdr t) "</Value></Tag>"))
                           tags))]
           [body (string-append
                   "<Tagging><TagSet>"
                   tag-xml
                   "</TagSet></Tagging>")]
           [req (s3-request/check client 'verb: 'PUT 'bucket: bucket-name 'key: key 'query:
                  (list (list "tagging" ':: "")) 'body: body 'content-type:
                  "application/xml")])
      (request-close req)
      (void)))
  (define (delete-object-tagging client bucket-name key)
    (let ([req (s3-request/check client 'verb: 'DELETE 'bucket: bucket-name 'key: key
                 'query: (list (list "tagging" ':: "")))])
      (request-close req)
      (void)))
  (define (list-multipart-uploads client bucket-name . args)
    (let* ([prefix (pgetq 'prefix: args)]
           [delimiter (pgetq 'delimiter: args)]
           [max-uploads (pgetq 'max-uploads: args)]
           [key-marker (pgetq 'key-marker: args)]
           [upload-id-marker (pgetq 'upload-id-marker: args)])
         (let* ([query (append (list (list "uploads" ':: ""))
                         (if prefix
                             (list (list "prefix" ':: prefix))
                             (list))
                         (if delimiter
                             (list (list "delimiter" ':: delimiter))
                             (list))
                         (if max-uploads
                             (list
                               (list
                                 "max-uploads"
                                 '::
                                 (if (number? max-uploads)
                                     (number->string max-uploads)
                                     max-uploads)))
                             (list))
                         (if key-marker
                             (list (list "key-marker" ':: key-marker))
                             (list))
                         (if upload-id-marker
                             (list
                               (list
                                 "upload-id-marker"
                                 '::
                                 upload-id-marker))
                             (list)))])
           (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
             'query: query))))
  #|
  ;; remaining list-multipart-uploads case-lambda clauses removed
      [(client bucket-name prefix)
       (let* ([delimiter #f]
              [max-uploads #f]
              [key-marker #f]
              [upload-id-marker #f])
         (let* ([query (append (list (list "uploads" ':: ""))
                         (if prefix
                             (list (list "prefix" ':: prefix))
                             (list))
                         (if delimiter
                             (list (list "delimiter" ':: delimiter))
                             (list))
                         (if max-uploads
                             (list
                               (list
                                 "max-uploads"
                                 '::
                                 (if (number? max-uploads)
                                     (number->string max-uploads)
                                     max-uploads)))
                             (list))
                         (if key-marker
                             (list (list "key-marker" ':: key-marker))
                             (list))
                         (if upload-id-marker
                             (list
                               (list
                                 "upload-id-marker"
                                 '::
                                 upload-id-marker))
                             (list)))])
           (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
             'query: query)))]
      [(client bucket-name prefix delimiter)
       (let* ([max-uploads #f]
              [key-marker #f]
              [upload-id-marker #f])
         (let* ([query (append (list (list "uploads" ':: ""))
                         (if prefix
                             (list (list "prefix" ':: prefix))
                             (list))
                         (if delimiter
                             (list (list "delimiter" ':: delimiter))
                             (list))
                         (if max-uploads
                             (list
                               (list
                                 "max-uploads"
                                 '::
                                 (if (number? max-uploads)
                                     (number->string max-uploads)
                                     max-uploads)))
                             (list))
                         (if key-marker
                             (list (list "key-marker" ':: key-marker))
                             (list))
                         (if upload-id-marker
                             (list
                               (list
                                 "upload-id-marker"
                                 '::
                                 upload-id-marker))
                             (list)))])
           (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
             'query: query)))]
      [(client bucket-name prefix delimiter max-uploads)
       (let* ([key-marker #f] [upload-id-marker #f])
         (let* ([query (append (list (list "uploads" ':: ""))
                         (if prefix
                             (list (list "prefix" ':: prefix))
                             (list))
                         (if delimiter
                             (list (list "delimiter" ':: delimiter))
                             (list))
                         (if max-uploads
                             (list
                               (list
                                 "max-uploads"
                                 '::
                                 (if (number? max-uploads)
                                     (number->string max-uploads)
                                     max-uploads)))
                             (list))
                         (if key-marker
                             (list (list "key-marker" ':: key-marker))
                             (list))
                         (if upload-id-marker
                             (list
                               (list
                                 "upload-id-marker"
                                 '::
                                 upload-id-marker))
                             (list)))])
           (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
             'query: query)))]
      [(client bucket-name prefix delimiter max-uploads
        key-marker)
       (let* ([upload-id-marker #f])
         (let* ([query (append (list (list "uploads" ':: ""))
                         (if prefix
                             (list (list "prefix" ':: prefix))
                             (list))
                         (if delimiter
                             (list (list "delimiter" ':: delimiter))
                             (list))
                         (if max-uploads
                             (list
                               (list
                                 "max-uploads"
                                 '::
                                 (if (number? max-uploads)
                                     (number->string max-uploads)
                                     max-uploads)))
                             (list))
                         (if key-marker
                             (list (list "key-marker" ':: key-marker))
                             (list))
                         (if upload-id-marker
                             (list
                               (list
                                 "upload-id-marker"
                                 '::
                                 upload-id-marker))
                             (list)))])
           (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
             'query: query)))]
      [(client bucket-name prefix delimiter max-uploads key-marker
        upload-id-marker)
       (let* ([query (append (list (list "uploads" ':: ""))
                       (if prefix (list (list "prefix" ':: prefix)) (list))
                       (if delimiter
                           (list (list "delimiter" ':: delimiter))
                           (list))
                       (if max-uploads
                           (list
                             (list
                               "max-uploads"
                               '::
                               (if (number? max-uploads)
                                   (number->string max-uploads)
                                   max-uploads)))
                           (list))
                       (if key-marker
                           (list (list "key-marker" ':: key-marker))
                           (list))
                       (if upload-id-marker
                           (list
                             (list
                               "upload-id-marker"
                               '::
                               upload-id-marker))
                           (list)))])
         (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
           'query: query))]))
  |#
  (define (abort-multipart-upload client bucket-name key
           upload-id)
    (let ([req (s3-request/check client 'verb: 'DELETE 'bucket: bucket-name 'key: key
                 'query: (list (list "uploadId" ':: upload-id)))])
      (request-close req)
      (void))))
