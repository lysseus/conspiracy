#lang scribble/manual

@title{Object Image}

@(require conspiracy/object-image
          (submod conspiracy/object %object)
          (submod conspiracy/object scribble))

The object-image module of Conspiracy implements object equivalents of Racket 2htdp/image.

@verbatim|{
> (require conspiracy/object-image)           
'Object
'ε-Nothing
'Nothing
'ι-Container
'ι-Rectangular
'ι-Circular
'ι-Line
'ι-Linear
'ι-Linear/pulls
'ι-Regular-Polygon/angle
'ι-Regular-Polygon/angle/angle
'ι-2D-Point
'ι-Offsets
'ι-Text
'ι-Text/font
'ι-Polygon
'ι-Regular-Polygon/count
'ι-Regular-Polygon/pulls
'ι-Triangle/sss
'ι-Triangle/ass
'ι-Triangle/sas
'ι-Right-Triangle
'ι-Triangle/ssa
'ι-Triangle/aas
'ι-Triangle/asa
'ι-Triangle/saa
'ι-Star-Polygon
'ι-Radial-Star
'ι-Places
'ι-Posns
'Image
'Container
'Empty-Image
'Empty-Scene
'Ellipse
'Circle
'Line
'Add-Line
'Scene+Line
'Add-Curve
'Scene+Curve
'Add-Solid-Curve
'Text
'Text/font
'Polygon
'Regular-Polygon
'Pulled-Regular-Polygon
'Triangular
'Triangle/sss
'Triangle
'Triangle/ass
'Triangle/sas
'Isosceles-Triangle
'Right-Triangle
'Triangle/ssa
'Triangle/aas
'Triangle/asa
'Triangle/saa
'Rectangle
'Rhombus
'Square
'Star
'Star-polygon
'Radial-Star
'Add-Polygon
'Scene+Polygon
'Overlay
'Underlay
'Place-Image
'Place-Images
'Overlay/align
'Underlay/align
'Place-Image/align
'Place-Images/align
'Overlay/offset
'Underlay/offset
'Overlay/align/offset
'Underlay/align/offset
'Overlay/xy
'Underlay/xy
'Overlay/pinhole
'Underlay/pinhole
'Beside
'Above
'Beside/align
'Above/align
}|

@section{Rendering Images}

Racket's 2htdp/image library provides a number of image construction functions and combinators for combining images. Conspiracy encapsulates those functions into object equivalents.

You cannot render one of the library images directly. These definitions have been constructed as 'templates' from which functional objects can be derived.

For instance:

@verbatim|{
> (@ show Circle)
(% Circle
	(2htdp-image-render #<procedure:...nspiracy/object.rkt:266:42>)
	(characteristics! #<procedure:...nspiracy/object.rkt:266:42>)
	(child Nothing)
	(flags (immutable no-assert))
	(implements (ι-Circular ~ι-Rectangular))
	(kinds (Ellipse))
	(parent Nothing)
	(sibling Ellipse))

• Circle template requirements:
	(radius #<flat-contract: (and/c real? (not/c negative?))>)
• Circle is a template and cannot be rendered.
}|

@subsection{Templates}

In Conspiracy a template is created when an object:
@itemlist[
 @item{Is immutable.}
 @item{@tt{implements} @italic{ι-props} interfaces that require the existence of specified properties}
 @item{Does not satisfy the requirements of an @italic{ι-porops} interface.}
 @item{@tt{flags} no-assert}]

@bold{Example:}
@verbatim|{
> (% ι-Circular (flags immutable)
   (radius (and/c real? (not/c negative?))))
'ι-Circular
> (% Circle (flags immutable no-assert)
   (implements ι-Circular))
'Circle
> (@ show Circle)
(% Circle
	(flags (immutable no-assert))
	(implements (ι-Circular))
	(kinds (Object)))

• Circle template requirements:
	(radius #<flat-contract: (and/c real? (not/c negative?))>)
}|

Using the @tt{τ} template syntax (which incidentally is modelled slightly on Smalltalk's syntax), you can create an instance derived from the Circle object.

@bold{Example:}
@verbatim|{
> (@ show (τ Circle radius: 40))
(% obj#1636889
	(kinds (Circle))
	(radius 40))
}|

@subsection{Characteristics}

In Conspiracy, Characteristics are those properties that make an object interesting. This is accomplished by defining an object with the following conditions:

@itemlist[
 @item{Is a template.}
  @item{Inherits from the Characteristics object.}
 @item{@tt{implements} @italic{μ-props} objects whose properties are inserted into the object's directly-defined property list. The μ-props object's propeties become the characteristics of interest.}]

We can extend our Circle template above, giving it characteristics as follows:

@verbatim|{
> (% μ-Circular (flags μ-props) 
   (area () (-> real?)
         (aux radius)
         (* pi (sqr radius)))
   (circumference () (-> real?)
                  (aux radius)
                  (* 2 pi radius))
   (diameter () (-> real?)
             (aux radius)
             (* 2 radius)))
'μ-Circular
> (% Circle (kinds Characteristics) (flags immutable no-assert)
   (implements ι-Circular μ-Circular))
'Circle   
> (@ show (τ Circle radius: 40))
(% obj#3028974
	(area 5026.548246)
	(circumference 251.327412)
	(diameter 80)
	(flags (immutable))
	(kinds (Circle))
	(radius 40))

 • obj#3028974 characteristics requirements:
	(radius 40)
 • obj#3028974 characteristics:
	(area 5026.548246)
	(circumference 251.327412)
	(diameter 80)
}|

The object-image library implements its basic geometric objects with characteristics that are of interest from a geometrical perspective. What follows demonstrates the objects' rendering capabilities and does. Replacing @tt{render} with @tt{show} would produce results similar to those above examples, but with a rendering as well. Incidentally, the @tt{#:precision} keyword in the example below limits the display (not the calculation) to 2 decimal places. 

@bold{Example:}
@verbatim|{
> (@ show (τ Ellipse width: 60 height: 40) #:precision '(= 2))
(% obj#4214030
	(area 3769.91)
	(child Nothing)
	(eccentricity 0.75)
	(flags (immutable))
	(foci (#(struct:posn -22.360679774997898 0) #(struct:posn 22.360679774997898 0)))
	(height 40)
	(kinds (Ellipse))
	(parent Nothing)
	(sibling Above/align)
	(width 60))

 • obj#4214030 characteristics requirements:
	(height 40)
	(width 60)
 • obj#4214030 characteristics:
	(area 3769.91)
	(eccentricity 0.75)
	(foci (#(struct:posn -22.360679774997898 0) #(struct:posn 22.360679774997898 0)))

• Rendering:
|@($ render (τ Ellipse width: 60 height: 40) #:precision '(= 2))
}|