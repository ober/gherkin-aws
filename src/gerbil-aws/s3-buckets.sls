#!chezscheme
(library (gerbil-aws s3-buckets)
  (export list-buckets create-bucket delete-bucket head-bucket
    get-bucket-location get-bucket-versioning
    put-bucket-versioning get-bucket-tagging put-bucket-tagging
    delete-bucket-tagging get-bucket-policy put-bucket-policy
    delete-bucket-policy)
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
    (compat request) (gerbil-aws s3-api))
  (define (list-buckets client)
    (let ([result (s3-request/xml client 'verb: 'GET)])
      (if (and (hash-table? result) (hash-get result 'Buckets))
          (let ([buckets (hash-get result 'Buckets)])
            (cond
              [(hash-table? buckets)
               (let ([bucket-list (hash-get buckets 'Bucket)])
                 (cond
                   [(list? bucket-list) bucket-list]
                   [(hash-table? bucket-list) (list bucket-list)]
                   [else (list)]))]
              [else (list)]))
          (list))))
  (define (create-bucket client bucket-name)
    (let ([client client])
      (let* ([body (if (equal?
                         (slot-ref client 'region)
                         "us-east-1")
                       #f
                       (string-append
                         "<CreateBucketConfiguration xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">"
                         "<LocationConstraint>" (slot-ref client 'region)
                         "</LocationConstraint>"
                         "</CreateBucketConfiguration>"))]
             [req (s3-request/check client 'verb: 'PUT 'bucket: bucket-name 'body: body
                    'content-type: (and body "application/xml"))])
        (request-close req)
        (void))))
  (define (delete-bucket client bucket-name)
    (let ([req (s3-request/check client 'verb: 'DELETE 'bucket:
                 bucket-name)])
      (request-close req)
      (void)))
  (define (head-bucket client bucket-name)
    (let* ([req (s3-request client 'verb: 'HEAD 'bucket:
                  bucket-name)]
           [status (request-status req)])
      (request-close req)
      (and (fx>= status 200) (fx< status 300))))
  (define (get-bucket-location client bucket-name)
    (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
      'query: (list (list "location" ':: ""))))
  (define (get-bucket-versioning client bucket-name)
    (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
      'query: (list (list "versioning" ':: ""))))
  (define (put-bucket-versioning client bucket-name status)
    (let* ([body (string-append
                   "<VersioningConfiguration xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">"
                   "<Status>" status "</Status>"
                   "</VersioningConfiguration>")]
           [req (s3-request/check client 'verb: 'PUT 'bucket: bucket-name 'query:
                  (list (list "versioning" ':: "")) 'body: body
                  'content-type: "application/xml")])
      (request-close req)
      (void)))
  (define (get-bucket-tagging client bucket-name)
    (s3-request/xml client 'verb: 'GET 'bucket: bucket-name
      'query: (list (list "tagging" ':: ""))))
  (define (put-bucket-tagging client bucket-name tags)
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
           [req (s3-request/check client 'verb: 'PUT 'bucket: bucket-name 'query:
                  (list (list "tagging" ':: "")) 'body: body 'content-type:
                  "application/xml")])
      (request-close req)
      (void)))
  (define (delete-bucket-tagging client bucket-name)
    (let ([req (s3-request/check client 'verb: 'DELETE 'bucket: bucket-name 'query:
                 (list (list "tagging" ':: "")))])
      (request-close req)
      (void)))
  (define (get-bucket-policy client bucket-name)
    (let* ([req (s3-request/check client 'verb: 'GET 'bucket: bucket-name 'query:
                  (list (list "policy" ':: "")))]
           [content (request-text req)])
      (request-close req)
      content))
  (define (put-bucket-policy client bucket-name policy)
    (let ([req (s3-request/check client 'verb: 'PUT 'bucket: bucket-name 'query:
                 (list (list "policy" ':: "")) 'body: policy 'content-type:
                 "application/json")])
      (request-close req)
      (void)))
  (define (delete-bucket-policy client bucket-name)
    (let ([req (s3-request/check client 'verb: 'DELETE 'bucket: bucket-name 'query:
                 (list (list "policy" ':: "")))])
      (request-close req)
      (void))))
