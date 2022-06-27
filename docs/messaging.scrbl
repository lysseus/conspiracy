#lang scribble/manual
 
@title{Messaging Objects}

Once an object has been registered in the database it can be interacted with by use of the following property messages:

@itemlist[
 @item{Retrieval}
 @item{Application}
 @item{Setting}]

With small variations the syntax of Conspiracy messaging is the same for each message type.

(@italic{op} @italic{propname} @italic{objname} [@italic{arg} ...] [@tt{#:when-undefined}] [@tt{#:assert}])
@verbatim|{
|@italic{op}               : (or/c ? @"@" !)
|@italic{propname}         : symbol?
|@italic{objname}          : |@tt{object?}
|@italic{arg}              : any/c
|@tt{#:when-undefined} : any/c
|@tt{#:assert}         : contract?
  }|

A Conspiracy method can return any number of values:
@itemlist[
 @item{Zero    : (values)}
 @item{Single  : (values any/c)}
 @item{Multiple: (values any/c any/c ...)}]

@section{Retrieval}

This message retrieves the value of the property for the object.

This message does not accept arguments, but @tt{#:when-undefined} and @tt{#:assert} are both valid with the message.

@tt{#:when-undefined}: This can be any value that then becomes the result of the message when the message returns @tt{undefined}. This can occur if the property was assigned that value, or if the property was not directly-defined or inherited by this object.

@tt{#:assert}: This can be any contract that is then applied to the result of the message (after the optional #:when-undefined value was applied) to assert some condition on the result. If the condition is true the result is returned by the message, otherwise the message throws an error.

Examples:

@verbatim|{
           > (? show Object)
#<procedure:...onspiracy/object.rkt:270:42>
> (? foo Object)
#<undefined>
> (? foo Object #:when-undefined 42)
42
> (? foo Object #:when-undefined 42 #:assert string?)
 ...onspiracy/object.rkt:774:4: broke its own contract
  promised: string?
  produced: 42
  in: string?
  contract from: Object.foo
  blaming: Object.foo
   (assuming the contract is correct)

 }|

@section{Application}

This message applies the value of the property for the object to the arguments.

This message only enforces the arity of arguments when the value is a procedure, otherwise it ignores the arguments altogether.

@tt{#:when-undefined} is valid with the message. @tt{#:assert} is not valid.

Examples:

@verbatim|{
> (@ get-kind-order Object)
'(Object)
> (@ get-prop-params Object show)
'(3 () () #f)
  }|

@section{Setting}

This message sets the value of the property for a mutable object.

Examples:

@verbatim|{
           > (! kinds Object '(Object))
 !: contract violation
  expected: mutable-object?
  given: 'Object
  in: the 2nd argument of
      (-> symbol? mutable-object? any/c any)
  contract from: (function !)
  blaming: <pkgs>/conspiracy/object.rkt
   (assuming the contract is correct)
  at: <pkgs>/conspiracy/object.rkt:784.18
> (! foo Object #t)
 !: contract violation
  expected: mutable-object?
  given: 'Object
  in: the 2nd argument of
      (-> symbol? mutable-object? any/c any)
  contract from: (function !)
  blaming: <pkgs>/conspiracy/object.rkt
   (assuming the contract is correct)
  at: <pkgs>/conspiracy/object.rkt:784.18

  }|

@section{Debugging}

By default the @tt{debug?} parameter of the library is set to #f. At times you may want to set debugging on, which will display library variables during messaging.

To get and set debug, use @tt{debug?} and @tt{debug!}.

@bold{Syntax:}

@verbatim|{
|@bold{debug?}
}|

@verbatim|{
(|@bold{debug!} [|@italic{value}])
   |@italic{value} : boolean?
 }|

@bold{Examples:}

@verbatim|{
> debug?
#f
> (debug!)
> debug?
#t
> (debug! #t)
> debug?
#t
> (debug! #f)
> debug?
#f
}|

With debug on you'll see something like the following (the meanings of which will be explained in later sections.)

@verbatim|{
           > (% A (p0 42))
[@: ε-props-assert A ()]
[method-begin build-kind-order:#<undefined> #<undefined>]
[method-end build-kind-order:#<undefined> #<undefined> values: ((A Object))]
[method-begin prop-defined:#<undefined> #<undefined>]
[method-end prop-defined:#<undefined> #<undefined> values: (Object)]
[Parameters:]
	self:		A
	target-prop:	ε-props-assert
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:[...nspiracy/object.rkt:336:42>
	invokee-arity:	0
[method-begin ε-props-assert:Object ()]
[@: get-objreqs A ()]
[method-begin build-kind-order:Object ()]
[method-end build-kind-order:Object () values: ((A Object))]
[method-begin prop-defined:Object ()]
[method-end prop-defined:Object () values: (Object)]
[Parameters:]
	self:		A
	target-prop:	get-objreqs
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:[...nspiracy/object.rkt:336:42>
	invokee-arity:	0
[method-begin get-objreqs:Object ()]
[@: prop-defined A (implements prop-def-directly)]
[method-begin build-kind-order:Object ()]
[method-end build-kind-order:Object () values: ((A Object))]
[method-begin prop-defined:Object ()]
[method-end prop-defined:Object () values: (Object)]
[Parameters:]
	self:		A
	target-prop:	prop-defined
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:...onspiracy/object.rkt:336:42>
	invokee-arity:	(1 2)
[method-begin prop-defined:Object (implements prop-def-directly)]
[method-end prop-defined:Object (implements prop-def-directly) values: (#f)]
[@: prop-defined Object (implements prop-def-directly)]
[method-begin build-kind-order:Object ()]
[method-end build-kind-order:Object () values: ((Object))]
[method-begin prop-defined:Object ()]
[method-end prop-defined:Object () values: (Object)]
[Parameters:]
	self:		Object
	target-prop:	prop-defined
	target-obj:	Object
	kind-order:	(Object)
	defining-obj:	Object
	invokee:	#<procedure:...onspiracy/object.rkt:336:42>
	invokee-arity:	(1 2)
[method-begin prop-defined:Object (implements prop-def-directly)]
[method-end prop-defined:Object (implements prop-def-directly) values: (#f)]
[method-end get-objreqs:Object () values: ((() () () () () ()))]
[method-end ε-props-assert:Object () values: (#<void>)]
[@: μ-props-assert! A ()]
[method-begin build-kind-order:#<undefined> #<undefined>]
[method-end build-kind-order:#<undefined> #<undefined> values: ((A Object))]
[method-begin prop-defined:#<undefined> #<undefined>]
[method-end prop-defined:#<undefined> #<undefined> values: (Object)]
[Parameters:]
	self:		A
	target-prop:	μ-props-assert!
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:[...nspiracy/object.rkt:336:42>
	invokee-arity:	0
[method-begin μ-props-assert!:Object ()]
[@: get-objreqs A ()]
[method-begin build-kind-order:Object ()]
[method-end build-kind-order:Object () values: ((A Object))]
[method-begin prop-defined:Object ()]
[method-end prop-defined:Object () values: (Object)]
[Parameters:]
	self:		A
	target-prop:	get-objreqs
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:[...nspiracy/object.rkt:336:42>
	invokee-arity:	0
[method-begin get-objreqs:Object ()]
[@: prop-defined A (implements prop-def-directly)]
[method-begin build-kind-order:Object ()]
[method-end build-kind-order:Object () values: ((A Object))]
[method-begin prop-defined:Object ()]
[method-end prop-defined:Object () values: (Object)]
[Parameters:]
	self:		A
	target-prop:	prop-defined
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:...onspiracy/object.rkt:336:42>
	invokee-arity:	(1 2)
[method-begin prop-defined:Object (implements prop-def-directly)]
[method-end prop-defined:Object (implements prop-def-directly) values: (#f)]
[@: prop-defined Object (implements prop-def-directly)]
[method-begin build-kind-order:Object ()]
[method-end build-kind-order:Object () values: ((Object))]
[method-begin prop-defined:Object ()]
[method-end prop-defined:Object () values: (Object)]
[Parameters:]
	self:		Object
	target-prop:	prop-defined
	target-obj:	Object
	kind-order:	(Object)
	defining-obj:	Object
	invokee:	#<procedure:...onspiracy/object.rkt:336:42>
	invokee-arity:	(1 2)
[method-begin prop-defined:Object (implements prop-def-directly)]
[method-end prop-defined:Object (implements prop-def-directly) values: (#f)]
[method-end get-objreqs:Object () values: ((() () () () () ()))]
[method-end μ-props-assert!:Object () values: (#<void>)]
[@: construct A ()]
[method-begin build-kind-order:#<undefined> #<undefined>]
[method-end build-kind-order:#<undefined> #<undefined> values: ((A Object))]
[method-begin prop-defined:#<undefined> #<undefined>]
[method-end prop-defined:#<undefined> #<undefined> values: (#<undefined>)]
[Parameters:]
	self:		A
	target-prop:	construct
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	#<undefined>
	invokee:	#<undefined>
	invokee-arity:	#<undefined>
[@: flags? A (prop-not-defined)]
[method-begin build-kind-order:#<undefined> ()]
[method-end build-kind-order:#<undefined> () values: ((A Object))]
[method-begin prop-defined:#<undefined> ()]
[method-end prop-defined:#<undefined> () values: (Object)]
[Parameters:]
	self:		A
	target-prop:	flags?
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:...onspiracy/object.rkt:336:42>
	invokee-arity:	#(struct:arity-at-least 0)
[method-begin flags?:Object (prop-not-defined)]
[@: prop-defined A (flags prop-def-directly)]
[method-begin build-kind-order:Object (prop-not-defined)]
[method-end build-kind-order:Object (prop-not-defined) values: ((A Object))]
[method-begin prop-defined:Object (prop-not-defined)]
[method-end prop-defined:Object (prop-not-defined) values: (Object)]
[Parameters:]
	self:		A
	target-prop:	prop-defined
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:...onspiracy/object.rkt:336:42>
	invokee-arity:	(1 2)
[method-begin prop-defined:Object (flags prop-def-directly)]
[method-end prop-defined:Object (flags prop-def-directly) values: (#f)]
[method-end flags?:Object (prop-not-defined) values: (#f)]
[@: flags? A (no-assert)]
[method-begin build-kind-order:#<undefined> #<undefined>]
[method-end build-kind-order:#<undefined> #<undefined> values: ((A Object))]
[method-begin prop-defined:#<undefined> #<undefined>]
[method-end prop-defined:#<undefined> #<undefined> values: (Object)]
[Parameters:]
	self:		A
	target-prop:	flags?
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:...onspiracy/object.rkt:336:42>
	invokee-arity:	#(struct:arity-at-least 0)
[method-begin flags?:Object (no-assert)]
[@: prop-defined A (flags prop-def-directly)]
[method-begin build-kind-order:Object (no-assert)]
[method-end build-kind-order:Object (no-assert) values: ((A Object))]
[method-begin prop-defined:Object (no-assert)]
[method-end prop-defined:Object (no-assert) values: (Object)]
[Parameters:]
	self:		A
	target-prop:	prop-defined
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:...onspiracy/object.rkt:336:42>
	invokee-arity:	(1 2)
[method-begin prop-defined:Object (flags prop-def-directly)]
[method-end prop-defined:Object (flags prop-def-directly) values: (#f)]
[method-end flags?:Object (no-assert) values: (#f)]
[@: ι-props-assert A ()]
[method-begin build-kind-order:#<undefined> #<undefined>]
[method-end build-kind-order:#<undefined> #<undefined> values: ((A Object))]
[method-begin prop-defined:#<undefined> #<undefined>]
[method-end prop-defined:#<undefined> #<undefined> values: (Object)]
[Parameters:]
	self:		A
	target-prop:	ι-props-assert
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:[...nspiracy/object.rkt:336:42>
	invokee-arity:	0
[method-begin ι-props-assert:Object ()]
[@: get-objreqs A ()]
[method-begin build-kind-order:Object ()]
[method-end build-kind-order:Object () values: ((A Object))]
[method-begin prop-defined:Object ()]
[method-end prop-defined:Object () values: (Object)]
[Parameters:]
	self:		A
	target-prop:	get-objreqs
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:[...nspiracy/object.rkt:336:42>
	invokee-arity:	0
[method-begin get-objreqs:Object ()]
[@: prop-defined A (implements prop-def-directly)]
[method-begin build-kind-order:Object ()]
[method-end build-kind-order:Object () values: ((A Object))]
[method-begin prop-defined:Object ()]
[method-end prop-defined:Object () values: (Object)]
[Parameters:]
	self:		A
	target-prop:	prop-defined
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:...onspiracy/object.rkt:336:42>
	invokee-arity:	(1 2)
[method-begin prop-defined:Object (implements prop-def-directly)]
[method-end prop-defined:Object (implements prop-def-directly) values: (#f)]
[@: prop-defined Object (implements prop-def-directly)]
[method-begin build-kind-order:Object ()]
[method-end build-kind-order:Object () values: ((Object))]
[method-begin prop-defined:Object ()]
[method-end prop-defined:Object () values: (Object)]
[Parameters:]
	self:		Object
	target-prop:	prop-defined
	target-obj:	Object
	kind-order:	(Object)
	defining-obj:	Object
	invokee:	#<procedure:...onspiracy/object.rkt:336:42>
	invokee-arity:	(1 2)
[method-begin prop-defined:Object (implements prop-def-directly)]
[method-end prop-defined:Object (implements prop-def-directly) values: (#f)]
[method-end get-objreqs:Object () values: ((() () () () () ()))]
[method-end ι-props-assert:Object () values: (#<void>)]
'A
 }|
