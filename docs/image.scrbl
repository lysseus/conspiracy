#lang scribble/manual

@title{Object Image}

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

The objects defined by this library are either ι-props interfaces, mix-ins, or templates. As stated in the @italic{Templates} section. 
