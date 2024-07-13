#lang racket/base

(provide keybinding
         variable
         function
         definition
         UX
         flow
         step)

(require scribble/core
         (except-in scribble/manual
                    index)
         syntax/parse/define
         scribble/bnf
         (for-syntax racket/base
                     (only-in racket/list add-between))
         seq/iso
         syntax/parse)

(define-syntax-rule (keybinding arg)
  (bold (code arg)))

(define-syntax-rule (variable arg)
  (bold (code arg)))

(define-syntax-rule (function arg)
  (bold (code arg)))

(define-syntax-rule (UX (f ...) ...)
  (BNF (flow f ...) ...))

(define-syntax-rule (flow f ...)
  (list (step f) ...))

(define (make-titlecase word)
  (if (member (string-downcase word)
              (list "for" "the" "in" "and" "of"))
      word
      (append
       (string (char-upcase (first word)))
       (rest word))))

(define (titlecase str)
  (join-with " "
             (map make-titlecase
                  (cut " " str))))

;; This may not work if there's punctuation or other special
;; symbols in the name, so use `esc` in that case.
(define (link-identifier name)
  (replace-infix " " "_"
                 (titlecase name)))

(define-syntax-parser stage
  [(_ (s ...))
   #:with stx (datum->syntax this-syntax
                (add-between (syntax->list #'((step s) ...))
                             #'(step AND)))
   #`(list #,@(syntax->list #'stx))])

(define-syntax-parser step
  [(_ ((~datum link) f)) #'(nonterm (secref (link-identifier f)))]
  [(_ ((~datum link) ((~datum to) f) text)) #'(nonterm (seclink (link-identifier f) text))]
  [(_ ((~datum esc) f)) #'f]
  [(_ (~datum AND)) #'(litchar "&")]
  [(_ ((~datum or) e ...)) #'(BNF-alt (step e) ...)]
  [(_ ((~datum primitive) p)) #'(nonterm (tt p))]
  [(_ ((~datum stages) s ...))
   #:with parsed-stages #'((stage s) ...)
   #`(BNF-seq-lines #,@(syntax->list #'parsed-stages))]
  [(_ (e ...)) #'(BNF-seq (step e) ...)]
  [(_ f) #'(nonterm f)])

;; based on scribble-abbrevs/latex
(define (definition term . defn*)
  (make-paragraph plain
    (list
     (element #f (list (bold (deftech term)) ": "))
     defn*)))
