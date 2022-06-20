#lang scribble/manual

@title{Special Properties}

Conspiracy properties are pairs of property name and value, but certain property names are 'special' in that they play a role in registration, inheritance, mutability, undefined property handling, and interfaces.

@section{Flags}

The @tt{flags} property has special usage within the library, as will be discussed below, and also has an unusual property syntax.

@bold{Syntax:}
@verbatim|{
(|@bold{flags} |@italic{flag} [|@italic{flag} ...])
  |@italic{flag}     : symbol? 
}|

The property's value is a list, and it can be defined as above, or in the usual ways that lists are represented:

@verbatim|{
> (% A (flags x y z))
'A
> (% B (flags '(x y z)))
'B
> (% C (flags (x y z)))
'C
> (% D (flags (list x y z)))
'D
> (@ show A)
(% A
	(flags (x y z))
	(kinds (Object)))
> (@ show B)
(% B
	(flags (x y z))
	(kinds (Object)))
> (@ show C)
(% C
	(flags (x y z))
	(kinds (Object)))
> (@ show D)
(% D
	(flags (x y z))
	(kinds (Object)))           
}|

@subsection{Interrogating Flags}

The flags mechanism in Conspiracy can be thought of as asking a question pertaining to the object. The flag is only relevant if the object directly-defines it. Flag interrogation is not inherited. Flags can be thought of as boolean values: their presence indicating true, their absence false.

The object message @tt{flags?} is used to interrogate the @tt{flags} property of an object. This message constrains the values to the directly-defined properties of the object, ignoring whether the object might inherit the flags property from other objects.

@bold{syntax}

@verbatim|{
(||@bold{@"@"} |@bold{flags?} |@italic{objname} [|@tt{#:al}] |@italic{flag} [|@italic{flag} ...])
  |@italic{objname}  : |@tt{object?}
  |@tt{#:all}    : boolean?
  |@italic{flag}     : symbol? 
}|

The @tt{#:all} boolean is #t by default. In that case the object must have all of the flags set in order for @tt{flags?} to return true. When @tt{#:all} is #f any flag match will cause @tt{flags?} to return #t.

@bold{Examples:}
@verbatim|{
> (% A (flags immutable x y z))
'A
> (@ flags? A immutable)
#t
> (@ flags? A w x y)
#f
> (@ flags? A #:all #f w x y)
#t
> (% B (kinds A))
'B
> (@ flags? B immutable)
#f           
}|

@subsection{Library Flags}

While any symbol can serve as a flag (even an object name), the library makes use of a handful of symbols for answering questions like:

@itemlist[
 @item{Is the object immutable?}
 @item{Does the object want to handle undefined properties itself?}
 @item{Does the object want to bypass asserting an interface it implements?}
 @item{Should any object that @tt{implements} this object treat it as an μ-props rather than an ι-props?}]

@subsubsection{@tt{immutable}}

By default Conspiracy objects are mutable.

Immutable objects cannot have their property values set with the @tt{!} operator.

Objects are defined immutable by registering them with an @tt{immutable} flag. Once this is done their @italic{directly-defined} property values cannot be modified (unless they are of a datatype that is itself mutable and referenced elsewhere.)

@subsubsection{@tt{no-assert}}

By default an object that @tt{implements} an interface asserts that the requirements of that interface during its construction. But there are times when you may wish to define an object that implements an interface which is only asserted by its derivations. In this manner you can simulate a template or class behavior.

By giving the object the @tt{no-assert} flag you tell the library that it must not enforce any directly-defined or inherited @tt{ι-props} or @tt{μ-props} interfaces.

@bold{Examples:}

@verbatim|{
> (% A (p0 number?))
'A
> (% B (implements A))
B does not implement A ι-props property (? p0 B) -> #<procedure:number?>.
> (% B (flags no-assert)
     (implements A))
'B     
|@margin-note*{@italic{B} is not a template-object, which requires the @tt{immutable} flag as well as @tt{no-assert}.}     
> (@ show B)
(% B
	(flags (no-assert))
	(implements (A))
	(kinds (Object)))
> (% C (kinds B) (p0 foo))
C does not implement A ι-props property p0 ->:
	Expected: #<procedure:number?>
	Actual: foo
> (% C (kinds B)
     (p0 42))
'C
> (@ show C)
(% C
	(kinds (B))
	(p0 42))           
}|

@subsubsection{@tt{prop-not-defined}}

The flag value @tt{prop-not-defined} tells the library to redirect any application operation to the object's @tt{prop-not-defined} method. This method can be directly-defined or inherited by the object, but the redirecting of undefined messages applies only when the object for whom the message is undefined provides the flag.

@bold{Examples:}

@verbatim|{
> (% B)
'B
> (@ foo B)
#<undefined>
> (%+ B (flags prop-not-defined)
     (prop-not-defined vals (->* () #:rest list? any) #f))
'B
> (@ foo B)
#f           
}|


In the example above, B does not define or inherit a @italic{foo} property. The library default returns @tt{undefined} in that situation. We could use the #:when-undefined keyword on the @tt{@"@"} call, but in this case the object has been modified to handle undefined properties itself. 

@subsubsection{@tt{ε-props}}

An object can be designated an 'ε-props' with the @tt{ε-props} flag (ε-props will be discussed in further detail in the @tt{implements} property section.)

@bold{Examples:}
@verbatim|{
> (% A (flags ε-props) (p0 undefined))
'A
> (% B (implements A) (p0 42))
B must not define ε-props A property p0
}|

@subsubsection{@tt{ι-props}}

An object can be designated an ι-props interface with the @tt{ι-props} flag (ι-props will be discussed in further detail in the @tt{implements} property section.

@subsubsection{@tt{μ-props}}

An object can be designated an μ-props interface with the @tt{μ-props} flag (μ-props will be discussed in further detail in the @tt{implements} property section.)

@bold{Examples:}
@verbatim|{
> (% A (flags μ-props)
     (p0 42))
'A
> (% B (implements A))
'B
> (@ show B)
(% B
	(implements (A))
	(kinds (Object))
	(p0 42))           
}|

@section{Kinds}

The @tt{kinds} property has special usage within the library, as will be discussed below, and also has an unusual property syntax.

@bold{Syntax:}
@verbatim|{
(|@bold{kinds} |@italic{kind} [|@italic{kind} ...])
  |@italic{kind}     : |@tt{object?} 
}|

The property's value is a list, and it can be defined as above, or in the usual ways that lists are represented:

@verbatim|{
> (% A)
'A
> (% B)
'B
> (% C (kinds A B))
'C
> (% D (kinds '(B A)))
'D
> (@ show C)
(% C
	(kinds (A B)))
> (@ show D)
(% D
	(kinds (B A)))
> (% E (kinds (C D)))
'E
> (@ show E)
(% E
	(kinds (C D)))
> (% F (kinds (list D E)))
'F
> (@ show F)
(% F
	(kinds (D E)))           
}|

In Conspiracy an object represents a 'kind' of thing. The @tt{kinds} property is perhaps one of the most important that can be defined for an object as it determines from which existing objects the new one will inherit.

@subsection{@tt{object?}}

The library defines the @tt{object?} predicate as any symbol registered as an object name in the objects database.

@verbatim|{
> (% A (kinds B))
 Library/Mobile Documents/com~apple~CloudDocs/Racket/utils/conspiracy/object.rkt:384:11: make-object: contract violation
  expected: (or/c (cons/c (quote kinds) (non-empty-listof (or/c (quote Object) (and/c (not/c (quote A)) object?)))) (cons/c (and/c symbol? (not/c (quote kinds))) any/c))
  given: '(kinds B)
  in: an element of
      the ps argument of
      (->i
       ((name
         (or/c
          #f
          (and/c symbol? (not/c object?))))
        (ps
         (name)
         (listof
          (or/c
           (cons/c 'kinds (non-empty-listof ...))
           (cons/c (and/c symbol? ...) any/c)))))
       (#:construct? (call () boolean?))
       (result symbol?))
  contract from: (function make-object)
  blaming: <pkgs>/conspiracy/object.rkt
   (assuming the contract is correct)
  at: <pkgs>/conspiracy/object.rkt:397.18           
}|
Initially the library bootstraps @tt{Object} as a valid @italic{kind} as well.

@verbatim|{
> (% A)
'A
> (object? A)
#t
> (object? B)
#f           
}|

@subsection{@tt{default-kind}}

Objects that do not specify a @tt{kinds} property in their definition are provided with one that uses the object(s) specified by the default-kind macro. Initially this value is set to 'Object, but it can be changed using the @tt{default-kind!} macro.

@bold{Examples}
@verbatim|{
> default-kind
'Object
> (% A)
'A
> (% B)
'B
> (default-kind! A B)
> (% C)
'C
> (@ show A)
(% A
	(kinds (Object)))
> (@ show B)
(% B
	(kinds (Object)))
> (@ show C)
(% C
	(kinds (A B)))
> default-kind
'(A B)
}|

@subsection{Inheritance Order}

The ordering of @tt{kinds}, like the naming of cats, is very important, as we'll learn in the section on inheritance. In the examples above the @tt{kinds} property for C shows the order '(A B), which would be very different in terms of inheritance from '(B A). More on that later.

@section{implements}

The @tt{implements} property allows an object to implement an interface: @tt{ι-props}, @tt{μ-props} or @tt{ε-props}.

@subsection{Implementing Interface Objects}

The following should be kept in mind:
@itemlist[
 @item{Interface assertion occurs at object registration. Objects are used to specify the interface. Any changes to an interface object after the object's registration do not affect the implementing object.}
 @item{If an error occurs in the assertion of an interface during object registration, the object definition is rolled back.}
 @item{an object definition can choose not to assert @tt{ι-props} and @tt{μ-props} interfaces during its construction using the @tt{no-assert} flag.}
 @item{Interfaces are inherited. An object's inheritance of interfaces follows its @tt{kind-order}}
 @item{An implementation can be removed from an object's inheritance through use of the @tt{~} prefixed to the interface object name.}]

@bold{Examples:}

@verbatim|{
> (% A (flags μ-props)
     (p0 14))
'A
> (% B (implements A) (flags no-assert))
'B
> (@ show B)
(% B
	(flags (no-assert))
	(implements (A))
	(kinds (Object)))
> (% C (kinds B))
'C
> (@ show C)
(% C
	(kinds (B))
	(p0 14))
> (% D (kinds C) (implements ~A))
'D
> (@ show D)
(% D
	(implements (~A))
	(kinds (C)))
> (% E (kinds D))
'E
> (@ show E)
(% E
	(kinds (D)))           
}|

Object's implementing @tt{ι-props} and @tt{μ-props} interfaces can choose to not assert the interface at the time of their construction.

@itemlist[
 @item{@tt{μ-props-assert!} is applied first to provide the object a chance to populate its directly-defined property list with required properties.}
 @item{@tt{(ι-props-assert} is applied after @tt{μ-props-assert!} to ensure the object provides the required properties.}]

@subsection{Implementing ε-props objects}

Sometimes it is desirable that an object @italic{not} define certain properties. This is useful when the object serves as a kind of 'template', where the @tt{ε-props} interfaces ensure the object will not define properties at registration that will later be overridden by object construction.

'Existential properties' interfaces are asserted after the object is registered, but before its @tt{construct} is invoked. If the object directly defines the properties of the @tt{ε-props} interface, then an error is thrown.

The @tt{ε-props} flag can be removed from an implementation chain with the @tt{~} prefixed to the @italic{ntf} object name.

@bold{Examples:}
@verbatim|{
> (% A (flags ε-props) (p0 undefined))
'A
> (% B (implements A))
'B
> (% C (kinds B) (p0 42))
C must not define ε-props A property p0
> (% C (kinds B) (p0 42) (implements ~A))
'C
}|
