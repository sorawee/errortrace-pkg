#lang racket/base

(provide setup)
(require racket/string
         racket/match
         setup/dirs
         pkg/path
         custom-load)

(define (path-prefix? a b)
  (string-prefix? (path->string (resolve-path a))
                  (path->string (resolve-path b))))

(define (setup pkgs)
  (current-load/use-compiled
   (make-custom-load/use-compiled
    #:blacklist
    (λ (path)
      (cond
        ;; NOTE: we rely on the fact that (find-collects-dir) has the suffix "/"
        [(path-prefix? path (find-collects-dir)) #f]
        [else
         (match (path->pkg path)
           [#f #t]
           [pkg-name (member pkg-name pkgs)])])))))
