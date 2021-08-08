#lang scribble/manual

@title{Special Property Values}

In Conspiracy all properties consist of pairs of property name and property value. The previous section discussed the library's unique meanings for the property names: @tt{flags}, @tt{implements}, and @tt{kinds}. But it handles certain values as special-case syntax.

@section{Methods}

A method is a procedure, represented by a property, specific to an object, that can be applied to arguments. To do this we use the @tt{@"@"} operator. When this is done the 'arity' of the function, the number of parameters it requires must agree with the number of arguments it receives. 

Earlier we discussed how the @tt{?} operator could @italic{assert} values on the results of its function. The @tt{@"@"} operator lacks that feature because all procedures defined using the object method syntax require function contracts.

This requirement of the method syntax is easy to forget, but its usefulness is that it ensures the method has maximum control over the data it receives and the data it produces.

@bold{Syntax:}

@verbatim|{
(|@italic{propname} |@italic{argspec} |@italic{ctcspec} body0 body ...)
  |@italic{propname} : symbol?           
  |@italic{argspec}  : Racket λ kw-formal
  |@italic{ctcspec}  : Racket function contract
}|

In other words, the property is defined just as though it were a Racket function being defined with the define/contract form.

@bold{Examples:}
@verbatim|{
> (% A (double (n) (-> number? number?) (* 2 n)))
'A
> (@ double A 13)
26
> (% B (add vs (->* () #:rest (listof number?) number?) (apply + vs)))
'B
> (@ add B 1 2 3)
6           
}|

@section{Nested Objects}

A property value can be an 'anonymous' object definition. Recall that an anonymous object is one for which the library provides the object name in the form of a gensym prefixed by @italic{'obj#} and then interned for referencing.

The nested object can define any of the normal object properties, but gets a special @tt{lexical-parent} property added in its directly-defined properties that points to the object it is nested in.

@bold{Examples:}
@verbatim|{
> (% (p0 (% (p0 (%)))))
'obj#5302530
> (@ show obj#5302530)
(% obj#5302530
	(kinds (Object))
	(p0 obj#5302531))
> (@ show obj#5302531)
(% obj#5302531
	(kinds (Object))
	(lexical-parent obj#5302530)
	(p0 obj#5302532))
> (@ show obj#5302532)
(% obj#5302532
	(kinds (Object))
	(lexical-parent obj#5302531))           
}|

@section{Lambda Forms}

The lambda function definition is a valid object property value.

@bold{Examples:}

@verbatim|{
> (% A (p0 (λ v v)))
'A
> (@ show A)
(% A
	(kinds (Object))
	(p0 #<procedure:...nspiracy/object.rkt:275:32>))
> ((? p0 A) "Hello, World!")
'("Hello, World!")           
}|

@section{Quoted and Quasiquoted Values}

You can quote and quasiquote the property value in the normal Racket way.

@bold{Examples:}

@verbatim|{
> (% A
     (p0 'pi)
     (p1 `(x y ,pi)))
'A
> (@ show A)
(% A
	(kinds (Object))
	(p0 pi)
	(p1 (x y 3.141592653589793)))           
}|

@section{@italic{(...)} Values}

This value special form behaves as follows:
@itemlist[
 @item{When empty it represents the empty list.}
 @item{When the first element is not a procedure it produces a list of the values.}
 @item{When the first element is a procedure, it is treated as a procedure call.}]

@bold{Examples:}
@verbatim|{
> (% A
     (p0 (+ 1 2 3))
     (p1 ('+ x y z))
     (p2 ((λ x x) 1 2 3)))
'A
> (@ show A)
(% A
	(kinds (Object))
	(p0 6)
	(p1 (+ x y z))
	(p2 (1 2 3)))           
}|