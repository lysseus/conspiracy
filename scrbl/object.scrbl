#lang scribble/manual
 
@title{Object}
 
The Object library.

@itemlist[
 @item{Objects are 'classless', there is no need to instantiate them. They can, however, be @italic{flagged} as immutable, effectively making them a template for other objects.}
 @item{ Objects can inherit from multiple pre-defined objects. The specification of inheritance creates a deterministic @tt{kind-order} in which properties are located.}
 @item{Message passing can be controlled through @tt{inherited} and @tt{delegated} forms that pass control down the inheritance order or delegate to other objects. Inherited or delegated messages can specify a default response when the desired property is undefined.}
 @item{All object properties are 'public'; an object doesn't hide its properties from other objects.}
 @item{Properties are 'untyped'; any datatype can be associated with the property, although type can be enforced if the object @italic{implements an @tt{ι-props} interface} requesting it to do so. An object may implement a @tt{μ-props} that supplies a property and value for the object, if it does not already do so.}
 @item{Property values can be retrieved or applied, and unless the object is immutable, they can be set. Retrieval and application can specify what to return when the property is undefined. Additionally, an object can indicate a special @tt{prop-not-defined} method to handle situations when the property is not directly-defined or inherited.}
 @item{ An object can reference its own properties with the 'self' keyword.}
 @item{Objects can be dynamically @italic{replaced} in the database, effecting the inheritance order and behaviors of other objects.}
 @item{Objects can be dynamically @italic{modified} in the database, with a superseding definition that will inherit properties from the previous definition, or replace or remove them altogether.}
 @item{Objects can be dynamically @italic{removed} from the database, along with their descendants and modifications.}
 @item{The objects database can be parameterized to include only specified objects and their inheritance ancestors, or exclude specified objects and their descendants. }
 ]

@section{Object Properties}

The following is an alphabetical listing of properties directly-defined by @tt{Object}.

@subsection{@tt{build-kind-order}}

The inheritance order is deterministic (i.e., it will always be the same for a given situation), and it depends on the full kind tree of the original target object.

@bold{Syntax:}
@verbatim|{
(|@bold{@"@"} |@bold{build-kind-obrder} |@italic{objname} [|@italic{kind}])
 |@italic{objname} : |@tt{object?}
 |@italic{kind}    : (or/c |@bold{#f} |@tt{object?})
}|

@subsection{@tt{construct}}

Called during the object registration process to complete any work necessary to build the module definition.

@subsection{@tt{create-clone}}

Creates a new object that is an identical copy of this object. The new object will have the same kinds as the original, and the identical set of properties defined in the original. No constructor is called in creating the new object, since the object is explicitly initialized by this method to have the exact property values of the original.

The clone is a 'shallow' copy of the original, which means that the clone refers to all of the same objects as the original. For example, if a property of the original points to a vector, the corresponding  property of the clone points to the same vector, not a copy of the vector.

@subsection{@tt{create-instance}}

Creates a new instance of the target object. This method's arguments are passed directly to the constructor, if any, of the new object; this method doesn't make any other use of the arguments. The method creates the object, invokes the new object's constructor, then returns the new object.

@bold{Syntax:}
@verbatim|{
(|@bold{@"@"} |@bold{create-instance} |@italic{objname} [|@italic{arg} ...])
  |@italic{objname} : |@tt{object?}
  |@italic{arg}     : any/c
}|

@subsection{@tt{create-instance-of}}

Creates a new instance based on multiple kinds. This is a "static" (kind-level) method, so you can call it directly on kind. With no arguments, this simply creates a basic kind instance; this is equivalent to the create-instance method with no arguments.

The arguments give the kinds, in "dominance" order. The kinds appear in the argument list in the same order in which they'd appear in an object definition: the first argument corresponds to the leftmost kind in an ordinary object definition. Each argument is either a kind or a list. If an argument is a list, the first element of the list must be a kind, and the remainder of the elements are the arguments to pass to that kind's constructor. If an argument is simply a kind (not a list), then the constructor for this kind is not invoked at all.

@bold{Syntax:}
@verbatim|{
(|@bold{@"@"} |@bold{create-instance-of} |@italic{objname} [|@italic{arg} ...])
 |@italic{objname} : |@tt{object?}
 |@italic{arg}     : any/c
}|

@subsection{@tt{directly-inherits-kind}}

Produces a list of objects whose kinds property contains this object, or an empty list if there are none.

@subsection{@tt{directly-inherits-kind?}}

Returns true if all the args directly inherit from this object; false otherwise.

@bold{Syntax:}
@verbatim|{
(|@bold{@"@"} |@bold{directly-inherits-kind?} |@italic{objname} [|@italic{kind} ...])
 |@italic{objname} : |@tt{object?}
 |@italic{kind}     : |@tt{object?}
}|

@subsection{@tt{flags}}

See section on @tt{flags}. Object is set as @tt{immutable}.

@subsection{@tt{flags?}}

Returns #t if the object directly defines a flags property and the flags list contains the flags appropriate to the value of the @tt{#:all} keyword parameter.

@bold{Syntax:}
@verbatim|{
(|@bold{@"@"} |@bold{flags?} |@italic{objname} [|@tt{#:all}] |@italic{flag} [|@italic{flag} ...])
 |@italic{objname} : |@tt{object?}
 |@tt{#:all}       : boolean?
 |@italic{flag}    : symbol?
}|

When @tt{#:all} is #t (the default), then the object must match all the flags indicated. When @tt{#:all} is #f, then the method returns #t if any match. Otherwise returns #f.

@subsection{@tt{get-kinds-list}}

Returns a list containing the immediate kinds of the object. The list contains only the object's direct kinds, which are the objects that were explicitly listed in the object's @tt{kinds} property.

@subsection{@tt{get-kind-order}}

Returns the pre-built ordering of kinds created as part of the @tt{objeect-call} process. 

@subsection{@tt{get-method}}

Gets the procedure for one of the object's methods.

@bold{Syntax:}
@verbatim|{
(|@bold{@"@"} |@bold{get-method} |@italic{objname} |@italic{propname})
  |@italic{objname}  : |@tt{object?}
  |@italic{propname} : symbol?
}|

@subsection{@tt{get-objreqs}}

Returns a list of elements representing the 'object requirements' for the object:
@itemlist[
 @item{a list of properties required by interfaces, but missing from this object's definition/inheritance.}
 @item{a list of properties required by interfaces The elements of these lists are triples consisting of:}
 @item{propname}
 @item{interface property value}
 @item{interface name}]

@subsection{@tt{get-prop-list}}

Returns a list of the properties directly-defined by this object.  Each entry in the list is a property symbol. The returned list contains only properties directly-defined by the object; inherited properties are not included, but may be obtained by explicitly traversing the @tt{kinds} list and calling this method on each kind.

@subsection{@tt{get-prop-params}}

Returns a list of information associated with the parameters and result of the property associated with this object, or #f if the property is undefined.

@itemlist[
 @item{mask encoding of by-position arguments}
 @item{list of required keyword arguments}
 @item{list of accepted keyword arguments}
 @item{result arity}]

@bold{Syntax:}
@verbatim|{
(|@bold{@"@"} |@bold{get-prop-params} |@italic{objname} |@italic{prop})
 |@italic{objname} : |@tt{object?}
 |@italic{prop}    : symbol?
}|

@subsection{@tt{inherits-kind}}

Produces a list of objects inheriting from this object, or an empty list if there are none.

@subsection{@tt{inherits-kind?}}

Returns true if all the args inherit from this object; false otherwise.

@bold{Syntax:}
@verbatim|{
(|@bold{@"@"} |@bold{inherits-kind?} |@italic{objname} [|@italic{kind} ...])
 |@italic{objname} : |@tt{object?}
 |@italic{kind}    : |@tt{object?}
}|

@subsection{@tt{kinds}}

See section on @tt{kinds}. Object is the only object registered in the database whose @tt{kinds} property lists itself.

@subsection{@tt{modifies}}

Produces a list of objects modified by this object. If the object hasn't been modified the list is empty.

@subsection{@tt{of-kind?}}

Determines if the object is an instance of the kind, or an instance inheriting from kind. Returns true if so, #f if not. This method always returns true if kind is Object, since every object ultimately derives from Object.

@bold{Syntax:}
@verbatim|{
(|@bold{@"@"} |@bold{of-kind?} |@italic{objname} |@italic{kind})
 |@italic{objname} : |@tt{object?}
 |@italic{kind}    : |@tt{object?}
}|

@subsection{@tt{prop-defined}}

Determines if the object defines or inherits the property propname, according to the flags value. If flags is not specified, a default value of prop-def-any is used. 

@bold{Syntax:}
@verbatim|{
(|@bold{@"@"} |@bold{prop-defined} |@italic{objname} |@italic{propname} [|@italic{flag}])
 |@italic{objname}  : |@tt{object?}
 |@italic{propname} : symbol?
  |@italic{flag}    : (or/c |@bold{prop-def-any}
                            prop-def-directly
                            prop-def-inherits
                            prop-def-get-kind)
}|

The valid flags values are:

@tabular[#:sep @hspace[1]
         (list (list @bold{Flag} @bold{Function Returns})
               (list "prop-def-any"
                     "#t if the object defines or inherits the property; Otherwise #f")
               (list "prop-def-directly"
                     "#t only if the object directly-defines the property; if it inherits the property from a kind, the function returns #f.")
               (list "prop-def-inherits"
                     "#t only if the object inherits the property from a kind; if it defines the property directly, or doesn't define or inherit the property at all, the function returns #f.")
               (list "prop-def-get-kind"
                     "the kind from which the property is inherited, or this object if the object defines the property directly. If the object doesn't define or inherit the property, the function returns undefined."))]

@subsection{@tt{prop-inherited}}

Determines if the object inherits the property prop. target is the "original target object," which is the object on which the method was originally invoked. definer is the "defining object," which is the object defining the method which will b inheriting the kind
 implementation.

@bold{Syntax:}
@verbatim|{
(|@bold{@"@"} |@bold{prop-inherited} |@italic{objname}
  |@italic{propname}
  |@italic{target}
  |@italic{definer}
  [|@italic{flag}])
  |@italic{objname}  : |@tt{object?}
  |@italic{propname} : symbol?
  |@italic{taget}    : |@tt{object?}
  |@italic{definer}  : |@tt{object?}
  |@italic{flag}     : (or/c |@bold{prop-def-any}
                             prop-def-get-kind)
}|

The return value depends on the value of the flags argument:

@tabular[#:sep @hspace[1]
         (list (list @bold{Flag} @bold{Function Returns})
               (list "prop-def-any"
                     "#t if the object defines or inherits the property; Otherwise #f")
               (list "prop-def-get-kind"
                     "the kind from which the property is inherited, or this object if the object defines the property directly. If the object doesn't define or inherit the property, the function returns undefined."))]

This method is most useful for determining if the currently active method will invoke an inherited version of the method if it uses the inherited operator; this is done by passing targetprop for the prop parameter, targetobj for the target parameter, and defining-obj for the definer parameter. When a kind is designed as a "mix-in" (which means that the kind is designed to be used with multiple inheritance as one of several base kinds, and adds some isolated functionality that is "mixed" with the functionality of the other base kinds), it sometimes useful to be able to check to see if the method is inherited from any other base kind involved in multiple inheritance. This method allows the caller to determine exactly what inherited will do.

@subsection{@tt{prop-type}}

Returns the datatype of the given property of the given object, or undefined if the object does not define or inherit the property. This function does not evaluate the property, but merely determines its type. The return value is one of the symbols returned by examining the @tt{struct->vector} of the value.

@bold{Syntax}
@verbatim|{
(|@bold{@"@"} |@bold{prop-type} |@italic{objname} |@italic{prop})
 |@italic{objname} : |@tt{object?}
 |@italic{prop}    : symbol?
}|

@subsection{@tt{set-kinds-list!}}

Sets the @tt{kinds} property of the object to the specified list of objects.

@bold{Syntax:}
@verbatim|{
(|@bold{@"@"} |@bold{set-kinds-list!} |@italic{objname} |@italic{kinds})
 |@italic{objname} : |@tt{object?}
 |@italic{kinds}   : (listof |@tt{object?})
}|

@subsection{@tt{set-method!}}

Assigns the procedure proc as a method of the object, using the property prop.

@bold{Syntax:}
@verbatim|{
(|@bold{@"@"} |@bold{set-method!} |@italic{objname} |@italic{propname} |@italic{proc} [|@tt{#:contract}])
 |@italic{objname}  : |@tt{object?}
 |@italic{propname} : symbol?
  |@italic{proc}    : procedure?
  |@tt{#:contract}  : contract?
}|

If a contract is provided then the proc is bound to it. 

@subsection{@tt{show}}

Displays the defined definition of self object.
    
@bold{Syntax:}
@verbatim|{
(|@bold{@"@"} |@bold{show} |@italic{objname} [|@italic{#:flag}
                   |@italic{#sign}
                   |@italic{#:precision}
                   |@italic{#:notation}
                   |@italic{#:format-exponent}])]
 |@italic{objname} : |@tt{object?}
 |@italic{#:flag}    : (or/c |@bold{#f} +kinds +mods +all 'chs)
 |@italic{#:sign}    : (or/c |@bold{#f } '+ '++ 'parens
                           (let ([ind (or/c string? (list/c string? string?))])
                             (list/c ind ind ind)))
 |@italic{#:precision} : (or/c exact-nonnegative-integer?
                                (list/c '= exact-nonnegative-integer?))
 |@italic{#:notation} : (or/c |@bold{'positional} 'exponential
                               (-> rational? (or/c 'positional 'exponential)))
 |@italic{format-exponent} : (or/c |@bold{#f} string? (-> exact-integer? string?))
}|

@italic{Flag} options are:

@itemlist[
 @item{+kinds - displays the object and its directly-defined kinds.}
  @item{+mods - displays all mods in self kind-order list.}
 @item{+all - displays all kinds in self kind-order list.}
 @item{chs - displays requirements and characteristics.}]

The @italic{sign}, @italic{precision}, @italic{notation}, and @italic{format-exponent} optional arguments control formating for inexact number property values, based on the @italic{~r} formatting rules. 

@subsection{@tt{ε-props-assert}}

Objects that implement @tt{ε-props} flagged objects must NOT define the ε-props object properties.

@subsection{@tt{ι-props-assert}}

Enforces the interfaces this object @tt{implements}. If the object does not implement a property indicated by one of its interfaces an error is thrown. By default this is only enforced when the object is constructed. The @tt{no-assert} flag can be used to bypass this object's assertion though it will still affect objects derived from this object.

@subsection{@tt{μ-props-assert!}}

Enforces the @tt{μ-props} interfaces this object @tt{implements}. Adds the interface properties to this object when it doesn't directly-define or inherit them. The order of interfaces takes precedence.

@section{Object Functions and Macros}

The following is an alphabetical listing of object functions and macros.

@subsection{aux}

A macro that binds property namess to their values for the directly-defined propertiees of @tt{self} during a method call.

@bold{Syntax:}
@verbatim|{
(|@bold{aux} |@italic{var} [|@italic{var} ...])
 |@italic{var}     = |@italic{varname}
                   | (|@italic{varname} value)
 |@italic{varname} : |@tt{symbol?}               
}|

@bold{Examples:}
@verbatim|{
> (% Rectangle
     (width 3)
     (height 2)
     (area () (-> real?)
           (aux width height)
           (+ width height)))
'Rectangle
> (@ area Rectangle)
5           
}|

It's important to remember that the @italic{varname} is bound to the object's associated directly-defined property value, and to @tt{undefined} if it does not exist. If the property is a method the method procedure is returned, not the application of the method. 

@subsection{@tt{debug}}

A macro that produces diagnostic displays associated with object messaging.

@subsection{@tt{debug!}}

A macro for setting the @tt{debug} boolean.

@bold{Syntax:}
@verbatim|{
(|@bold{debug!} |@italic{value})
 |@italic{value} : boolean?
}|

@subsection{@tt{default-kind}}

A macro for returning the default kind(s) that objects inherit when they are not defined with a @tt{kinds} property.

@subsection{@tt{default-kind!}}

A macro for setting the value of @tt{default-kind}.

@bold{Syntax:}
@verbatim|{
(|@bold{default-kind!} |@italic{kind} [|@italic{kind} ...])
 |@italic{kind} : |@tt{object?}
}|

@subsection{@tt{defining-obj}}

A pseudo-variable. Provides access at run-time to the current method definer. This is the object that actually defines the method currently  executing; in most cases, this is the object that defined the current method code in the source code of the program.

@subsection{@tt{delegated}}

A function for passing control to another object's property and @tt{kind-order}.

@subsection{directly-defined-properties}

A pseudo-variable. Provides access at run-time to the @tt{self} object's directly-defined properties.

@subsection{@tt{immutable-object?}}

A function for determining whether an object is immutable. Returns @tt{(and (object? @italic{value}) (@"@" flags? @italic{value} immutable))}

@bold{Syntax:}
@verbatim|{
(|@bold{immutable-object?} |@italic{value}))           
}|

Immutable objects prohibit property modification through @tt{!}.

@subsection{@tt{inherited}}

A function for passing control down the object's @tt{kind-order}.

@subsection{@tt{invokee}}

A pseudo-variable. Provides a pointer to the currently executing function.

@subsection{@tt{invokee-args}}

A pseudo-variable. Provides a pointer to the currently executing function arguments.

@subsection{@tt{invokee-arity}}

A pseudo-variable. Contains a normalized arity giving information about the number of by-position arguments accepted by @tt{invokee}.

@subsection{@tt{kind-order}}

A pseudo-variable. Provides a reference to the collection of objects that form the inheritance sequence.

@subsection{@tt{mutable-object?}}

A function for determining whether an object is mutable. Returns @tt{(not (immutable-object? @italic{value}))}

@bold{Syntax:}
@verbatim|{
(|@bold{mutable-object?} |@italic{value}))           
}|

Objects are mutable by default. 

@subsection{@tt{object}}

A macro for defining objects (See section Object Defining).

@subsection{@tt{objects}}

A macro for the objects database.

@subsection{@tt{objects-copy}}

A function for filtering the objects database. Returns a hash copy of objects filtering on kinds. Results are as follows:
@tabular[#:sep @hspace[1]
         (list (list @bold{filter-not?}
                     @bold{kinds}
                     @bold{contains})
               (list "#f"
                     "o"
                     "o and inherited kinds")
               (list "#t"
                     "o"
                     "All objects except o, o modifies, and inheriting o")
               (list "#f"
                     "empty"
                     "Empty database")
               (list "#t"
                     "empty"
                     "All objects currently in database"))]

@subsection{@tt{object-names}}

A macro for object names registered in the objects database.

@subsection{@tt{object->list}}

A function that converts an object into a list consisting of the object name followed by property value pairs.

@bold{Examples:}
@verbatim|{
> (% A
    (p0 () (-> any) #t)
    (p1 'foo)
    (p2 (a b c)))
'A
> (object->list A)
'(A (kinds Object) (p0 . #<procedure:...nspiracy/object.rkt:260:42>) (p1 . foo) (p2 a b c))           
}|

@subsection{@tt{object?}}

A function for determining whether a value is an object. Returns #t if the value is a symbol registered in the objects database; otherwise #f.

@bold{Syntax:}
@verbatim|{(|@bold{object?} |@italic{value}}|

@subsection{@tt{Object?}}

A function used to identify the Object symbol. Returns #t if the value is @tt{'Object}; otherwise #f.

@bold{Syntax:}
@verbatim|{(|@bold{Object?} |@italic{value}}|

@subsection{@tt{objreq}}

A struct identifying 'object requirements'.

@bold{Syntax}
@verbatim|{
(|@bold{objreq} |@italic{type} |@italic{objname} |@italic{propname} |@italic{value} |@italic{proc?})
 |@italic{type} :
  |@italic{objname}  : |@tt{object?}
  |@italic{propname} : symbol?
  |@italic{value}    : any/c
  |@italic{proc?}    : boolean?
}|

This is a representation of an individual object property requirement. The type determines which interface type should be asserted.

@subsection{@tt{self}}

A pseudo-variable. Provides a reference to the object whose method was originally invoked to reach the current method. Because of inheritance, this is not necessarily the object where the current method is actually defined.

@subsection{@tt{target-obj}}

A pseudo-variable. Provides access at run-time to the original target object of the current method. This is the object that was specified in the method call that reached the current method. 

@subsection{@tt{target-prop}}

A pseudo-variable. Provides access at run-time to the current target property, which is the property that was invoked to reach the current method. This complements @tt{self},  which gives the object whose property was invoked.

@subsection{@tt{this}}

A pseudo-variable. Equivalent to @tt{defining-obj}.

@subsection{@tt{true?}}

A function specific to Conspiracy truth and falsehood. Returns #t when @italic{value} is neither #f or @tt{undefined}.

@bold{Syntax}
@verbatim|{
(|@bold{true?} |@italic{value})
}|

@subsection{@tt{undefined}}

A symbol representing 'undefined' values. 

@subsection{@tt{undefined?}}

A function for determining whether a value is the @tt{undefined} datatype. Returns #t if the value is @italic{undefined}; otherwise #f.

@bold{Syntax:}
@verbatim|{
(|@bold{undefined?} |@italic{value})
 |@italic{value} : any/c
}|

@subsection{@tt{without-objects}}

A macro for parameterizing the current-objects, current-default-kind, and current-debug, restoring their values once the context of the macro has terminated.

Filter objects by kinds and their inherited objects.

@subsection{@tt{with-objects}}

A macro for parameterizing the current-objects, current-default-kind, and current-debug, restoring their values once the context of the macro has terminated.

Filter-not objects by kinds and their modified and inheriting objects.


@subsection{@tt{!}}

A function for setting the property value of an object.

@subsection{@tt{%}}

A macro for registering objects.

@subsection{@tt{%*}}

A macro for registering 'anonymous' objects.

@subsection{@tt{%+}}

A macro for registering modifed objects in the database.

@subsection{@tt{%-}}

A macro for unregistering objects from the database.

@subsection{@tt{%=}}

A macro for registering the replacement of an object in the database.

@subsection{@tt{?}}

A function for retrieving the property value of an object.

@subsection{@tt{@"@"}}

A function for applying the property value of an object to the specified arguments.

@subsection{@tt{τ}}

A macro for registering 'anonymous' objects in a 'template' fashioned syntax.

@subsection{@tt{#%top}}

A macro wrapping unbound identifiers in quotes.

@subsection{@tt{τ}}

A macro for registering 'anonymous' objects in a 'template' fashioned syntax. 