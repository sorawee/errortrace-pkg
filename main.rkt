#lang racket/base

(require racket/cmdline
         "lib.rkt")

(define pkgs '())

(command-line
 #:program "errortrace-pkg"
 #:multi
 [("--errortrace-pkg") pkg
                       "Instrument code in the given package"
                       (set! pkgs (cons pkg pkgs))]

 #:args args
 ; pass all unused arguments to the file being run
 (current-command-line-arguments (list->vector args))
 (void))

(setup pkgs)
