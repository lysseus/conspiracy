#lang scribble/manual
 
@title{Getting Started}

@section{Object Modules}

The following documents the modules that can be @italic{required} as part of the @italic{Object} Library

@subsection{Main Module}

For the purpose of this documentation it is assumed that the library has been made into a collection. We will be using the registration syntax provided by this module.

The 'main' module must always be required in using any Conspiracy Object module. It provides the database and various functions as well as @tt{Object} itself.

@verbatim|{
> (require conspiracy/object)
'Object
}|

The first thing to notice is that requiring the object module returns @tt{Object}. That's the symbol representing the 'root' object in the database.

@subsection{@tt{%object} Module}

This module provides a traditional version of registration syntax.
@itemlist[
 @item{(@tt{object} ...) can be used instead of (@tt{%} ...) for object definition.}
 @item{(@tt{replace-object} ...) can be used instead of (@tt{%=} for object replacement.}
 @item{(@tt{modify-object} ...) can be used instead of (@tt{%+} ...) for object modification.}
 @item{(@tt{remove-object} ...) can be used instead of (@tt{%-} ...) for object removal.}]

@verbatim|{
> (require conspiracy/object
           (submod conspiracy/object %object))
'Object
}|

@subsection{@tt{@"@"app} Module}

This module will map any form beginning with an unbound operator to the @tt{@"@"} operation. Any bound operator will be executed normally.

@verbatim|{
> (require conspiracy/object
           (submod conspiracy/object @"@"app))
'Object
}|

@bold{Examples:}
@verbatim|{
> (list a b c)
'(a b c)
> (of-kind Object Object)
#<undefined>
> (of-kind? Object Object)
#t           
}|

@subsection{@tt{Nothing} Module}

This module defines a basic 'object tree' mechanism.


@verbatim|{
> (require conspiracy/object
           (submod conspiracy/object Nothing))
'Object
'ε-Nothing
'Nothing
}|

@subsection{@tt{Rule} Module}

This module defines a basic 'Rules' mechanism.

@verbatim|{
> (require conspiracy/object
           (submod conspiracy/object Rule))
'Object
'Rule
}|

@section{Automatic Quoting of Unbound Symbols}

Conspiracy doesn't bind the symbols you choose for object or property names. It adopts the position of automatically quoting unbound symbols. While in 'normal' Racket you would receive an error message, in Conspiracy the unbound symbol is bounced back.
