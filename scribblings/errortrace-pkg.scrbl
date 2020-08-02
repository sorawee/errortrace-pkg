#lang scribble/manual
@require[@for-label[racket/base errortrace-pkg/lib racket/contract]
         racket/string
         racket/function
         racket/list
         scribble/bnf]

@(define (explode line)
   (define (final xs)
     (define result
       (reverse (map (compose1 list->string reverse) xs)))
     (if (non-empty-string? (first result))
         result
         (rest result)))
   (for/fold ([acc '()]
              [active '()]
              [last #\space]
              #:result (final (cons active acc)))
             ([c (in-list (string->list line))])
     (cond
       [(equal? (char-whitespace? c)
                (char-whitespace? last))
        (values acc (cons c active) c)]
       [else
        (values (cons active acc) (list c) c)])))

@(define (error-style s)
   (cond
     [(char-whitespace? (string-ref s 0)) s]
     [else (racketerror s)]))

@(define (as-error . xs)
   (apply verbatim
          (append*
           (for/list ([line (in-list xs)])
             (map error-style (explode line))))))

@title{errortrace-pkg}
@author[(author+email "Sorawee Porncharoenwase" "sorawee.pwase@gmail.com")]

@defmodule[errortrace-pkg]

This package allows users to use @racketmodname[errortrace] on installed packages.

@section[#:tag "quick-instructions"]{Quick Instructions}

@itemize[
         @item{If your program has a module file @nonterm{prog}, run it with

               @commandline{racket -l errortrace-pkg -t @nonterm{prog} -- [--errortrace-pkg @nonterm{pkg}] ... @nonterm{rest-arg} ...}}

         @item{If your program is a non-module top-level sequence of
               definitions and expressions, add:
               @racketblock[
                 (require errortrace-pkg/lib)
                 (setup _pkgs)
               ]
               where @racket[_pkgs] is a list of package names. See @racket[setup] for details.
               }

         @item{If you have no main program and you want to use
               Racket interactively, include the @Flag{i} flag
               before @Flag{l}:
               @commandline{racket -i -l errortrace-pkg -- [--errortrace-pkg @nonterm{pkg}] ... @nonterm{rest-arg} ...}}
         ]

After starting @racketmodname[errortrace-pkg] in one of these ways, when an
exception occurs, the exception handler prints something like a stack trace
with most recent contexts first.

The @racketmodname[errortrace-pkg] module is strange: Don't import it
into another module. Instead, the @racketmodname[errortrace]
module is meant to be invoked from the top-level, so that it can install
an evaluation handler, exception handler, etc.

Unlike errortrace, there is no need to remove the @filepath{compiled} directory
before running programs.

@section{API}

@defmodule[errortrace-pkg/lib]

@defproc[(setup (pkgs (listof string?))) void?]{
  This function installs an evaluation handler, exception handler, etc.
  so that errortrace works. The errortrace will instrument code for non-packages
  and only packages specified in @racket[pkgs].

  Only call this function when the running program is @emph{not} a module.
  See @secref{quick-instructions} for the instructions.
}


@section{Example}

Following program @filepath{test.rkt} is a reduced version of @url{https://gist.github.com/anentropic/976121f288e7f0a2e91e8de082f44096}

@codeblock{
(require datalog)

(define (make-echo-hash)
  (impersonate-hash
    (make-hash)
    (lambda (hash key)
      (values
        key
        (lambda (hash key val)
          (printf "~a: ~a\n" key val))))
    (lambda (hash key val)
      (values key val))
    (lambda (hash key)
      key)
    (lambda (hash key)
      key)
    (lambda (hash)
      (hash-clear! hash))
    (lambda (hash key)
      key)))

(define family (make-echo-hash))

(datalog family
  (! (:- (nephew X Y)
          (nibling X Y)
          (male X))))

(datalog family (? (nephew X paul)))
}

Running

@commandline{racket test.rkt}

results in the following error:

@as-error{
for-each: contract violation
  expected: list?
  given: #<void>
}

To debug the error, one might attempt to use

@commandline{racket -l errortrace -t test.rkt}

However, the result is not helpful:

@as-error{
for-each: contract violation
  expected: list?
  given: #<void>
  errortrace...:
   /path/to/test.rkt:31:0: (datalog family (? (nephew X paul)))
}

The problem in this case is that the datalog module is not instrumented by errortrace,
so errortrace could not provide any useful information to us.

Instead, errortrace-pkg could be used to help with this kind of situation.
Running @commandline{racket -l errortrace-pkg -t test.rkt -- --errortrace-pkg datalog} results in:

@as-error{
for-each: contract violation
  expected: list?
  given: #<void>
  errortrace...:
   /path/to/pkgs/datalog/runtime.rkt:103:4: (for-each <elided> (get thy (subgoal-question sg)))
   /path/to/pkgs/datalog/eval.rkt:37:5: (prove (current-theory) (query-question s))
   /path/to/pkgs/datalog/stx.rkt:55:10: (idY21 lifted/18 <elided>)
   /path/to/pkgs/datalog/stx.rkt:53:9: (->substitutions <elided> <elided>)
}

In particular, it shows that @racket[(get thy (subgoal-question sg))] evaluates to @racket[(void)].
