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

By default the debug parameter of the library is set to #f. At times you may want to set debugging on, which will display library variables during messaging.

To get and set debug, use @tt{debug} and @tt{debug!}.

@bold{Syntax:}

@verbatim|{
|@bold{debug}
}|

@verbatim|{
(|@bold{debug!} [|@italic{value}])
   |@italic{value} : boolean?
 }|

@bold{Examples:}

@verbatim|{
> debug
#f
> (debug!)
> debug
#t
> (debug! #t)
> debug
#t
> (debug! #f)
> debug
#f
}|

With debug on you'll see something like the following (the meanings of which will be explained in later sections.)

@verbatim|{
           > (% A (p0 42))
[@: construct A ()]
[construct:#<undefined> | target=A self=A | args=#<undefined>]
[construct:#<undefined> | target=A self=A | args=#<undefined>]
[Parameters:]
	self:		A
	target-prop:	construct
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:...nspiracy/object.rkt:260:42>
	invokee-arity:	#(struct:arity-at-least 0)
[construct:Object | target=A self=A | args=()]
[@: flags? A (no-assert)]
[flags?:Object | target=A self=A | args=()]
[flags?:Object | target=A self=A | args=()]
[Parameters:]
	self:		A
	target-prop:	flags?
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:...onspiracy/object.rkt:260:42>
	invokee-arity:	#(struct:arity-at-least 0)
[flags?:Object | target=A self=A | args=(no-assert)]
[@: prop-defined A (flags prop-def-directly)]
[prop-defined:Object | target=A self=A | args=(no-assert)]
[prop-defined:Object | target=A self=A | args=(no-assert)]
[Parameters:]
	self:		A
	target-prop:	prop-defined
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:...onspiracy/object.rkt:260:42>
	invokee-arity:	(1 2)
[prop-defined:Object | target=A self=A | args=(flags prop-def-directly)]
[@: assert! A ()]
[assert!:Object | target=A self=A | args=()]
[assert!:Object | target=A self=A | args=()]
[Parameters:]
	self:		A
	target-prop:	assert!
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:...nspiracy/object.rkt:260:42>
	invokee-arity:	0
[assert!:Object | target=A self=A | args=()]
[@: ntf-reqs A ()]
[ntf-reqs:Object | target=A self=A | args=()]
[ntf-reqs:Object | target=A self=A | args=()]
[Parameters:]
	self:		A
	target-prop:	ntf-reqs
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:...nspiracy/object.rkt:260:42>
	invokee-arity:	0
[ntf-reqs:Object | target=A self=A | args=()]
[@: prop-defined A (implements prop-def-directly)]
[prop-defined:Object | target=A self=A | args=()]
[prop-defined:Object | target=A self=A | args=()]
[Parameters:]
	self:		A
	target-prop:	prop-defined
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:...onspiracy/object.rkt:260:42>
	invokee-arity:	(1 2)
[prop-defined:Object | target=A self=A | args=(implements prop-def-directly)]
[@: prop-defined Object (implements prop-def-directly)]
[prop-defined:Object | target=Object self=Object | args=()]
[prop-defined:Object | target=Object self=Object | args=()]
[Parameters:]
	self:		Object
	target-prop:	prop-defined
	target-obj:	Object
	kind-order:	(Object)
	defining-obj:	Object
	invokee:	#<procedure:...onspiracy/object.rkt:260:42>
	invokee-arity:	(1 2)
[prop-defined:Object | target=Object self=Object | args=(implements prop-def-directly)]
[@: assert A ()]
[assert:Object | target=A self=A | args=()]
[assert:Object | target=A self=A | args=()]
[Parameters:]
	self:		A
	target-prop:	assert
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:...nspiracy/object.rkt:260:42>
	invokee-arity:	0
[assert:Object | target=A self=A | args=()]
[@: ntf-reqs A ()]
[ntf-reqs:Object | target=A self=A | args=()]
[ntf-reqs:Object | target=A self=A | args=()]
[Parameters:]
	self:		A
	target-prop:	ntf-reqs
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:...nspiracy/object.rkt:260:42>
	invokee-arity:	0
[ntf-reqs:Object | target=A self=A | args=()]
[@: prop-defined A (implements prop-def-directly)]
[prop-defined:Object | target=A self=A | args=()]
[prop-defined:Object | target=A self=A | args=()]
[Parameters:]
	self:		A
	target-prop:	prop-defined
	target-obj:	A
	kind-order:	(A Object)
	defining-obj:	Object
	invokee:	#<procedure:...onspiracy/object.rkt:260:42>
	invokee-arity:	(1 2)
[prop-defined:Object | target=A self=A | args=(implements prop-def-directly)]
[@: prop-defined Object (implements prop-def-directly)]
[prop-defined:Object | target=Object self=Object | args=()]
[prop-defined:Object | target=Object self=Object | args=()]
[Parameters:]
	self:		Object
	target-prop:	prop-defined
	target-obj:	Object
	kind-order:	(Object)
	defining-obj:	Object
	invokee:	#<procedure:...onspiracy/object.rkt:260:42>
	invokee-arity:	(1 2)
[prop-defined:Object | target=Object self=Object | args=(implements prop-def-directly)]
'A
> (? p0 A)
[?: p0 A ()]
[p0:#<undefined> | target=A self=A | args=#<undefined>]
[p0:#<undefined> | target=A self=A | args=#<undefined>]
42
 }|
