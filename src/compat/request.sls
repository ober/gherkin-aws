#!chezscheme
;; HTTP request compat module - native HTTPS via chez-ssl/chez-https
;; Replaces the old curl-based implementation with in-process TLS.
(library (compat request)
  (export http-get http-post http-put http-delete http-head
          request-status request-text request-content
          request-headers request-close)
  (import (chez-https)))
