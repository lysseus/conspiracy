#lang racket

;;;
;;; Conspiracy Objeect Image
;;;
;;; Provides a number of basic image construction functions, along with
;;; combinators for building more complex images out of existing images.
;;; Basic images include various polygons, ellipses and circles, and text,
;;; as well as bitmaps.
;;;


(provide (all-from-out "object.rkt"
                       2htdp/image)
         posn? posn make-posn
         default-outline-mode
         default-outline-mode!
         default-pen-or-color
         default-pen-or-color!
         default-font-size
         default-font-size!
         default-color
         default-color!)

(require (for-syntax syntax/parse)
         "object.rkt"
         2htdp/image
         (only-in lang/htdp-advanced posn? posn make-posn)
         (submod "object.rkt" Nothing)
         (submod "object.rkt" Characteristics))

(module+ test (require rackunit
                       (submod "..")))

;;=========================================================================================
;; Psuedo-variables
;;=========================================================================================

(define/contract current-default-outline-mode
  (parameter/c mode?)
  (make-parameter "solid")) 
;; default-outline-mode: a macro that provides the value of current-default-outline-mode.
(define-syntax default-outline-mode
  (λ (stx) (syntax-parse stx [default-outline-mode:id #'(current-default-outline-mode)])))
;; default-outline-mode!: a macro that sets the value of current-default-outline-mode.
(define-syntax default-outline-mode!
  (λ (stx) (syntax-parse stx
             [(_ v:id)
              #'(current-default-outline-mode (quote v))]
             [(_ v:expr)
              #'(current-default-outline-mode v)])))

(define/contract current-default-pen-or-color
  (parameter/c (or/c image-color? pen?))
  (make-parameter "gold")) 
;; default-pen-or-color: a macro that provides the value of current-default-pen-or-color.
(define-syntax default-pen-or-color
  (λ (stx) (syntax-parse stx [default-pen-or-color:id #'(current-default-pen-or-color)])))
;; default-pen-or-color!: a macro that sets the value of current-default-pen-or-color.
(define-syntax default-pen-or-color!
  (λ (stx) (syntax-parse stx
             [(_ v:id)
              #'(current-default-pen-or-color (quote v))]
             [(_ v:expr)
              #'(current-default-pen-or-color v)])))

(define/contract current-default-font-size
  (parameter/c (and/c integer? (between/c 1 255)))
  (make-parameter 20)) 
;; default-font-size: a macro that provides the value of current-default-font-size.
(define-syntax default-font-size
  (λ (stx) (syntax-parse stx [default-font-size:id #'(current-default-font-size)])))
;; default-font-size!: a macro that sets the value of current-default-font-size.
(define-syntax default-font-size!
  (λ (stx) (syntax-parse stx
             [(_ v:expr)
              #'(current-default-font-size v)])))

(define/contract current-default-color
  (parameter/c (or/c image-color? pen?))
  (make-parameter "green")) 
;; default-color: a macro that provides the value of current-default-color.
(define-syntax default-color
  (λ (stx) (syntax-parse stx [default-color:id #'(current-default-color)])))
;; default-color!: a macro that sets the value of current-default-color.
(define-syntax default-color!
  (λ (stx) (syntax-parse stx
             [(_ v:id)
              #'(current-default-color (quote v))]
             [(_ v:expr)
              #'(current-default-color v)])))

;;=====================================================================================
;; Interfaces
;;=====================================================================================

(default-kind! Object)

(% ι-Container (flags immutable)
   (container-lower nonnegative-integer?)
   (container-upper (or/c #f procedure? nonnegative-integer?)))

(% ι-Rectangular (flags immutable)
   (width  (and/c real? (not/c negative?)))
   (height (and/c real? (not/c negative?))))

(% ι-Circular (flags immutable)
   (radius (and/c real? (not/c negative?))))

(% ι-Line (flags immutable)
   (x1 real?)
   (y1 real?))


(% ι-Linear (flags immutable)
   (x1 real?)
   (y1 real?)
   (x2 real?)
   (y2 real?))

(% ι-Linear/pulls (flags immutable)
   (x1     real?)
   (y1     real?)
   (x2     real?)
   (y2     real?)
   (angle1 angle?)
   (angle2 angle?)
   (pull1  real?)
   (pull2  real?))

(% ι-Regular-Polygon/side (flags immutable)
   (side (and/c real? (not/c negative?))))

(% ι-Regular-Polygon/side/angle (flags immutable)
   (side  (and/c real? (not/c negative?)))
   (angle angle?))

(% ι-2D-Point (flags immutable)
   (x real?)
   (y real?))

(% ι-Offsets (flags immutable)
   (x-offset real?)
   (y-offset real?))

(% ι-Text (flags immutable)
   (text-string string?))

(% ι-Text/font (flags immutable)
   (text-string string?)
   (face        (or/c string? #f))
   (family      (or/c "default" "decorative" "roman" "script"
                      "swiss" "modern" "symbol" "system"
                      'default 'decorative 'roman 'script
                      'swiss 'modern 'symbol 'system))
   (style      (or/c "normal" "italic" "slant"
                     'normal 'italic 'slant))
   (weight     (or/c "normal" "bold" "light"
                     'normal 'bold 'light))
   (underline?  any/c))

(% ι-Polygon (flags immutable)
   (vertices (listof (or/c real-valued-posn? pulled-point?))))

(% ι-Regular-Polygon/count (flags immutable)
   (side        (and/c real? (not/c negative?)))
   (side-count  side-count?))

(% ι-Regular-Polygon/pulls (flags immutable)
   (pull  real?)
   (angle angle?))

(% ι-Isosceles-Triangle (flags immutable)
   (side  (and/c real? (not/c negative?)))
   (angle angle?))

(% ι-Triangle/sss (flags immutable)
   (a (and/c real? (not/c negative?)))
   (b (and/c real? (not/c negative?)))
   (c (and/c real? (not/c negative?))))

(% ι-Triangle/ass (flags immutable)
   (α angle?)
   (b  (and/c real? (not/c negative?)))
   (c  (and/c real? (not/c negative?))))

(% ι-Triangle/sas (flags immutable)
   (a  (and/c real? (not/c negative?)))
   (β angle?)
   (c  (and/c real? (not/c negative?))))

(% ι-Right-Triangle (flags immutable)
   (a (and/c real? (not/c negative?)))
   (b (and/c real? (not/c negative?))))

(% ι-Triangle/ssa (flags immutable)
   (a  (and/c real? (not/c negative?)))
   (b  (and/c real? (not/c negative?)))
   (γ angle?))

(% ι-Triangle/aas (flags immutable)
   (α angle?)
   (β angle?)
   (c  (and/c real? (not/c negative?))))

(% ι-Triangle/asa (flags immutable)
   (α angle?)
   (b  (and/c real? (not/c negative?)))
   (γ angle?))

(% ι-Triangle/saa (flags immutable)
   (a  (and/c real? (not/c negative?)))
   (β angle?)
   (γ angle?))

(% ι-Star-Polygon (flags immutable)
   (side        (and/c real? (not/c negative?)))
   (side-count  side-count?)
   (step-count  step-count?))

(% ι-Radial-Star (flags immutable)
   (point-count  (and/c integer? (>=/c 2)))
   (inner-radius (and/c real? (not/c negative?)))
   (outer-radius (and/c real? (not/c negative?))))

(% ι-Places (flags immutable)
   (x-place x-place?)
   (y-place y-place?))

(% ι-Posns (flags immutable)
   (posns (or/c (listof posn?)
                (λ (v) (and (procedure? v)
                            ((listof posn?) (v)))))))

;;=====================================================================================
;;
;;=====================================================================================

;; Note: we use the (aux _ @) form to evaluate any μ procedure versions of these variables.
(% μ-Ellipse (flags μ-props)   
   (area () (-> real?)
         (aux (width @) (height @))
         (* 1/2 pi width height))
   (eccentricity () (-> real?)
                 (aux (width @) (height @))
                 (define a (/ width 2))
                 (define b (/ height 2))
                 (define c (sqrt (abs (- (sqr a) (sqr b)))))
                 (/ c a))
   (foci () (-> (listof posn?))
         (aux (width @) (height @))
         (define a (/ width 2))
         (define b (/ height 2))
         (define c (sqrt (abs (- (sqr a) (sqr b)))))
         (if (zero? c)
             (list (make-posn 0 0))
             (list (make-posn (- c) 0)
                   (make-posn c 0)))))

(% μ-Circular (flags μ-props) (implements μ-Ellipse)
   ;; Required for μ-Ellipse inheritance
   (width () (-> real?)
          (aux (radius @))
          (* 2 radius))
   ;; Required for μ-Elliipse inheritance
   (height () (-> real?)
          (aux (radius @))
          (* 2 radius))
   (area () (-> real?)
         (aux radius)
         (* pi (sqr radius)))
   (circumference () (-> real?)
                  (aux radius)
                  (* 2 pi radius))
   (diameter () (-> real?)
             (aux radius)
             (* 2 radius)))

;; μ-Regular-Polygon (side, side-count)
(% μ-Regular-Polygon (flags μ-props) 
   (apothem () (-> real?)
            (aux side side-count)
            (* (/ side 2) (tan (degrees->radians (/ 180 side-count)))))   
   (area () (-> real?)
         (aux side side-count (apothem @))
         (* (/ side-count 2) side apothem))   
   (perimeter () (-> real?)
              (aux side side-count)
              (* side side-count)))

(% μ-Triangular (flags μ-props)
   (area () (-> any)
         (aux a b c)
         (@ herons-formula self a b c))
   (height-a () (-> real?)
             (aux a (area @))             
             (* 2 (/ area a)))
   (height-b () (-> real?)
             (aux b (area @))
             (* 2 (/ area b)))
   (height-c () (-> real?)
             (aux c (area @))             
             (* 2 (/ area c)))
   (perimeter () (-> real?)
              (aux a b c)
              (+ a b c)))

(% μ-Rectangular (flags μ-props)
   (side-AB () (-> real?) (aux width) width)
   (side-BC () (-> real?) (aux height) height)
   (side-CD () (-> real?) (aux width) width)
   (side-DA () (-> real?) (aux height) height)
   (diagonal-AC () (-> real?)
                (aux width height)
                (sqrt (+ (sqr width) (sqr height))))
   (diagonal-BD () (-> real?)
                (aux width height)
                (sqrt (+ (sqr width) (sqr height))))
   (perimeter () (-> real?)
              (aux width height)
              (+ (* 2 width) (* 2 height)))
   (area () (-> real?)
         (aux width height)
         (* width height))
   (circumradius () (-> real?)
                 (aux width height)
                 (* 1/2 (sqrt (+ (sqr width) (sqr height))))))

(% μ-Rhombus (flags μ-props)
   (α () (-> real?) (aux angle) (- 180 angle))
   (β () (-> real?) (aux angle) angle)
   (γ () (-> real?) (aux angle) (- 180 angle))
   (δ () (-> real?) (aux angle) angle)
   (AB () (-> real?) (aux side) side)
   (BC () (-> real?) (aux side) side)
   (CD () (-> real?) (aux side) side)
   (DA () (-> real?) (aux side) side)
   (AC () (-> real?)
       (aux side angle)
       (third (@ law-of-cosines Triangular
                 side #f #f angle side #f)))
   (BD () (-> real?)
       (aux side angle)
       (third (@ law-of-cosines Triangular
                 side #f #f (- 180 angle) side #f)))
   (inradius () (-> real?)
             (aux side angle (AC @) (BD @))             
             (/ (* AC BD)
                (* 2 (sqrt (+ (sqr AC) (sqr BD))))))
   (perimeter () (-> real?) (aux side) (* 4 side))
   (area () (-> real?)
         (aux side angle (AC @) (BD @))         
         (* 1/2 AC BD)))

;; μ-Square (side, side-count, angle, height, width)
(% μ-Square (flags μ-props)
   (implements μ-Regular-Polygon μ-Rectangular μ-Rhombus))

;;=====================================================================================
;; Basic Images
;;=====================================================================================

(default-kind! Characteristics Nothing)

(% Image (flags immutable no-assert)
   (construct () (-> any)
              (inherited)                          
              (@ characteristics! self))
   (show (#:flag (flag #f)
         #:sign (sign #f)
         #:precision (precision '(= 6))
         #:notation (notation 'positional)
         #:format-exponent (format-exponent #f))       
        (->* ()
             (#:flag (or/c #f '+kinds +mods '+all 'chs)
              #:sign (or/c #f '+ '++ 'parens
                           (let ([ind (or/c string? (list/c string? string?))])
                             (list/c ind ind ind)))
              #:precision (or/c exact-nonnegative-integer?
                                (list/c '= exact-nonnegative-integer?))
              #:notation (or/c 'positional 'exponential
                               (-> rational? (or/c 'positional 'exponential)))
              #:format-exponent (or/c #f string? (-> exact-integer? string?)))
             any)
        (inherited #:flag flag
                      #:sign sign
                      #:precision precision
                      #:notation notation
                      #:format-exponent format-exponent)        
         (with-handlers ([exn:fail? (λ (e) (printf "~%~a ~a" #\u2022 (exn-message e)))])
           (define img (@ render self))
           (printf "~%~a Rendering:~%~%~a" #\u2022 img)))   
   (render () (-> any)
           (if (@ template-object? self)
               (error (format "~a is a template and cannot be rendered." self))
               (@ 2htdp-image-render self))))

;; A mix-in for rendering the contents of an object.
(% Container  (flags immutable no-assert) (implements ι-Container)
   (validate-images () (-> any)
                    (define cs (@ contents self))
                    (define lower (@ container-lower self #:when-undefined 2))
                    (define upper (@ container-upper self #:when-undefined #f))
                    (if (and (cond
                               [(false? upper)
                                (<= lower (length cs))]
                               [else (<= lower (length cs) upper)])
                             (andmap (λ (v)
                                       (and (object? v) (@ of-kind? v Image)))
                                     cs))
                        cs
                        #f))
   (render-contents () (-> (or/c #f (listof image?)))
                    (define cs (@ validate-images self))
                    (if cs
                        (map (λ (v) (@ render v)) cs)
                        #f))
   (2htdp-image-render ()(-> any)
                       (define images (@ render-contents self))
                       (cond
                         [(false? images) (@ render Empty-Image)]
                         [else (@ render-composition self images)])))

(default-kind! Image)

(% Empty-Image (flags immutable no-assert)
   (2htdp-image-render ()(-> image?) empty-image))

(% Empty-Scene (flags immutable no-assert) (implements ι-Rectangular) 
   (pen-or-color white)
   (2htdp-image-render ()(-> image?)
                       (empty-scene (@ width self)
                                    (@ height self)
                                    (@ pen-or-color self))))

(module+ test
  (with-objects ()
    (test-case "Empty-Image tests"
               (check-equal? (@ render (τ Empty-Image)) empty-image))
    (test-case "Empty-Scene tests"
               (check-equal? (@ render (τ Empty-Scene
                                          width: 800
                                          height: 600))
                             (empty-scene 800 600)))))

;; Ellipse (width, height)
(% Ellipse (flags immutable no-assert)
   (implements ι-Rectangular μ-Ellipse)  
   (2htdp-image-render ()(-> image?)
                       (ellipse (@ width self)
                                (@ height self)
                                (@ outline-mode self #:when-undefined default-outline-mode)
                                (@ pen-or-color self #:when-undefined default-pen-or-color))))
(module+ test
  (with-objects ()
    (test-case "Ellipse tests"
               (check-equal? (@ render (τ Ellipse
                                          width: 40
                                          height: 20))
                             (ellipse 40 20 solid gold)))))

;; Circle (radius)
(% Circle (kinds Ellipse) (flags immutable no-assert)
   (implements ι-Circular μ-Circular ~ι-Rectangular ~μ-Ellipse)
   (2htdp-image-render ()(-> image?)
                       (circle (@ radius self)
                               (@ outline-mode self #:when-undefined default-outline-mode)
                               (@ pen-or-color self #:when-undefined
                                  default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "Circle tests"
               (check-equal? (@ render (τ Circle radius: 1))
                             (circle 1 solid gold)))))

;; Line (x1, y1)
;; Render draws line with coordinates (0,0) and (x1,y1).
(% Line (flags immutable no-assert) (implements ι-Line)
   (2htdp-image-render ()(-> image?)
                       (line (@ x1 self) (@ y1 self)
                             (@ pen-or-color self #:when-undefined default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "Line tests"
               (% p0 (kinds Line)
                  (x1 40)
                  (y1 40))
               (check-equal? (@ render p0)
                             (line 40 40 gold)))))

(% Add-Line (kinds Container Line)
   (flags immutable no-assert) (implements ι-Linear)
   (container-lower 1)
   (container-upper 1)
   (render-composition (images) (-> (listof image?) image?)
                       (add-line (car images)
                                 (@ x1 self)
                                 (@ y1 self)
                                 (@ x2 self)
                                 (@ y2 self)
                                 (@ pen-or-color self))))

(% Scene+Line (kinds Add-Line) (flags immutable no-assert)
   (render-composition (images) (-> (listof image?) image?)
                       (scene+line (car images)
                                   (@ x1 self)
                                   (@ y1 self)
                                   (@ x2 self)
                                   (@ y2 self)
                                   (@ pen-or-color self))))

(module+ test
  (with-objects ()
    (test-case "Add-Line tests"
               (% p0 (kinds Add-Line)
                  (x1 40)
                  (y1 40)
                  (x2 0)
                  (y2 0)
                  (pen-or-color black))
               (% (kinds Circle) (parent p0)
                  (radius 1))
               (check-equal? (@ render p0)
                             (add-line (circle 1 solid gold)
                                       40 40 0 0 black)))
    (test-case "Scene+Line tests"
               (% p1 (kinds Scene+Line)
                  (x1 40)
                  (y1 40)
                  (x2 0)
                  (y2 0)
                  (pen-or-color black))
               (% (kinds Empty-Scene) (parent p1) (width 100) (height 100))
               (check-equal? (@ render p1)
                             (scene+line (empty-scene 100 100)
                                         40 40 0 0 black)))))

(% Add-Curve (kinds Add-Line) (flags immutable no-assert)
   (implements ι-Linear/pulls)
   (compose-fn add-curve)
   (render-composition (images) (-> (listof image?) image?)
                       ((? compose-fn self) (car images)
                                            (@ x1 self)
                                            (@ y1 self)
                                            (@ angle1 self)
                                            (@ pull1 self)
                                            (@ x2 self)
                                            (@ y2 self)
                                            (@ angle2 self)
                                            (@ pull2 self)
                                            (@ pen-or-color self))))

(% Scene+Curve (kinds Add-Curve) (flags immutable no-assert)
   (compose-fn scene+curve))

(module+ test
  (with-objects ()
    (test-case "Add-Curve tests"
               (% p0 (kinds Add-Curve)
                  (x1 40)
                  (y1 40)
                  (x2 0)
                  (y2 0)
                  (angle1 0)
                  (angle2 0)
                  (pull1 1/3)
                  (pull2 1/3)
                  (pen-or-color black))
               (% (kinds Circle) (parent p0)
                  (radius 1))
               (check-equal? (@ render p0)
                             (add-curve (circle 1 solid gold)
                                        40 40 0 1/3 0 0 0 1/3 black)))
    (test-case "Scene+Curve tests"
               (% p1 (kinds Scene+Curve)
                  (x1 40)
                  (y1 40)
                  (x2 0)
                  (y2 0)
                  (angle1 0)
                  (angle2 0)
                  (pull1 1/3)
                  (pull2 1/3)
                  (pen-or-color black))
               (% (kinds Empty-Scene) (parent p1)
                  (width 100) (height 100))
               (check-equal? (@ render p1)
                             (scene+curve (empty-scene 100 100)
                                          40 40 0 1/3 0 0 0 1/3 black)))))


(% Add-Solid-Curve (kinds Add-Line) (flags immutable no-assert)
   (2htdp-image-render ()(-> image?)
                       (define images (@ render-contents self))
                       (if images
                           (add-solid-curve (car images)
                                            (@ x1 self)
                                            (@ y1 self)
                                            (@ angle1 self)
                                            (@ pull1 self)
                                            (@ x2 self)
                                            (@ y2 self)
                                            (@ angle2 self)
                                            (@ pull2 self)
                                            (@ pen-or-color self))
                           (@ render Empty-Image))))

(module+ test
  (with-objects ()
    (test-case "Add-Solid-Curve tests"
               (% p0 (kinds Add-Solid-Curve)
                  (x1 40)
                  (y1 40)
                  (x2 0)
                  (y2 0)
                  (angle1 0)
                  (angle2 0)
                  (pull1 1/3)
                  (pull2 1/3)
                  (pen-or-color black))
               (% (kinds Circle) (parent p0)
                  (radius 1))
               (check-equal? (@ render p0)
                             (add-solid-curve (circle 1 solid gold)
                                              40 40 0 1/3 0 0 0 1/3 black)))))

;; Text (text-string, font-size)
(% Text (flags immutable no-assert) (implements ι-Text)
   (2htdp-image-render ()(-> image?)
                       (text (@ text-string self)
                             (@ font-size self #:when-undefined default-font-size)
                             (@ 'color self #:when-undefined default-color))))

(module+ test
  (with-objects ()
    (test-case "Text tests"
               (check-equal? (@ render (τ Text
                                          text-string: "Hello, World!"
                                          font-size: 20
                                          color: gold))
                             (text "Hello, World!" 20 gold)))))

;; Text/font (text-string, font-size, face, family, style, weight, underline?)
(% Text/font (flags immutable no-assert) (implements ι-Text/font)
   (2htdp-image-render ()(-> image?)
                       ; string font color face family style weight underline?
                       (text/font (@ text-string self)
                                  (@ font-size self #:when-undefined default-font-size)
                                  (@ 'color self #:when-undefined default-color)
                                  (@ face self)
                                  (@ family self)
                                  (@ style self)
                                  (@ weight self)
                                  (@ underline? self))))

(module+ test
  (with-objects ()
    (test-case "Text/font tests"
               (% f1 (kinds Text/font)
                  (face       #f) 
                  (family     modern)
                  (style      italic)
                  (weight     normal)
                  (underline? #f)
                  (font-size 20)
                  (color     gold)
                  (text-string "Hello, World!"))
               (check-equal? (@ render f1)
                             (text/font "Hello, World!" 20 gold
                                        #f modern italic normal #f)))))

;;======================================================================================
;; Polygons
;;======================================================================================

(% Polygon (flags immutable no-assert)
   (implements ι-Polygon)
   (vertices ())
   (2htdp-image-render ()(-> image?)
                       (polygon (@ vertices self)
                                (@ outline-mode self #:when-undefined default-outline-mode)
                                (@ pen-or-color self #:when-undefined default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "polygon tests"
               (check-equal? (@ render (τ Polygon
                                          vertices: (list (make-posn 0 0)
                                                          (make-posn -10 20)
                                                          (make-posn 60 0))))
                             (polygon (list (make-posn 0 0)
                                            (make-posn -10 20)
                                            (make-posn 60 0))
                                      solid gold)))))

;; Regular-Polygon (side, side-count)
(% Regular-Polygon (kinds Polygon) (flags immutable no-assert)
   (implements μ-Regular-Polygon
               ι-Regular-Polygon/count
               ~ι-Polygon)   
   (2htdp-image-render ()(-> image?)
                       (aux side side-count)
                       (regular-polygon side side-count
                                        (@ outline-mode self
                                           #:when-undefined default-outline-mode)
                                        (@ pen-or-color self 
                                           #:when-undefined default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "regular-polygon tests"
               (check-equal? (@ render (τ Regular-Polygon
                                          side: 20
                                          side-count: 3))
                             (regular-polygon 20 3
                                              solid gold)))))

(% Pulled-Regular-Polygon (kinds Regular-Polygon)
   (flags immutable no-assert)
   (implements ι-Regular-Polygon/pulls)
   (2htdp-image-render ()(-> image?)
                       (aux side side-count pull angle)
                       (pulled-regular-polygon side side-count pull angle
                                               (@ outline-mode self
                                                  #:when-undefined default-outline-mode)
                                               (@ pen-or-color self
                                                  #:when-undefined default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "Pulled-Regular-Polygon tests"
               (check-equal? (@ render (τ Pulled-Regular-Polygon
                                          side: 60
                                          side-count: 4
                                          pull: 1/3
                                          angle: 30))
                             (pulled-regular-polygon 60 4 1/3 30
                                                     solid gold)))))

;; A mixin for all things triangular.
(% Triangular (kinds Polygon) (flags no-assert)
   (implements ~ι-Polygon μ-Triangular)
   (construct () (-> any)
              (aux a α b β c γ)
              (define ans (cond
                            [(or(and (real? a) (real? b) (real? γ))
                                (and (real? a) (real? c) (real? β))
                                (and (real? b) (real? c) (real? α))
                                (and (real? a) (real? b) (real? c)))
                             (@ law-of-cosines self (if (real? a)  a #f)
                                (if (real? α) α #f)
                                (if (real? b) b #f)
                                (if (real? β) β #f)
                                (if (real? c) c #f)
                                (if (real? γ) γ #f))]
                            [else
                             (@ law-of-sines self (if (real? a)  a #f)
                                (if (real? α) α #f)
                                (if (real? b) b #f)
                                (if (real? β) β #f)
                                (if (real? c) c #f)
                                (if (real? γ) γ #f))]))
              (! 'a self (first ans))
              (! 'α self (second ans))
              (! 'b self (third ans))
              (! 'β self (fourth ans))
              (! 'c self (fifth ans))
              (! 'γ self (sixth ans))
              (inherited))
   ;; Returns the area of a triangle, given its sides.
   (herons-formula (a b c) (-> real? real? real? real?)
                   (define s (* 1/2 (+ a b c)))
                   (sqrt (* s (- s a) (- s b) (- s c))))
   ;; The law of sines can be used to compute the remaining sides of a triangle
   ;; when two angles and a side are known.  
   (law-of-sines (a α b β c γ) (-> any/c any/c any/c any/c any/c any/c any)                 
                 (define s (vector a b c))
                 (define θ (vector α β γ))
                 (when (= (vector-length (vector-filter real? θ)) 2)
                   (for ([i (range 3)]
                         [v θ] #:when (false? v))
                     (vector-set! θ i (- 180 (for/sum ([v θ] #:when (real? v)) v)))))
                 (define r
                   (let ([a (vector-ref s 0)]
                         [α (vector-ref θ 0)]
                         [b (vector-ref s 1)]
                         [β (vector-ref θ 1)]
                         [c (vector-ref s 2)]
                         [γ (vector-ref θ 2)])
                     (cond
                       [(and a α) (/ a (sin (degrees->radians α)))]
                       [(and b β) (/ b (sin (degrees->radians β)))]
                       [(and c γ) (/ c (sin (degrees->radians γ)))]
                       [else #f])))
                 (cond
                   [(false? r) (void)]
                   [else
                    (define (solve-it)
                      (for ([i (range 3)]
                            [n s]
                            [v θ])
                        (cond
                          ;; Solving for angle
                          [(and (real? n) (false? v))
                           (vector-set! θ i (radians->degrees (asin (/ n r))))]
                          ;; Solving for side
                          [(and (real? v) (false? n))
                           (vector-set! s i (* r (sin (degrees->radians v))))])))
                    (solve-it)
                    (when (= (vector-length (vector-filter real? θ)) 2)
                      (for ([i (range 3)]
                            [v θ] #:when (false? v))
                        (vector-set! θ i (- 180 (for/sum ([v θ] #:when (real? v)) v))))
                      (solve-it))])
                 (list (if (real? (vector-ref s 0))
                           (vector-ref s 0)
                           (vector-ref s 0))
                       (if (real? (vector-ref θ 0))
                           (vector-ref θ 0)
                           (vector-ref θ 0))
                       (if (real? (vector-ref s 1))
                           (vector-ref s 1)
                           (vector-ref s 1))
                       (if (real? (vector-ref θ 1))
                           (vector-ref θ 1)
                           (vector-ref θ 1))
                       (if (real? (vector-ref s 2))
                           (vector-ref s 2)
                           (vector-ref s 2))
                       (if (real? (vector-ref θ 2))
                           (vector-ref θ 2)
                           (vector-ref θ 2))))
   ;; The law of cosines is useful for computing the third side of a triangle
   ;; when two sides and their enclosed angle are known, and in computing the
   ;; angles of a triangle if all three sides are known.  
   (law-of-cosines (a α b β c γ) (-> any/c any/c any/c any/c any/c any/c any)                   
                   (define s (vector a b c))
                   (define θ (vector α β γ))
                   (cond
                     [(and b c α) ;=> a
                      (define a (sqrt (+ (* b b)
                                         (* c c)
                                         (* -2 b c (cos (degrees->radians α))))))
                      (vector-set! s 0 a)     
                      (when (false? β)
                        (vector-set! θ 1 (radians->degrees
                                          (acos (/ (- (+ (* a a) (* c c)) (* b b))
                                                   (* 2 a c))))))
                      (when (false? γ)
                        (vector-set! θ 2 (radians->degrees
                                          (acos (/ (- (+ (* a a) (* b b)) (* c c))
                                                   (* 2 a b))))))]
                     [(and a c β) ;=> b
                      (define b (sqrt (+ (* a a)
                                         (* c c)
                                         (* -2 a c (cos (degrees->radians β))))))
                      (vector-set! s 1 b)
                      (when (false? α)
                        (vector-set! θ 0 (radians->degrees
                                          (acos (/ (- (+ (* b b) (* c c)) (* a a))
                                                   (* 2 b c))))))
                      (when (false? γ)
                        (vector-set! θ 2 (radians->degrees
                                          (acos (/ (- (+ (* a a) (* b b)) (* c c))
                                                   (* 2 a b))))))]
                     [(and a b γ) ;=> c
                      (define c (sqrt (+ (* a a)
                                         (* b b)
                                         (* -2 a b (cos (degrees->radians γ))))))
                      (vector-set! s 2 c)
                      (when (false? α)
                        (vector-set! θ 0 (radians->degrees
                                          (acos (/ (- (+ (* b b) (* c c)) (* a a))
                                                   (* 2 b c))))))
                      (when (false? β)
                        (vector-set! θ 1 (radians->degrees
                                          (acos (/ (- (+ (* a a) (* c c)) (* b b))
                                                   (* 2 a c))))))]
                     [(and a b c) ;=> α, β, γ
                      (when (false? α)
                        (vector-set! θ 0 (radians->degrees
                                          (acos (/ (- (+ (* b b) (* c c)) (* a a))
                                                   (* 2 b c))))))
                      (when (false? β)
                        (vector-set! θ 1 (radians->degrees
                                          (acos (/ (- (+ (* a a) (* c c)) (* b b))
                                                   (* 2 a c))))))
                      (when (false? γ)
                        (vector-set! θ 2 (radians->degrees
                                          (acos (/ (- (+ (* a a) (* b b)) (* c c))
                                                   (* 2 a b))))))])
                   (list (if (real? (vector-ref s 0))
                             (vector-ref s 0)
                             (vector-ref s 0))
                         (if (real? (vector-ref θ 0))
                             (vector-ref θ 0)
                             (vector-ref θ 0))
                         (if (real? (vector-ref s 1))
                             (vector-ref s 1)
                             (vector-ref s 1))
                         (if (real? (vector-ref θ 1))
                             (vector-ref θ 1)
                             (vector-ref θ 1))
                         (if (real? (vector-ref s 2))
                             (vector-ref s 2)
                             (vector-ref s 2))
                         (if (real? (vector-ref θ 2))
                             (vector-ref θ 2)
                             (vector-ref θ 2)))))

;; Triangle/sss (a, b, c)
;; Render draws α top left, β top right, γ bottom.
(% Triangle/sss (kinds Triangular) (flags immutable no-assert)
   (implements ι-Triangle/sss)  
   (2htdp-image-render ()(-> image?)
                       (aux a b c)
                       (triangle/sss a b c
                                     (@ outline-mode self
                                        #:when-undefined default-outline-mode)
                                     (@ pen-or-color self
                                        #:when-undefined default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "triangle/sss tests"
               (check-equal? (@ render (τ Triangle/sss
                                          a: 40
                                          b: 60
                                          c: 80))
                             (triangle/sss 40 60 80
                                           solid gold)))))

;; Triangle (side)
;; Render draws α left, β top, γ right.
(% Triangle (kinds Triangle/sss Regular-Polygon) (flags immutable no-assert)
   (implements ι-Regular-Polygon/side ~ι-Regular-Polygon/count ~ι-Triangle/sss μ-Triangular)
   (construct () (-> any)
              (aux side)
              (! side-count self 3)
              (! a self side)
              (! b self side)
              (! c self side)
              (inherited))
   (2htdp-image-render ()(-> image?)
                       (aux side)
                       (triangle side
                                 (@ outline-mode self
                                    #:when-undefined default-outline-mode)
                                 (@ pen-or-color self
                                    #:when-undefined default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "triangle tests"
               (check-equal? (@ render (τ Triangle side: 40))
                             (triangle 40 solid gold)))))

;; Triangle/ass (α, b, c)
;; Render draws α top right, β top left, γ bottom.
(% Triangle/ass (kinds Triangular) (flags immutable no-assert)
   (implements ι-Triangle/ass μ-Triangular)
   (2htdp-image-render ()(-> any)
                       (aux α b c)
                       (triangle/ass α b c
                                     (@ outline-mode self
                                        #:when-undefined default-outline-mode)
                                     (@ pen-or-color self
                                        #:when-undefined default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "Triangle/ass tests"
               (check-equal? (@ render (τ Triangle/ass α: 10 b: 60 c: 100))
                             (triangle/ass 10 60 100 solid gold)))))

;; Triangle/sas (a, β, c)
;; Render draws α top left, β top right, γ bottom.
(% Triangle/sas (kinds Triangular) (flags immutable no-assert)
   (implements ι-Triangle/sas)   
   (2htdp-image-render ()(-> image?)
                       (aux a β c)
                       (triangle/sas a β c
                                     (@ outline-mode self
                                        #:when-undefined default-outline-mode)
                                     (@ pen-or-color self
                                        #:when-undefined default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "Triangle/sas tests"
               (check-equal? (@ render (τ Triangle/sas a: 60 β: 10 c: 100))
                             (triangle/sas 60 10 100 solid gold)))))

;; Isosceles-Triangle (side, angle)
;; Render draws α left, β top (< 180) bottom (> 180), γ right.
(% Isosceles-Triangle (kinds Triangle/sas) (flags immutable no-assert)
   (implements ι-Isosceles-Triangle ~ι-Triangle/sas)
   (construct () (-> any)
              (aux side angle)
              (! a self side)
              (! b self side)
              (! γ self angle)
              (inherited))   
   (2htdp-image-render ()(-> image?)
                       (aux side angle)
                       (isosceles-triangle side angle
                                           (@ outline-mode self
                                              #:when-undefined default-outline-mode)
                                           (@ pen-or-color self
                                              #:when-undefined default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "Isosceles-Triangle tests"
               (check-equal? (@ render (τ Isosceles-Triangle side: 60 angle: 30))
                             (isosceles-triangle 60 30 solid gold)))))

;; Right-Triangle (a, b)
;; Render draws α top, β bottom right, γ bottom left.
(% Right-Triangle (kinds Triangle/sas) (flags immutable no-assert)
   (implements ι-Right-Triangle ~ι-Triangle/sas)
   (construct () (-> any)
              (! γ self 90)
              (inherited))   
   (2htdp-image-render ()(-> image?)
                       (aux a b)
                       (right-triangle a b
                                       (@ outline-mode self
                                          #:when-undefined default-outline-mode)
                                       (@ pen-or-color self
                                          #:when-undefined default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "Right-Triangle tests"
               (check-equal? (@ render (τ Right-Triangle a: 36 b: 48))
                             (right-triangle 36 48 solid gold)))))

;; Triangle/ssa (a, b, γ)
;;Render draws α top left, β top right, γ bottom.
(% Triangle/ssa (kinds Triangular) (flags immutable no-assert)
   (implements ι-Triangle/ssa)   
   (2htdp-image-render ()(-> any)
                       (aux a b γ)
                       (triangle/ssa a b γ
                                     (@ outline-mode self
                                        #:when-undefined default-outline-mode)
                                     (@ pen-or-color self
                                        #:when-undefined default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "Triangle/ssa tests"
               (check-equal? (@ render (τ Triangle/ssa a: 60 b: 100 γ: 10))
                             (triangle/ssa 60 100 10 solid gold)))))

;; Triangle/aas (α, β,-c)
;; Render draws α top left, β top right, γ bottom.
(% Triangle/aas (kinds Triangular) (flags immutable no-assert)
   (implements ι-Triangle/aas)
   (2htdp-image-render ()(-> image?)
                       (aux α β c)
                       (triangle/aas α β c
                                     (@ outline-mode self
                                        #:when-undefined default-outline-mode)
                                     (@ pen-or-color self
                                        #:when-undefined default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "Triangle/aas tests"
               (check-equal? (@ render (τ Triangle/aas α: 10 β: 40 c: 200))
                             (triangle/aas 10 40 200 solid gold)))))

;; Triangle/asa (α, b, γ)
;; Render draws α top right, β top left, γ bottom.
(% Triangle/asa (kinds Triangular) (flags immutable no-assert)
   (implements ι-Triangle/asa)
   (2htdp-image-render ()(-> image?)
                       (aux α b γ)
                       (triangle/asa  α b γ
                                      (@ outline-mode self
                                         #:when-undefined default-outline-mode)
                                      (@ pen-or-color self
                                         #:when-undefined default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "Triangle/asa tests"
               (check-equal? (@ render (τ Triangle/asa α: 10 b: 200 γ: 40))
                             (triangle/asa 10 200 40 solid gold)))))

;; Triangle/saa (a, β, γ)
;; Render draws α top right, β top left, γ bottom.
(% Triangle/saa (kinds Triangular) (flags immutable no-assert)
   (implements ι-Triangle/saa)
   (2htdp-image-render ()(-> image?)
                       (aux a β γ)
                       (triangle/saa a β γ
                                     (@ outline-mode self
                                        #:when-undefined default-outline-mode)
                                     (@ pen-or-color self
                                        #:when-undefined default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "Triangle/saa tests"
               (check-equal? (@ render (τ Triangle/saa a: 200 β: 10 γ: 40))
                             (triangle/saa 200 10 40 solid gold)))))

;; Rectangle: (width, height)
(% Rectangle (kinds Polygon) (flags immutable no-assert)
   (implements ι-Rectangular ~ι-Polygon μ-Rectangular)   
   (2htdp-image-render ()(-> image?)
                       (aux width height)
                       (rectangle width height
                                  (@ outline-mode self
                                     #:when-undefined default-outline-mode)
                                  (@ pen-or-color self
                                     #:when-undefined default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "Rectangle tests"
               (check-equal? (@ render (τ Rectangle width: 20 height: 40))
                             (rectangle 20 40 solid gold)))))

;; Rhombus (side, angle)
(% Rhombus (kinds Polygon) (flags immutable no-assert)
   (implements μ-Rhombus ι-Regular-Polygon/side/angle ~ι-Polygon)  
   (2htdp-image-render ()(-> image?)
                       (aux side angle)
                       (rhombus side angle
                                (@ outline-mode self
                                   #:when-undefined default-outline-mode)
                                (@ pen-or-color self
                                   #:when-undefined default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "Rhombus tests"
               (check-equal? (@ render (τ Rhombus side: 80 angle: 150))
                             (rhombus 80 150 solid gold)))))

;; Square: (side)
(% Square (kinds Rectangle Rhombus Regular-Polygon)
   (flags immutable no-assert)
   (implements μ-Square ι-Regular-Polygon/side 
               ~ι-Regular-Polygon/count ~ι-Rectangular)
   (construct any (->* () #:rest list? any)
              (aux side)
              (unless (@ characteristics-template? self)
                (! side-count self 4)
                (! 'angle self 90)
                (! width self side)
                (! height self side))
              (inherited))  
   (2htdp-image-render ()(-> image?)
                       (aux side)
                       (square side
                               (@ outline-mode self
                                  #:when-undefined default-outline-mode)
                               (@ pen-or-color self
                                  #:when-undefined default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "Square tests"
               (check-equal? (@ render (τ Square side: 40))
                             (square 40 solid gold)))))

;; Star (side)
(% Star (flags immutable no-assert)
   (implements ι-Regular-Polygon/side)
   (2htdp-image-render ()(-> image?)
                       (aux side)
                       (star side
                             (@ outline-mode self
                                #:when-undefined default-outline-mode)
                             (@ pen-or-color self
                                #:when-undefined default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "Star tests"
               (check-equal? (@ render (τ Star side: 40))
                             (star 40 solid gold)))))


;; Star-Polygon (side, side-count, step-count)
(% Star-Polygon (flags immutable no-assert)
   (implements ι-Star-Polygon)
   (2htdp-image-render () (-> image?)
                       (aux side side-count step-count)
                       (star-polygon side side-count step-count
                                     (@ outline-mode self
                                        #:when-undefined default-outline-mode)
                                     (@ pen-or-color self
                                        #:when-undefined default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "Star-Polygon tests"
               (check-equal? (@ render (τ Star-Polygon side: 40 side-count: 5 step-count: 2))
                             (star-polygon 40 5 2 solid gold)))))

;; Radial-Star (point-count, inner-radius, outer-radius)
(% Radial-Star (flags immutable no-assert)
   (implements ι-Radial-Star)
   (2htdp-image-render ()(-> image?)
                       (aux point-count inner-radius outer-radius)
                       (radial-star point-count inner-radius outer-radius
                                    (@ outline-mode self
                                       #:when-undefined default-outline-mode)
                                    (@ pen-or-color self 
                                       #:when-undefined default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "Radial-Star-Polygon tests"
               (check-equal? (@ render (τ Radial-Star point-count: 8 inner-radius: 8
                                          outer-radius: 64))
                             (radial-star 8 8 64 solid gold)))))


(% Add-Polygon (kinds Container Polygon) (flags immutable no-assert)
  (container-lower 1)
  (container-upper 1)
  (render-composition (images) (-> (listof image?) image?)
                      (add-polygon (car images)
                                   (@ vertices self)
                                   (@ outline-mode self
                                      #:when-undefined default-outline-mode)
                                   (@ pen-or-color self 
                                      #:when-undefined default-pen-or-color))))

(module+ test
  (with-objects ()
    (test-case "add-polygon tests"
               (% foo (kinds Add-Polygon)
                 (vertices (list (make-posn 109 160)
                                  (make-posn 26 148)
                                  (make-posn 46 36)
                                  (make-posn 93 44)
                                  (make-posn 89 68)
                                  (make-posn 122 72)))
                 (outline-mode "outline")
                 (pen-or-color "dark blue"))
               (τ Square
                 parent: foo
                 side: 180
                 pen-or-color: yellow)
               (check-equal? (@ render foo)
                             (add-polygon (square 180 "solid" "yellow")
                                          (list (make-posn 109 160)
                                                (make-posn 26 148)
                                                (make-posn 46 36)
                                                (make-posn 93 44)
                                                (make-posn 89 68)
                                                (make-posn 122 72))
                                          "outline" "dark blue")))))

(% Scene+Polygon (kinds Add-Polygon) (flags immutable no-assert)
  (2htdp-image-render ()(-> any)
                      (define images (@ render-contents self))
                      (if images
                          (scene+polygon (car images)
                                         (@ vertices self)
                                         (@ outline-mode self
                                            #:when-undefined default-outline-mode)
                                         (@ pen-or-color self
                                            #:when-undefined default-pen-or-color))
                          (@ render Empty-Image))))

(module+ test
  (with-objects ()
    (test-case "scene+polygon tests"
               (% foo (kinds Add-Polygon)
                 (vertices (list (make-posn 109 160)
                                  (make-posn 26 148)
                                  (make-posn 46 36)
                                  (make-posn 93 44)
                                  (make-posn 89 68)
                                  (make-posn 122 72)))
                 (outline-mode "outline")
                 (pen-or-color "dark blue"))
               (τ Square
                 parent: foo
                 side: 180
                 pen-or-color: yellow)
               (check-equal? (@ render foo)
                             (scene+polygon (square 180 "solid" "yellow")
                                            (list (make-posn 109 160)
                                                  (make-posn 26 148)
                                                  (make-posn 46 36)
                                                  (make-posn 93 44)
                                                  (make-posn 89 68)
                                                  (make-posn 122 72))
                                            "outline" "dark blue")))))

;;======================================================================================
;; Overlaying Images
;;======================================================================================


(% Overlay (kinds Container Image) (flags immutable no-assert)
  (compose-fn overlay)
  (container-lower 2)
  (container-upper #f)
  (render-composition (images) (-> (listof image?) image?)
                      (apply (? compose-fn self) images)))

(% Underlay (kinds Overlay) (flags immutable no-assert)
  (compose-fn underlay))

(% Place-Image (kinds Container Empty-Scene) (flags immutable no-assert)
  (implements ι-2D-Point ~ι-Rectangular)
  (container-lower 2)
  (container-upper 2)
  (compose-fn place-image)
  (render-composition (images) (-> (listof image?) image?)
                      ((? compose-fn self) (first images)
                                           (@ x self)
                                           (@ y self)
                                           (second images))))

(% Place-Images (kinds Place-Image) (flags immutable no-assert)
  (implements ι-Posns ~ι-2D-Point)
  (container-upper () (-> real?)
                   (length (@ contents self #:when-undefined '())))
  (compose-fn place-images)
  (render-composition (images) (-> (listof image?) image?)
                      ((? compose-fn self) (take images (sub1 (length images)))
                                           (@ posns self)
                                           (last images))))

(module+ test
  (with-objects ()
    (test-case "overlay tests"
               (% p0 (kinds Overlay))          
               (τ Square parent: p0
                 side: 1
                 pen-or-color: blue)
               (τ Circle parent: p0
                 radius: 1)
               (check-equal? (@ render p0)
                             (overlay (square 1 solid blue)
                                      (circle 1 solid gold))))
    (test-case "underlay tests"
               (% p1 (kinds Underlay))
               (τ Circle parent: p1
                 radius: 1)
               (τ Square parent: p1
                 side: 1
                 pen-or-color: blue)
               (check-equal? (@ render p1)
                             (underlay (circle 1 solid gold)
                                       (square 1 solid blue))))
    (test-case "place-image tests"
               (% p2 (kinds Place-Image)                 
                 (x 0)
                 (y 0))               
               (τ Circle parent: p2
                 radius: 1
                 pen-or-color: red)
               (τ Empty-Scene parent: p2
                 width: 800
                 height: 600)
               (check-equal? (@ render p2)
                             (place-image (circle 1 solid red)
                                          0 0
                                          (empty-scene 800 600))))
    (test-case "place-images tests"
               (% p3 (kinds Place-Images)
                 (posns () (-> (listof posn?))
                        (define cs (@ contents self))
                        (if (empty? cs)
                            '()
                            (for/list ([n (rest cs)])
                              (make-posn 0 0)))))                              
               (τ Square parent: p3
                 side: 1
                 pen-or-color: blue)
               (τ Circle parent: p3
                 radius: 1
                 pen-or-color: red)
               (τ Empty-Scene parent: p3
                 width: 100 height: 100)
               (check-equal? (@ render p3)
                             (place-images (list
                                            (square 1 solid blue)
                                            (circle 1 solid red))
                                           (list (make-posn 0 0)
                                                 (make-posn 0 0))
                                           (empty-scene 100 100 white))))))

(% Overlay/align (kinds Overlay) (flags immutable no-assert)
  (implements ι-Places)
  (compose-fn overlay/align)
  (render-composition (images) (-> (listof image?) image?)
                      (apply (? compose-fn self)
                             (@ x-place self)
                             (@ y-place self)
                             images)))

(% Underlay/align (kinds Overlay/align) (flags immutable no-assert)
  (compose-fn underlay/align))

(% Place-Image/align (kinds Place-Image) (flags immutable no-assert)
  (implements ι-Places)
  (compose-fn place-image/align)
  (render-composition (images) (-> (listof image?) image?)
                      ((? compose-fn self) (first images)
                                           (@ x self)
                                           (@ y self)
                                           (@ x-place self)
                                           (@ y-place self)
                                           (second images))))

(% Place-Images/align (kinds Place-Images) (flags immutable no-assert)
  (implements ι-Places ι-Posns ~ι-2D-Point)  
  (compose-fn place-images/align)
  (render-composition (images) (-> (listof image?) image?)
                      ((? compose-fn self) (take images (sub1 (length images)))
                                           (@ posns self)
                                           (@ x-place self)
                                           (@ y-place self)
                                           (last images))))

(module+ test
  (with-objects ()
    (test-case "overlay/align tests"
               (% p0 (kinds Overlay/align)
                 (x-place center)
                 (y-place center))               
               (τ Square parent: p0
                 side: 1
                 pen-or-color: blue)
               (τ Circle parent: p0
                 radius: 1)
               (check-equal? (@ render p0)
                             (overlay/align "middle" "center"
                                            (square 1 solid blue)
                                            (circle 1 solid gold))))
    (test-case "underlay/align tests"
               (% p1 (kinds Underlay/align)
                 (x-place center)
                 (y-place center))               
               (τ Circle parent: p1
                 radius: 1)
               (τ Square parent: p1
                 side: 1
                 pen-or-color: blue)
               (check-equal? (@ render p1)
                             (underlay/align "center" "center"
                                             (circle 1 solid gold)
                                             (square 1 solid blue))))
    (test-case "place-image/align tests"
               (% p2 (kinds Place-Image/align)
                 (x 0)
                 (y 0)
                 (x-place center)
                 (y-place center)
                 (width 800)
                 (height 600))               
               (τ Circle parent: p2
                 radius: 1
                 pen-or-color: red)
               (τ Empty-Scene parent: p2
                 width: 100 height: 100)
               (check-equal? (@ render p2)
                             (place-image/align (circle 1 solid red)
                                                0 0
                                                "center" "center"
                                                (empty-scene 100 100))))
    (test-case "place-images/align tests"
               (% p3 (kinds Place-Images/align)
                 (posns () (-> (listof posn?))
                        (define cs (@ contents self))
                        (if (empty? cs)
                            '()
                            (for/list ([n (rest cs)])
                              (make-posn 0 0))))
                 (x-place center)
                 (y-place center))                              
               (τ  Square parent: p3
                 side: 1
                 pen-or-color: blue)
               (τ Circle parent: p3
                 radius: 1
                 pen-or-color: red)
               (τ Empty-Scene parent: p3
                 width: 100 height: 100)
               (check-equal? (@ render p3)
                             (place-images/align (list
                                                  (square 1 solid blue)
                                                  (circle 1 solid red))
                                                 (list (make-posn 0 0)
                                                       (make-posn 0 0))
                                                 "center" "center"
                                                 (empty-scene 100 100 white))))))

(% Overlay/offset (kinds Overlay) (flags immutable no-assert)
  (implements ι-Offsets)
  (compose-fn overlay/offset)
  (container-upper 2)
  (render-composition (images) (-> (listof image?) image?)
                      ((? compose-fn self)
                       (first images)
                       (@ x-offset self)
                       (@ y-offset self)
                       (second images))))

(% Underlay/offset (kinds Overlay/offset) (flags immutable no-assert)
  (compose-fn underlay/offset))

(module+ test
  (with-objects ()
    (test-case "overlay/offset tests"
               (% p0 (kinds Overlay/offset)
                 (x-offset 0)
                 (y-offset 0))               
               (τ Square parent: p0
                 side: 1
                 pen-or-color: blue)
               (τ Circle parent: p0
                 radius: 1)
               (check-equal? (@ render p0)
                             (overlay/offset (square 1 solid blue)
                                             0 0
                                             (circle 1 solid gold))))
    (test-case "underlay/offset tests"
               (% p1 (kinds Underlay/offset)
                 (x-offset 0)
                 (y-offset 0))               
               (τ Circle parent: p1
                 radius: 1)
               (τ Square parent: p1
                 side: 1
                 pen-or-color: blue)
               (check-equal? (@ render p1)
                             (underlay/offset (circle 1 solid gold)
                                              0 0
                                              (square 1 solid blue))))))

(% Overlay/align/offset (kinds Overlay/align Overlay/offset)
  (flags immutable no-assert)
  (compose-fn overlay/align/offset)
  (render-composition (images) (-> (listof image?) image?)
                      ((? compose-fn self)
                       (@ x-place self)
                       (@ y-place self)
                       (first images)
                       (@ x-offset self)
                       (@ y-offset self)
                       (second images))))


(% Underlay/align/offset (kinds Overlay/align/offset)
  (flags immutable no-assert)
  (compose-fn underlay/align/offset))

(module+ test
  (with-objects ()
    (test-case "overlay/align/offset tests"
               (% p0 (kinds Overlay/align/offset)
                 (x-place center)
                 (y-place center)
                 (x-offset 0)
                 (y-offset 0))               
               (τ Square parent: p0
                 side: 1
                 pen-or-color: blue)
               (τ Circle parent: p0
                 radius: 1)
               (check-equal? (@ render p0)
                             (overlay/align/offset "center" "center"
                                                   (square 1 solid blue)
                                                   0 0
                                                   (circle 1 solid gold))))
    (test-case "underlay/align/offset tests"
               (% p1 (kinds Underlay/align/offset)
                 (x-place center)
                 (y-place center)
                 (x-offset 0)
                 (y-offset 0))               
               (τ Circle parent: p1
                 radius: 1)
               (τ Square parent: p1
                 side: 1
                 pen-or-color: blue)
               (check-equal? (@ render p1)
                             (underlay/align/offset "middle" "center"
                                                    (circle 1 solid gold)
                                                    0 0
                                                    (square 1 solid blue))))))

(% Overlay/xy (kinds Overlay/align Overlay/offset)
  (flags immutable no-assert)
  (implements ι-2D-Point ~ι-Places ~ι-Offsets)
  (compose-fn overlay/xy)
  (render-composition (images) (-> (listof image?) image?)
                      ((? compose-fn self) (first images)
                                           (@ x self)
                                           (@ y self)
                                           (second images))))

(% Underlay/xy (kinds Overlay/xy) (flags immutable no-assert)
  (compose-fn underlay/xy))

(module+ test
  (with-objects ()
    (test-case "overlay/xy tests"
               (% p0 (kinds Overlay/xy)
                 (x 0)
                 (y 0))
               (τ Square parent: p0
                 side: 1
                 pen-or-color: blue)
               (τ Circle parent: p0
                 radius: 1)
               (check-equal? (@ render p0)
                             (overlay/xy
                              (square 1 solid blue)
                              0 0
                              (circle 1 solid gold))))
    (test-case "underlay/xy tests"
               (% p1 (kinds Underlay/xy)
                 (x 0)
                 (y 0))
               (τ Circle parent: p1
                 radius: 1)
               (τ Square parent: p1
                 side: 1
                 pen-or-color: blue)
               (check-equal? (@ render p1)
                             (underlay/xy
                              (circle 1 solid gold)
                              0 0
                              (square 1 solid blue))))))

(% Overlay/pinhole (kinds Overlay) (flags immutable no-assert)
  (compose-fn overlay/pinhole)
  (render-composition (images) (-> (listof image?) image?)
                      (apply (@ compose-fn self) images)))

(% Underlay/pinhole (kinds Overlay/pinhole) (flags immutable no-assert)
  (compose-fn underlay/pinhole))

(% Beside (kinds Container Image) (flags immutable no-assert)
  (container-lower 2)
  (container-upper () (-> real?)
                   (length (@ contents self #:when-undefined '())))
  (compose-fn beside)
  (render-composition (images) (-> (listof image?) image?)
                      (apply (? compose-fn self) images)))

(% Above (kinds Beside) (flags immutable no-assert)
  (compose-fn above))

(module+ test
  (with-objects ()
    (test-case "beside tests"
               (% p0 (kinds Beside))               
               (τ Square
                 parent: p0
                 side: 1
                 pen-or-color: blue)
               (τ Circle parent: p0
                 radius: 1)
               (check-equal? (@ render p0)
                             (beside (square 1 solid blue)
                                     (circle 1 solid gold))))
    (test-case "above tests"
               (% p1 (kinds Above))
               (τ Circle parent: p1
                 radius: 1)
               (τ Square
                 parent: p1
                 side: 1
                 pen-or-color: blue)
               (check-equal? (@ render p1)
                             (above (circle 1 solid gold)
                                    (square 1 solid blue))))))

(% Beside/align (kinds (Beside)) (flags immutable no-assert)
  (compose-fn beside/align)
  (y-place "center")
  (render-composition (images) (-> (listof image?) image?)
                      (apply (? compose-fn self)
                             (@ y-place self)
                             images)))

(% Above/align (kinds Beside/align) (flags immutable no-assert)
  (compose-fn above/align))

(module+ test
  (with-objects ()
    (test-case "beside/align tests"
               (% p0 (kinds Beside/align))               
               (τ Square
                 parent: p0
                 side: 1
                 pen-or-color: blue)
               (τ Circle parent: p0
                 radius: 1)
               (check-equal? (@ render p0)
                             (beside/align "center"
                                           (square 1 solid blue)
                                           (circle 1 solid gold))))
    (test-case "above/align tests"
               (% p1 (kinds Above/align))
               (τ Circle parent: p1
                 radius: 1)
               (τ Square
                 parent: p1
                 side: 1
                 pen-or-color: blue)
               (check-equal? (@ render p1)
                             (above/align "center"
                                          (circle 1 solid gold)
                                          (square 1 solid blue))))))
