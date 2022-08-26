#lang scribble/base

@(require (only-in scribble/core make-style)
          (only-in scribble/latex-properties latex-defaults+replacements))

@(define my-style
   (make-style
    #f
    (list (latex-defaults+replacements
           (list 'collects #"scribble" #"scribble-prefix.tex")
           (list 'collects #"scribble" #"scribble-style.tex")
           '()
           (hash "scribble-load-replace.tex" #"\\renewcommand{\\packageMathabx}{\\relax}\n")))))
 
@title[#:style my-style]{Conspiracy Library}
 
Conspiracy is an object-oriented paradigm. An object is defined as a collection of property ids and value pairs (i.e. properties) associated with a symbol name registered in the objects database. 

@include-section["getting-started.scrbl"]
@include-section["database.scrbl"]
@include-section["messaging.scrbl"]
@include-section["registering.scrbl"]
@include-section["special-properties.scrbl"]
@include-section["special-property-values.scrbl"]
@include-section["pseudo-variables.scrbl"]
@include-section["inheritance.scrbl"]
@include-section["templates.scrbl"]
@include-section["object.scrbl"]
@include-section["characteristics.scrbl"]
@include-section["nothing.scrbl"]
@include-section["rule.scrbl"]
