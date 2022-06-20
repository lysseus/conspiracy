#lang scribble/manual

@title{Pseudo-Variables}

We call these 'pseudo-variables' because they are 'read-only' and only meaningful during object messaging within the context of object methods.

@bold{Examples:}

@verbatim|{
> (% A
     (p0 42)
     (p1 "Hello, World!")
     (get (prop) (-> symbol? any)
          (? prop self)))
'A
> (@ get A p0)
42
> (@ get A p1)
"Hello, World!"
> (@ get A p2)
#<undefined>
> self
#<undefined>           
}|

In @italic{get} above we use the @tt{self} pseudo-variable to retrieve the values of various properties on the object belonging to (or inherited by) the object @italic{A}. Outside of the method, however, this pseudo-variable has an 'undefined' meaning.

Below is an alphabetical list of the library's pseudo-variables.

@section{@tt{defining-obj}}

Provides access at run-time to the current method definer. This is the object that actually defines the method currently  executing; in most cases, this is the object that defined the current method code in the source code of the program.

@section{directly-defined-properties}

Provides a reference to the object's directly-defined properties. This is an immutable hasheq table of property names and values. 

@section{@tt{invokee}}

Provides a pointer to the currently executing function.

@section{@tt{invokee-args}}

Provides a pointer to the currently executing function arguments.

@section{@tt{invokee-arity}}

Contains a normalized arity giving information about the number of by-position arguments accepted by @tt{invokee}.

@section{@tt{kind-order}}

Provides a reference to the collection of objects that form the @tt{target-obj} inheritance sequence.

@section{@tt{self}}

Provides a reference to the object whose method was originally invoked to reach the current method. Because of inheritance, this is not necessarily the object where the current method is actually defined.

@section{@tt{target-obj}}

Provides access at run-time to the original target object of the current method. This is the object that was specified in the method call that reached the current method. 

The target object remains unchanged when you use @tt{inherited} to inherit a kind's method, because the method is still executing in the context of the original call to the inheriting method.

The @tt{target-obj} value is the same as @tt{self} in normal method calls, but not  in calls initiated with the @tt{delegated} keyword. When @tt{delegated} is used,  the value of @tt{self} stays the same as it was in the delegating method,  and @tt{target-obj} gives the target of the delegated call.

@section{@tt{target-prop}}

Provides access at run-time to the current target property, which is the property that was invoked to reach the current method. This complements @tt{self},  which gives the object whose property was invoked.

@section{@tt{this}}

Equivalent to @tt{defining-obj}.
