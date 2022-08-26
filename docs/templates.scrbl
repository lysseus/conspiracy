#lang scribble/manual

@title{Templates}

A template is an object definition that has the following:

@itemlist[
 @item{Is immutable.}
 @item{@tt{implements} @italic{ι-props} interfaces that require the existence of specified properties}
 @item{Does not satisfy the requirements of an @italic{ι-porops} interface.}
 @item{@tt{flags} no-assert}]

@bold{Examples:}
@verbatim|{
> (% A (p0 number?))
'A
> (% B (implements A) (flags immutable no-assert))
'B
}|

Now that we have defined B as a template-object, we can interrogate it.

@section{@tt{template-object?}}

@tt{Object} provides the @tt{template-object?} method, which returns true if the object satisfies the above definition of a template object. In our case @italic{B} does, @italic{A} does not:

@verbatim|{
> (@ template-object? A)
#f
> (@ template-object? B)
#t
}|

@section{@tt{template-objreqs}}

@tt{Object} provides this method, which returns the list of all missing object requirements for its ι-props interfaces, if the object is a @italic{template}. The list is empty if the object is not a @italic{template}.

@verbatim|{
> (@ template-objreqs A)
'()           
> (@ template-objreqs B)
(list (objreq 'ι-props 'A 'p0 #<procedure:number?> #t))
}|

@section{@tt{show} for @italic{template-objects}}

The @tt{show} method provides a convenient way to interrogate template objects. 

@verbatim|{
> (@ show B)
(% B
	(flags (immutable no-assert))
	(implements (A))
	(kinds (Object)))

• B template requirements:
	(p0 #<procedure:number?>)
}|

@section{τ form}

As described in the section on @italic{registration}, the @tt{τ} form is a convenient way to define an 'anonymous' object deriving from a template (Although the syntax can be used for other 'anonymous' object definitions as well.)

@verbatim|{
> (τ B)
obj#30820730 (B) does not implement A ι-props property (? p0 obj#30820730) -> #<procedure:number?>.
> (τ B p0: 42)
'obj#19611876
> (@ show obj#19611876)
(% obj#19611876
	(kinds (B))
	(p0 42))           
}|
