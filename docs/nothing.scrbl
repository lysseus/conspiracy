#lang scribble/manual

@title{Nothing Object}

The Nothing submodule of Conspiracy object implements a parent, sibling, child relationship.

@verbatim|{
> (require conspiracy/object
           (submod conspiracy/object Nothing))
'Object
'ε-Nothing
'Nothing
}|

@section{Containment}

This module specializes in a mechanism for representing an 'object tree'. The relationship among objects in the tree is independent of their relationships through inheritance or delegation. To help illustrate what we mean by an object tree we'll make use of the following classic diagram:

@verbatim{
meadow
   |
mailbox - player - torch
    |                |
  note             battery
}

In the @italic{meadow} there is a @italic{mailbox}, a @italic{player}, and a @italic{torch}. Inside the @italic{mailbox} is a @italic{note}. Inside the @italic{torch} is a @italic{battery}.

One way to model these relationships would be with a set of pointers: @italic{location} and @italic{contents}. The @italic{location} would point to a single object. The @italic{contents} would be a list of objects.

The @tt{Nothing} Library implements a different model using @tt{parent}, @tt{sibling}, @tt{child} relationships that place the object within the object tree.

@subsection{@tt{parent}}

In the above diagram we would say that @italic{meadow} is the parent of @italic{mailbox}, @italic{player}, and @italic{torch}. The @italic{mailbox} is the @tt{parent} of the @italic{note}. The @italic{torch} is the @tt{parent} of the @italic{battery}. Incidentally, the @italic{meadow} has a @tt{parent}, which is the @tt{Nothing} object itself.

@subsection{@tt{sibling}}

The @tt{sibling} of the @italic{mailbox} is the @italic{player}, but the relationship isn't reciprocal, it flows from left to right. The @tt{sibling} of the @italic{player} is the @italic{torch}. Finally, the @italic{torch} has no @tt{sibling}, or as the model would say, the @tt{sibling} of @italic{torch} is @tt{Nothing}. 

@subsection{@tt{child}}

While the objects in the @italic{meadow} can be spoken of as @tt{children} of the meadow, there is only one @tt{child} of @italic{meadow}, the @italic{mailbox}.

@section{Defining Objects Derived From @tt{Nothing}}

Object's derived from @tt{Nothing} have a special @tt{construct} property. This checks the object's directly-defined properties for @tt{parent}, @tt{sibling}, and @tt{child}  and adds any that are missing, assigning them the value of @tt{Nothing}. It then moves the object into the object tree.

@section{Defining The Object Tree}

An object derived from @tt{Nothing} @tt{implements} @tt{ε-Nothing}, which has 'existential exclusion properties' @tt{sibling} and @tt{child}. This means that these objects cannot have those properties in their definition (the library will supply them).

The following describes how to define an object tree:

@itemlist[
 @item{Define each object with the appropriate @tt{parent} property.}
 @item{Do not define @tt{sibling} or @tt{child} properties for the objects.}
 @item{Define sibling objects in right to left order.}]

Going back to our @italic{meadow} object tree:

@verbatim|{
> (% meadow)
'meadow
> (% torch   (parent meadow))
'torch
> (% battery (parent torch))
'battery
> (% player (parent meadow))
'player
> (% mailbox (parent meadow))
'mailbox
> (% note (parent mailbox))
'note
> (@ show meadow)
(% meadow
	(child mailbox)
	(kinds (Nothing))
	(parent Nothing)
	(sibling Nothing))
> (@ show mailbox)
(% mailbox
	(child note)
	(kinds (Nothing))
	(parent meadow)
	(sibling player))
> (@ show note)        
(% note
	(child Nothing)
	(kinds (Nothing))
	(parent mailbox)
	(sibling Nothing))
> (@ show player)        
(% player
	(child Nothing)
	(kinds (Nothing))
	(parent meadow)
	(sibling torch))
> (@ show torch)        
(% torch
	(child battery)
	(kinds (Nothing))
	(parent meadow)
	(sibling Nothing))
> (@ show battery)
(% battery
	(child Nothing)
	(kinds (Nothing))
	(parent torch)
	(sibling Nothing))
 }|

@section{@tt{Nothing} Properties}

The following documents the properties of @tt{Nothing}.

@subsection{@tt{in?}}

Returns #t if @italic{objname} is the @tt{parent} of @tt{self}.

@bold{Syntax:}

@verbatim|{
(|@bold{in?} |@italic{objname}) -> boolean?
  |@italic{objname}  : |@tt{object?}
}|

@subsection{@tt{is-in?}}

Determines if @tt{self} is in the sub-tree whose parent is @italic{objname}, and if so returns #t; otherwise returns #f.

@bold{Syntax:}

@verbatim|{
(|@bold{is-in?} |@italic{objname}) -> boolean?
  |@italic{objname}  : |@tt{object?}
}|

@subsection{@tt{move-to}}

Moves @tt{self} to @italic{objname} in the object-tree.

@bold{Syntax:}

@verbatim|{
(|@bold{move-to} |@italic{objname}) ->|
  |@italic{objname}  : |@tt{object?}
}|

In our @italic{meadow} object tree, suppose the player 'takes' the battery from the torch:

@verbatim|{
> (@ move-to battery player)
> (@ show player)
(% player
	(child battery)
	(kinds (Nothing))
	(parent meadow)
	(sibling torch))
> (@ show torch)
(% torch
	(child Nothing)
	(kinds (Nothing))
	(parent meadow)
	(sibling Nothing))
> (@ show battery)
(% battery
	(child Nothing)
	(kinds (Nothing))
	(parent player)
	(sibling Nothing))           
}|

And now suppose we move the torch to the mailbox.

@verbatim|{
> (@ move-to torch mailbox)
> (@ show mailbox)
(% mailbox
	(child torch)
	(kinds (Nothing))
	(parent meadow)
	(sibling player))
> (@ show note)        
(% note
	(child Nothing)
	(kinds (Nothing))
	(parent mailbox)
	(sibling Nothing))
> (@ show player)        
(% player
	(child battery)
	(kinds (Nothing))
	(parent meadow)
	(sibling Nothing))
> (@ show torch)        
(% torch
	(child Nothing)
	(kinds (Nothing))
	(parent mailbox)
	(sibling note))
> (@ show battery)        
(% battery
	(child Nothing)
	(kinds (Nothing))
	(parent player)
	(sibling Nothing))
}|

The examples above show that the 'eldest' sibling is the last in the chain. The @tt{move-to} always places the object as the @tt{child} of the new @tt{parent} and pushes the previous @tt{child} down the chain.

@subsection{@tt{parents}}

Accumulates a list by applying @italic{fn}, if provided, to each successive @tt{parent} of @tt{self} until @tt{Nothing} is reached. If @italic{fn} is #f then @italic{acc} is the list of successive @italic{parents} of the original object. 

@bold{Syntax:}

@verbatim|{
(|@bold{parents} [|@italic{fn}] [|@italic{acc}]) -> list?
  |@italic{fn}  : (or/c #f procedure?)
  |@italic{acc} : list?
}|

@subsection{@tt{siblings}}

Accumulates a list by applying @italic{fn}, if provided, to each successive @tt{sibling} of @tt{self} until @tt{Nothing} is reached. If @italic{fn} is #f then @italic{acc} is the list of successive @italic{siblings} of the original object. 

@bold{Syntax:}

@verbatim|{
(|@bold{siblings} [|@italic{fn}] [|@italic{acc}]) -> list?
  |@italic{fn}  : (or/c #f procedure?)
  |@italic{acc} : list?
}|

@subsection{@tt{children}}

Accumulates a list by applying @italic{fn}, if provided, to each successive @tt{child} of @tt{self} until @tt{Nothing} is reached. If @italic{fn} is #f then @italic{acc} is the list of successive @italic{children} of the original object. 

@bold{Syntax:}

@verbatim|{
(|@bold{children} [|@italic{fn}] [|@italic{acc}]) -> list?
  |@italic{fn}  : (or/c #f procedure?)
  |@italic{acc} : list?
}|

@subsection{@tt{contents}}

Returns a list of objects that are the @italic{contents} of this object. If the object has no contents, returns an empty list.

@bold{Syntax:}

@verbatim|{
(|@bold{contents}) -> list?           
}|

@section{@tt{Nothing} Functions and Macros}

The following documents the functions and macros of @tt{Nothing}.

@subsection{@tt{object-loop}}

Iterates over all objects. When @italic{pred} is supplied the object is considered for selection only when the procedure returns (not/c (or/c #f undefined?)). When @italic{acc} is supplied the body statements are only called once with the list of accumulated objects; otherwise body statements are called once for each object satisfying @italic{proc}. 

@bold{Syntax:}

@verbatim|{
(|@bold{object-loop} (|@italic{var} [|@italic{pred} [|@italic{acc}]] body0 body ...) -> any/c
   |@italic{pred}  : procedure?
   |@italic{acc}   : identifier?
}|

Note: This macro simulates the @italic{objectloop} of Graham Nelson's Inform language.

@bold{Examples:}
@verbatim|{
> (% meadow)
'meadow
> (% torch (parent meadow))
'torch
> (% battery (parent torch))
'battery
> (% player (parent meadow))
'player
> (% mailbox (parent meadow))
'mailbox
> (% note (parent mailbox))
'note
(object-loop (o) (printf "~%~a" o))
Object
battery
meadow
torch
mailbox
player
note
ε-Nothing
Nothing
(object-loop (o #t acc) acc)
'(% battery meadow torch mailbox player note ε-Nothing Nothing)
(object-loop (o (@ of-kind? o Nothing) acc) acc)
'(battery meadow torch mailbox player note Nothing)
(@ move-to torch player)
(object-loop (o (@ is-in? o player) acc) acc)
'(battery torch)
}|

Of course, it should be noted that Racket @italic{for loops} can offer more flexible and powerful alternatives.
