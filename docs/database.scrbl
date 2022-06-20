#lang scribble/manual
 
@title{The Database}

Although its been said that objects can be represented as nothing more than structs with associated functions, Conspiracy takes a somewhat different approach of defining them as keys in a hash table whose values are hash tables of property keys and their values. 

As mentioned in the previous section on the quoting of unbound symbols, object and property names needn't have meaning outside the objects database.

@verbatim|{
> Object
'Object           
}|

On the other hand, it's perfectly possible to define an object named 'pi' or 'λ' in the objects database with meanings independent of their normal Racket bound values. In those cases, however, it will be important to remember to quote the symbol names to avoid operating on their bound values, rather than on their symbols.

But the practical upshot of this is that neither objects, nor properties, are first class values. You can't pass an object into a function, because it doesn't live outside of the database. 

@section{@tt{object-names}}

At any point the object names registered in the objects database can be retrieved with the object-names macro like this:

@verbatim|{
> object-names
'(Object)
}|

Although it's a list of object names, the list is constructed in arbitrary order and doesn't represent a historic perspective of object definition.

@section{@tt{objects}}

The @tt{objects} macro provides a 'raw' view of the objects database. By using it, you can glimpse 'under the hood' or 'behind the curtain' at the hash tables that comprise it.

@verbatim|{
> objects
'#hasheq((Object
          .
          #hasheq((assert . #<procedure:...nspiracy/object.rkt:270:42>)
                  (assert! . #<procedure:...nspiracy/object.rkt:270:42>)
                  ...
                  (set-method! . #<procedure:[...nspiracy/object.rkt:270:42>)
                  (show . #<procedure:...onspiracy/object.rkt:270:42>))))           
}|

We've abbreviated the properties listing for Object. But you can clearly see the key/value pairs of the hash tables involved, both of which use symbols for keys. 

So far we only have @tt{Object} registered in the database. But before we move on to defining, we need to discuss messaging in the @italic{messaging} section.

@section{Filtering}

As stated earlier, database object and property symbols are not bound by the library. This means you have to pass the database and its macro and function operators to modules that want to make use of Conspiracy objects.

Sometimes you might want a subset of the database instead. Conspiracy provides 2 forms that parameterize the database allowing you to filter it at the same time.

The following macros parameterize on:
@itemlist[
 @item{objects}
 @item{default-kind}
 @item{debug}]

Parameterizing these values means that within the context of the @tt{with-objects} and @tt{without-objects} macro bodies those values can be modified, but will be restored to their original values once control returns outside of the macros. 

@subsection{with-objects}

Filter objects by kinds and their @italic{inherited} objects.

@bold{Syntax:}

@verbatim|{
(|@bold{with-objects} (|@italic{kind} ...) body ...)
 }|

@bold{Examples:}

@verbatim|{
> object-names
'(Object)
> (with-objects () (% A) (% B) object-names)
'(B A Object)
> object-names
'(Object)
> (% A)
'A
> (% B)
'B
> (% C (kinds A B))
'C
> (with-objects (A) object-names)
'(A Object)
> (% D (kinds C))
'D
> (with-objects (C) object-names)
'(C B A Object)
> object-names
'(C B D A Object)
}|

@subsection{without-objects}

Filter-not objects by kinds and their @italic{modified} and @italic{inheriting} objects.

@bold{Syntax:}


@verbatim|{
(|@bold{without-objects} (|@italic{kind} ...) body ...)
 }|

@bold{Examples:}

@verbatim|{
           > object-names
'(Object)
> (% A)
'A
> (%+ A (p0 14))
'A
> (% B)
'B
> (% C (kinds A))
'C
> object-names
'(B mod#5944484 C A Object)
> (without-objects (A) object-names)
'(B Object)
> object-names
'(B mod#5944484 C A Object)
}|
