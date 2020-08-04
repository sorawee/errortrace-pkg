#lang info
(define collection "errortrace-pkg")
(define deps '("base" "custom-load"))
(define build-deps '("errortrace-doc"
                     "scribble-lib" "racket-doc" "rackunit-lib"))
(define scribblings '(("scribblings/errortrace-pkg.scrbl" ())))
(define pkg-desc "Errortrace installed packages")
(define version "0.0")
(define pkg-authors '(sorawee))
