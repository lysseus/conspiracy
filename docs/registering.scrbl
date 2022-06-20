#lang scribble/manual
 
@title{Registering Objects}

Initially the objects database only contains @tt{Object}. In this section we briefly go over the ways that the database can be changed through four forms of registration

@section{Object Definition}

Registers an object in the objects database. Returns the object name.

@bold{Syntax:}

@verbatim|{
(|@bold{%} [|@italic{objname}] |@italic{property} ...)
  |@italic{objname}  : (and/c symbol? (not |@tt{object?}))
  |@italic{property} : (|@bold{flags} |@italic{flag} [|@italic{flag} ...])
          | (|@bold{kinds} |@italic{kind} [|@italic{kind} ...])
          | (|@bold{implements} |@italic{ntf} [|@italic{ntf} ...])
          | (|@italic{propname} |@italic{argspec} |@italic{ctcspec} body0 body ...)
          | (|@italic{propname} |@bold{(}value ...|@bold{)})
          | (|@italic{propname} value)
  |@italic{flag}     : symbol?
  |@italic{kind}     : |@tt{object?}
  |@italic{ntf}      : |@tt{object?}
  |@italic{propname} : symbol?            
  |@italic{argspec}  : Racket λ kw-formal
  |@italic{ctcspec}  : Racket function contract
}|

When @italic{objname} is not provided the library will generate a name from a gensym prefixed with 'obj# that is then interned for referencing.

Properties will be discussed further in separate sections.

@bold{Examples:}

@verbatim|{
> (%)
'obj#2125281
> (% A (sqr (n) (-> integer? integer?) (sqr n)))
'A
> (@ sqr A 25)
 Library/Mobile Documents/com~apple~CloudDocs/Racket/utils/conspiracy/object.rkt:801:5: @: contract violation
  expected: symbol?
  given: #<procedure:sqr>
> (@ 'sqr A 25)
625
> (@ show A)
(% A
	(kinds (Object))
	(sqr #<procedure:...nspiracy/object.rkt:270:42>))
}|

@section{Anonymous Definition}

Registers an 'anonymous' object in the objects database. Returns the object name. This is an alternative form of the @tt{%} 'anonymous' definition above.

@subsection{@tt{%*}}

@bold{Syntax:}

@verbatim|{
(|@bold{%*} |@italic{kind} ... |@italic{property} ...)
  |@italic{kind}     : |@tt{object?}
  |@italic{property} : (|@bold{flags} |@italic{flag} [|@italic{flag} ...])
          | (|@bold{implements} |@italic{ntf} [|@italic{ntf} ...])
          | (|@italic{propname} |@italic{argspec} |@italic{ctcspec} body0 body ...)
          | (|@italic{propname} |@bold{(}value ...|@bold{)})
          | (|@italic{propname} value)
  |@italic{flag}     : symbol?
  |@italic{ntf}      : |@tt{object?}
  |@italic{propname} : symbol?            
  |@italic{argspec}  : Racket λ kw-formal
  |@italic{ctcspec}  : Racket function contract
}|

This syntax is a shorter version of the anonymous variation of @tt{%}, but the results are the same. Note that @tt{kinds} is not a valid property in this syntax.

@bold{Examples:}
@verbatim|{
> (% A (p0 0))
'A
> (% B (p1 10))
'B
> (%* A B (p2 20))
'obj#26607112
> (@ show obj#26607112 #:flag +kinds)
(% obj#26607112
	(kinds (A B))
	(p2 20))
(% A
	(kinds (Object))
	(p0 0))
(% B
	(kinds (Object))
	(p1 10))
> (%*)
'obj#26628183
> (@ show obj#26628183)
(% obj#26628183
	(kinds (Object)))
> (%* B A (p42 42) (kinds A B))
obj#26671717: kinds property not valid in definition.
> (%* B A (p42 42))
'obj#26672992
> (@ show obj#26672992 +kinds)
(% obj#26672992
	(kinds (B A))
	(p42 42))
(% B
	(kinds (Object))
	(p1 10))
(% A        
}|

@subsection{@tt{τ}}

Anonymous object syntax especially useful for objects designed to behave as 'templates'.

@bold{Syntax:}
@verbatim|{
(|@bold{τ} |@italic{kind} [|@italic{kind} ...] property ...)
 |@italic{kind}     = |@tt{object?}
 |@italic{property}  = |@italic{propname}: val [val ...]
 |@italic{propname} : symbol?
}|

@bold{Note:}
@itemlist[
 @item{property names are identified by the @italic{:} suffix.}
  @item{@tt{kinds} is not a valid property in this form.}
 @item{A single value will produce a propname/value pair. Any properties requiring a list will neeed to have the value wrapped in a list function. This applies to special properties @tt{flags} and @tt{implements} as well.}]

@bold{Examples:}
@verbatim|{
> (% A)
'A
> (@ show A)
(% A
	(kinds (Object)))
> (τ A)
'obj#15994270
> (@ show obj#15994270)
(% obj#15994270
	(kinds (A)))
> (τ A p0: foo p1: bar baz p2: x y z)
'obj#16020613
> (@ show obj#16020613)
(% obj#16020613
	(kinds (A))
	(p0 foo)
	(p1 (bar baz))
	(p2 (x y z)))
> (τ A p0: (list foo))
'obj#16030671
> (@ show obj#16030671)
(% obj#16030671
	(kinds (A))
	(p0 (foo)))       
}|

@section{Object Replacement}

Replaces an object in the objects database.

@bold{Syntax:}

@verbatim|{
(|@bold{%=} |@italic{objname} |@italic{property} ...)
  |@italic{objname}  : |@tt{object?}
  |@italic{property} : (|@bold{flags} |@italic{flag} [|@italic{flag} ...])
          | (|@bold{kinds} |@italic{kind} [|@italic{kind} ...])
          | (|@bold{implements} |@italic{ntf} [|@italic{ntf} ...])
          | (|@italic{propname} |@italic{argspec} |@italic{ctcspec} body0 body ...)
          | (|@italic{propname} |@bold{(}value ...|@bold{)})
          | (|@italic{propname} value)
  |@italic{flag}     : symbol?
  |@italic{kind}     : |@tt{object?}
  |@italic{ntf}      : object?
  |@italic{propname} : symbol?            
  |@italic{argspec}  : Racket λ kw-formal
  |@italic{ctcspec}  : Racket function contract
}|

Properties will be discussed further in separate sections.

@bold{Examples:}

@verbatim|{
> (% A)
'A
> (@ show A)
(% A
	(kinds (Object)))
> (%= A (p0 42))
'A
> (@ show A)
(% A
	(kinds (Object))
	(p0 42))           
}|

@verbatim|{
> (% A (flags immutable))
'A
> (! p0 A 10)
 !: contract violation
  expected: mutable-object?
  given: 'A
  in: the 2nd argument of
      (-> symbol? mutable-object? any/c any)
  contract from: (function !)
  blaming: <pkgs>/conspiracy/object.rkt
   (assuming the contract is correct)
  at: <pkgs>/conspiracy/object.rkt:784.18
> (%=  A (p0 42))
'A
> (! p0 A 10)
> (@ show A)
(% A
	(kinds (Object))
	(p0 10))
 }|

@section{Object Modification}

Modifies an object in the objects database.

@bold{Syntax:}

@verbatim|{
(|@bold{%+} |@italic{objname} |@italic{property} [|@italic{property} ...])
  |@italic{objname}  : |@tt{object?}
  |@italic{property} : (|@bold{flags} |@italic{flag} [|@italic{flag} ...])
          | (|@bold{kinds} |@italic{kind} [|@italic{kind} ...])
          | (|@bold{implements} |@italic{ntf} [|@italic{ntf} ...])
          |(|@bold{remove} |@italic{propname} [|@italic{propname} ...])
          |(|@bold{replace} |@italic{property} [|@italic{property} ...])
          | (|@italic{propname} |@italic{argspec} |@italic{ctcspec} body0 body ...)
          | (|@italic{propname} |@bold{(}value ...|@bold{)})
          | (|@italic{propname} value)
  |@italic{flag}     : symbol?
  |@italic{kind}     : |@tt{object?}
  |@italic{ntf}      : |@tt{object?}
  |@italic{propname} : symbol?            
  |@italic{argspec}  : Racket λ kw-formal
  |@italic{ctcspec}  : Racket function contract
}|

Properties will be discussed further in separate sections.

Modification is a registration process that is more complicated than replacement. During modification the following steps occur:
@itemlist[
 @item{The directly-defined properties of the object are registered as a new @italic{modobject} whose object name is a gensym prefixed by 'mod# and then interned for referencing.}
 @item{The property clauses of @tt{%+} become the object's directly-defined property list, with the addition of a @tt{kinds} property pointing to the @italic{modobject}.}
 @item{Any @tt{replace} property values are removed from the @italic{modobject} and added to the object's directly-defined property list.}
 @item{Any @tt{remove} property values are removed from the object and its modifications.}
 @item{The object's @tt{construct} property is called.}]

@verbatim|{
           > (%+ Object (p0 42))
 object-modify: contract violation
  expected: mutable-object?
  given: 'Object
  in: the 1st argument of
      (->*
       (mutable-object?
        (non-empty-listof
         (cons/c
          (and/c symbol? (not/c 'kinds))
          any/c)))
       (#:construct? boolean?)
       symbol?)
  contract from: (function object-modify)
  blaming: <pkgs>/conspiracy/object.rkt
   (assuming the contract is correct)
  at: <pkgs>/conspiracy/object.rkt:449.18

}|

@subsection{Replacing Properties}

When it is desirable to remove a property from an object's modifications, providing a new version in its directly-defined properties we can accomplish this with the @tt{replace} property. The syntax of which is:

@verbatim|{
(|@bold{replace} |@italic{property} [|@italic{property} ...])           
}|

As we'll see later in discussions on inheritance, this will allow a method to pass control along the object's original @tt{kind-order}.

Examples:

@verbatim|{
> (% A (p0 0))
'A
> (%+ A (p0 1))
'A
> (%+ A (p0 2))
'A
> (%+ A (replace (p0 3)))
'A
> (@ show A #:flag +mods)
(% A
	(kinds (mod#2864351))
	(p0 3))
(% mod#2864351
	(kinds (mod#2864205)))
(% mod#2864205
	(kinds (mod#2864132)))
(% mod#2864132
	(kinds (Object)))           
}|

@subsection{Removing Properties}

In object modification a property can be removed from its modifications using a property with the following syntax:

@verbatim|{
(|@bold{remove} |@italic{propname} [|@italic{propname} ...])
}|

Examples:

@verbatim|{
> (% A (p0 0))
'A
> (%+ A (p1 1))
'A
> (%+ A (p2 2))
'A
> (%+ A (remove p0))
'A
> (@ show A #:flag +mods)
(% A
	(kinds (mod#2907069)))
(% mod#2907069
	(kinds (mod#2906919))
	(p2 2))
(% mod#2906919
	(kinds (mod#2906855))
	(p1 1))
(% mod#2906855
	(kinds (Object)))           
}|

@section{Object Removal}

Removes an object and its derivations and modifications from the objects database. Returns a list of all objects removed.

@bold{Syntax:}

@verbatim|{
(|@bold{%-} |@italic{objname})
  |@italic{objname}  : |@tt{object?}
}|

@bold{Examples:}

@verbatim|{
> (% A)
'A
> (%+ A (p0 42))
'A
> (% B (kinds A) (p0 100))
'B
> (%- A)
'(B A mod#2493110)           
}|
