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
 
@title[#:style my-style]{Conspiracy 2htdp Library}
 
Conspiracy provides object-oriented variations of 2htdp/image functions.

@include-section["image.scrbl"]
@include-section["images.scrbl"]