#lang scribble/manual

@title{Inheritance}

Conspiracy is a multiple inheritance paradigm. Conflict resolution is achieved from a deterministic algorithm that constructs at message application a @tt{kind-order} for the object receiving the message. The process begins working from left to right along the @tt{kind-order} looking at each @italic{kind's} directly-defined property list until it finds a match or exhausts the list, at which point it returns @tt{undefined}.

So how does this work in practice? Suppose we have 4 objects, defined as follows:

@verbatim|{
> (% Z (p 1))
'Z
> (% A (kinds Z))
'A
> (% B (kinds Z) (p 2))
'B
> (% C (kinds A B))
'C
}|

The question now is whether the message @italic{p} sent to @italic{C} returns 1 or 2?

@section{Resolving Inheritance Conflicts}

Conspiracy resolves inheritance by constructing the @tt{kind-order} in the following manner:

@itemlist[#:style 'ordered
 @item{Start with an empty @tt{kind-order}}
 @item{Set @tt{kind-order} index to 0.}
 @item{Append the object to the end of the @tt{kind-order}.}
 @item{Get the object at @tt{kind-order} index, if at end, stop}
 @item{For each kind in the object's @tt{kinds} list, working left to right, if it isn't in the @tt{kind-order}, append it to the @tt{kind-order}}
 @item{increment the @tt{kind-order} index}
 @item{Go to step 4}]

For our example above the @tt{kind-order} is (C A B Z Object) and the returned value is 2.

Once the system has built the kind-order inheritance begins looking for the desired property in the directly-defined properties of the objects from left to right. When it finds a match it stops --- unless told by the property to do otherwise. Conspiracy provides two ways for a property to do so: through the @tt{inherited} and @tt{delegated} functions.

@section{inherited}

Passes control to an inherited object.

@bold{Syntax:}

@verbatim|{
(|@bold{inherited} [|@tt{#:when-undefined}] [|@tt{#:propname}] [|@tt{#:objname}] arg ...)
  |@tt{#:when-undefined} : any/c                   
  |@italic{propname}         : symbol?
  |@italic{objname}          : |@tt{object?}
  |@italic{arg}              : any/c
}|

By default @tt{inherited} works its way down the @tt{kind-order} beginning with the next object in the list after the one the statement is defined in.

@tt{#:propname}: if supplied, it will look for that property name instead.

@tt{#:objname}: if supplied, it will begin searching downstream (rightward in the @tt{kind-order} from the object which is executing the @tt{inherited}, looking from that point.

Here's an example that works its way down the @tt{kind-order}:

@verbatim|{
> (% Z             (p () (-> any) (cons this (inherited #:when-undefined '()))))
'Z
> (% A (kinds Z)   (p () (-> any) (cons this (inherited #:when-undefined '()))))
'A
> (% B (kinds Z)   (p () (-> any) (cons this (inherited #:when-undefined '()))))
'B
> (% C (kinds A B) (p () (-> any) (cons this (inherited #:when-undefined '()))))
'C
> (@ p C)
'(C A B Z)
}|

@section{delegated}

Passes control to the delegated object.

@bold{Syntax:}

@verbatim|{
(|@bold{delegated} [|@tt{#:when-undefined}| [|@tt{#:propname}] |@tt{#:objname} arg ...)
  |@tt{#:when-undefined} : any/c                   
  |@italic{propname}         : symbol?
  |@italic{objname}          : |@tt{object?}
  |@italic{arg}              : any/c
}|

@bold{Examples:}

@verbatim|{
> (% Z (p0 () (-> any) this))
'Z
> (% A (kinds Z) (p0 () (-> any) (cons this (inherited))))
'A
> (% B (kinds Z) (p0 () (-> any) (cons this (inherited))))
'B
> (% C (kinds A B) (p0 () (-> any) (cons this (inherited))))
'C
> (% D (kinds A B) (p0 () (-> any) (cons this (delegated A))))
'D
> (@ p0 C)
'(C A B . Z)
> (@ p0 D)
'(D A . Z)           
}|

@section{Differences between Inherited and Delegated}

A key difference between delegation and inheritance can be observed from the examples above. Although both objects pass control to @italic{A}, which then passes control in both cases to @tt{inherited}, the inherited call to @italic{A} continues down the @tt{kind-order} of @italic{C}, while the delegated call to @italic{A} continues down the @tt{kind-order} of @italic{A}.
