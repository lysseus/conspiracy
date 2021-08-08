#lang scribble/manual

@title{Characteristics Object}

@verbatim|{
(require conspiracy/object
         (submod conspiracy/object Characteristics)           
}|

Characteristics are those properties of an object that make it interesting. Conspiracy defines this as a relationship among 3 objects:

@itemlist[
 @item{An ι-props object defining properties required for those characteristics.}
 @item{A μ-props object defining the characteristic properties.}
 @item{A characteristics-template object.}]

@section{@tt{characteristics-template?}}

This method returns true when:
@itemlist[
 @item{The object derives from Characteristics.}
 @item{The object implements a μ-props object.}
 @item{The object is a template-object.}]

@section{The Characteristics Relationship}

Even when we meet the requirements of Characteristics, there's no guarantee that the μ-props properties will be satisfied by the values supplied when deriving from the characteristics-template. They may not reference the characteristics-template's ι-proops properties, or they may not be satisfied by them.

But to give an example of how characteristics are designed to work, imagine a circle template that produces objects calculating diameter, circumference, and area, given the readius of the circle.

Since @italic{radius} is our required template value, we define an ι-props object for it:

@verbatim|{
>(% ι-Circle (radius real?))
'ι-Circle
}|

No @tt{flags} property is needed for defining an ι-props object. By convention we prefix the objet name with "ι-" though this has no effect on the object definition. In addition we require the @tt{radius} to be a @italic{real} number.

Next we translate the following formulas into μ-props properties:

diameter = 2 * radius
circumference = 2 * pi * radius
area = pi * radius^2

into:
@verbatim|{
>(% μ-Circle (flags immutable μ-props)
   (diameter () (-> real?)
             (aux radius)
             (* 2 radius))
   (circumference () (-> real?)
                  (aux radius)
                  (* 2 pi radius))
   (area () (-> real?)
         (aux radius)
         (* pi radius radius)))
'μ-Circle         
}|

Notice that these properties take no argumentts, and get the @tt{radius} value from @tt{self}. We previx the object name with "μ-", again by convention. But this object must specify @tt{μ-props} in the @tt{flags} property to distinguish it from @tt{ι-props} and @tt{ε-props} implementations.

Also, we are using the @tt{aux} macro to bind @tt{radius} to the directly-defined property value of @tt{self}. Since these μ-props methods will be copied to our @italic{Characteristics} derived object, the @tt{construct} call will be to the object being constructed at that point. 

Next we define the @italic{characteristis-template}: 

@verbatim|{
>(% Circle (flags immutable no-assert)
    (implements ι-Circle μ-Circle)
    (kinds Characteristics))
'Circle   
}|

@section{@tt{characteristics}}

@bold{Syntax:}
@verbatim|{
(@ |@bold{characteristics} |@italic{objname} [|@tt{#:prop+val?}])
   |@italic{objname}   : |@tt{object?}
   |@tt{#:prop+val?} : (or/c |@bold{#f} #t) 
}|

This method returns:
@itemlist[
 @item{By default, or when #:prop+val? #f, a list of 2 elements: The first is a list is of the object's missing @tt{ι-props} propnames. The second is a list of the object's @tt{μ-props} propnames.}
 @item{When #:prop+val? #t, the sublists consist of the porpname / value pairs for those elements.}]

Conspiracy says that a @italic{characteristics-template} has no characteristics. By this it means that the template is merely a recipe for an object that does have characteristics. So the value of a propname/value pair is undefined for @italic{characteristics-templates}.

@italic{Characteristics-templates} produce immutable anonymous objects, creating directly-defined properties corresponding to the μ-props properties, for their derivations, excpet that the property values are the result of the property invocation. 

@verbatim|{
> (τ Circle radius: 10)
'obj#63998617
> (τ Circle radius: 10)
'obj#71842977
> (@ characteristics obj#71842977)
'((radius) (area circumference diameter))
> (@ characteristics obj#71842977 #:prop+val? #t)
'(((radius . 10)) ((area . 314.1592653589793) (circumference . 62.83185307179586) (diameter . 20)))
}|

@section{@tt{show} and characteristics}

Objects that have characteristics produce additional @tt{show} information.

@verbatim|{
> (@ show obj#71842977)
(% obj#71842977
	(area 314.1592653589793)
	(circumference 62.83185307179586)
	(diameter 20)
	(flags (immutable))
	(kinds (Circle))
	(radius 10))

 • obj#71842977 characteristics requirements:
	(radius 10)
 • obj#71842977 characteristics:
	(area 314.1592653589793)
	(circumference 62.83185307179586)
	(diameter 20)	(diameter 20)
}|

Objects that are not anonymous and mutable created with the @italic{characteristics-template} are different in that their @tt{μ-props} properties are not directly-defined with property values that are the result of the property invocation.

The directly-defined @tt{ι-props} properties of the mutable Characteristics object derivation can be changed, with a corresponding change in the reporting of characteristics.

@verbatim|{
> (% C (kinds Circle) (radius 20))
'C
> (@ show C)
(% C
	(kinds (Circle))
	(radius 20))

 • C characteristics requirements:
	(radius 20)
 • C characteristics:
	(area 1256.6370614359173)
	(circumference 125.66370614359172)
	(diameter 40)
> (! radius C 10)
> (@ show C)
(% C
	(kinds (Circle))
	(radius 10))

 • C characteristics requirements:
	(radius 10)
 • C characteristics:
	(area 314.1592653589793)
	(circumference 62.83185307179586)
	(diameter 20)           
}|

