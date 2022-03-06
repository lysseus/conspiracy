#lang scribble/manual

@title{Object Universe Rules}

The object-universe-rules module of Conspiracy implements object equivalents of Racket 2htdp/universe.

@verbatim|{
> (require conspiracy/universe-rules)           
'Object
'Rule
'Universe-Rule
'Tick-Rule
'Tick-Rules
'Key-Rule
'Key-Rules
'Mouse-Rule
'Mouse-Rules
'Button-Rule
'Button-Rules
}|

@section{Rendering Images}

Racket's 2htdp/image library provides a number of image construction functions and combinators for combining images. Conspiracy encapsulates those functions into object equivalents.

You cannot render one of the library images directly. These definitions habe been constructed as 'templates' from which functional objects can be derived.

For instance:

@verbatim|{
> (@ show Circle)
(% Circle
	(2htdp-image-render #<procedure:...nspiracy/object.rkt:266:42>)
	(characteristics! #<procedure:...nspiracy/object.rkt:266:42>)
	(child Nothing)
	(flags (immutable no-assert))
	(implements (ι-Circular ~ι-Rectangular))
	(kinds (Ellipse))
	(parent Nothing)
	(sibling Ellipse))

• Circle template requirements:
	(radius #<flat-contract: (and/c real? (not/c negative?))>)
• Circle is a template and cannot be rendered.
}|

@subsection{Templates}

The objects defined by this library are either ι-props interfaces, mix-ins, or templates. As stated in the @italic{Templates} section. 
