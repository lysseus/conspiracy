#lang racket

;;;
;;; Conspiracy Object Library
;;;
;;; Conspiracy is an object-oriented paradigm. An object is defined as
;;; a collection of property ids and value pairs (i.e. properties) associated
;;; to a symbol name registered in the objects database. 
;;;
;;; * Objects are "classless", there is no need to instantiate them.
;;;   They can, however, be "flagged" as immutable, effectively
;;;   making them a template for other objects.
;;; * Objects can "inherit" from 1 or more pre-defined objects. The
;;;   specification of inheritance creates a deterministic order in
;;;   which properties are located.
;;; * Message passing can be controlled through "inherited" and "delegated"
;;;   forms that pass control down the inheritance order or delegate to other
;;;   objects. Inherited or delegated messages can specify a default response
;;;   when the desired property is undefined.
;;; * All object properties are "public", an object doesn't hide its
;;;   properties from other objects. 
;;; * Properties are "untyped", any datatype can be assoicated with
;;;   the property, although type can be enforced if the object "implements
;;;   an interface" requesting it to do so. An object may "implement a μ-props"
;;    that supplies a property and value for the object, if it does not already
;;;   do so.
;;; * Property values can be retrieved ("?") or evaluated ("@"), and unless the
;;;   object is immutable, they can be set ("!"). Retrieval and evaluation can
;;;   specify what to return when the property is undefined. Additionally, an
;;;   object can be flag a special method to handle situations when the property
;;;   is not defined.
;;; * An object can reference its own properties with the "self" keyword. 
;;; * Objects can be dynamically "replaced" in the database, dynamically effecting
;;;   the inheritance order and behaviors of other objects.
;;; * Objects can be dynaically "modified" in the database, with a superceding
;;;   definition that will inherit properties from the previous definition, or
;;    replace or remove them altogether.
;;; * Objects can be dynamically "removed" from the database, along with their
;;;   descendants and modifications.
;;; * The database can be parameterized to include only specified objects and
;;;   their inheritance requirements, or exclude specified objects and their
;;;   descendants. 
;;;
;;; Conspiracy has been modelled on the object-oriented system used by Mike Roberts' 
;;; Text Adventure Development System (TADS).
;;;
;;; The Nothing object containment model in the Nothing module is based on Graham
;;; Nelson's Inform 6 system.
;;;
;;; This module is divided into the following sections:
;;; (A) Defining Objects
;;; (B) Message Passing
;;; (C) Object Definition
;;;
;;; Submodules: (require (submod "object.rkt" module-name)
;;; Module     Description
;;; ------     --------------------------
;;; Rule       Inform-style Rulebook                          
;;; Nothing    Inform-style Object Tree
;;; @app       Redirects undefined app to @
;;; %object    Simplified notation for object defintion
;;;


(provide (struct-out objreq)
         #%top
         aux
         undefined
         undefined?
         true?
         objects
         object-names
         object?
         immutable-object?
         mutable-object?
         anonymous-object?
         default-kind
         default-kind!
         %
         %*
         τ         
         %=
         %+
         %-
         Object?
         debug
         debug!
         self
         target-prop
         target-obj
         kind-order
         defining-obj
         this
         invokee
         invokee-arity
         invokee-args
         ?
         !
         @
         inherited
         delegated
         object->list
         objects-copy
         with-objects
         without-objects)

(require (for-syntax racket/syntax)
         syntax/parse/define
         racket/undefined
         anaphoric
         "kw-pass-through-lambda.rkt")

;; Wrap unbound identifiers in quote. 
(define-simple-macro (#%top . x) 'x)

(module+ test (require rackunit
                       (submod "..")))

;; The object requirement struct.
(struct objreq (type objname propname value proc? undefined?)
  #:mutable #:transparent)

;; undefined?: v => boolean?
;; Returns true if v is the undefined value;
;;Otherwise returns false.
(define/contract (undefined? v)
  (-> any/c boolean?)
  (eq? v undefined))

;; true?: v => boolean?
;; Returns true if v is not undefined? or #f;
;;Otherwise returns false.
(define/contract (true? v)
  (-> any/c boolean?)
  (not (or (undefined? v) (false? v))))

;;;================================================================================
;;; (A) Defining Objects
;;;=================================================================================

;; current-objects: The objects hash-table's keys are symbols that
;; represent object names and values are mutable hash-tables
;; whose entries represent the object's properties. Thus it
;; requires 2 hash-refs to retrieve an object's property value. 
(define/contract current-objects
  (parameter/c (and/c hash-eq? immutable?))
  (make-parameter (make-immutable-hasheq)))
;; objects: a macro that provides the value of current-objects.
(define-syntax objects
  (λ (stx)
    (syntax-parse stx [objects:id #'(current-objects)])))
;; object-names: a macro that provides the hash-keys list of object names
;; currently registered in curren-objects.
(define-syntax object-names
  (λ (stx)
    (syntax-parse stx [objects-names:id #'(hash-keys (current-objects))])))

;; current-backup: A copy of the database.
(define/contract current-backup
  (parameter/c (or/c #f (and/c hash-eq? immutable?)))
  (make-parameter #f))
;; backup: a macro that provides the value of current-backup.
(define-syntax backup
  (λ (stx)
    (syntax-parse stx [backup:id #'(current-backup)])))

;; objects-copy: [#:fliter-not?] kinds => hash-eq?
;; #:filter-not? boolean?
;; kinds: list of kindsor empty
;; Returns a hash copy of objects filtering on kinds.
;; Results are as follows:
;; filter-not?  kinds    hash contains
;; -----------  -------   ------------
;; #f           O         O and inherited kinds
;; #t           O         All objects except O, O modifies, and inheriting O
;; #f           empty     Empty hash
;; #t           empty     All objects
(define/contract (objects-copy #:filter-not? (filter-not? #f) . kinds)
  (->* () (#:filter-not? boolean?) #:rest list? hash-eq?)
  (define names
    (cond
      [(and (empty? kinds) filter-not?) object-names]
      [(empty? kinds) '()]
      [(false? filter-not?)
       (for/fold ([acc (set)])
                 ([kind kinds])
         (values (set-union acc (list->set (@ get-kind-order kind)))))]
      [else
       (define os (for/fold ([acc (list->set kinds)])
                            ([kind kinds])
                    (values (set-union acc (list->set (@ inherits-kind kind))))))
       (set-subtract (list->set object-names)
                     (for/fold ([acc os])
                               ([kind os])
                       (values (set-union acc (list->set (@ modifies kind))))))]))
  (for/hasheq ([name names])
    (define props (hash-ref objects name))
    (define props-copy
      (for/hasheq ([propname (hash-keys props)])
        (values propname (hash-ref props propname))))
    (values name (hash-ref objects name))))

(define (backup!)
  (current-backup (objects-copy #:filter-not? #t)))

(define (restore!) (current-objects backup))

;; Object?: v => boolean?
;; Returns true if v is the Object; otherwise returns false.
(define (Object? v) (and (object? v) (eq? v Object)))

;; object?: objname => boolean?
;; Returns true if the object is defined in the objects table;
;; Otherwise returns false.
(define/contract (object? objname)
  (-> any/c boolean?)
  (hash-has-key? (current-objects) objname))

;; immutable-object? objname => boolean?
;; Returns true if objname is an object and has flags? immutable;
;; otherwise returns false.
(define/contract (immutable-object? v)
  (-> any/c boolean?)
  (and (object? v) (@ flags? v immutable)))

;; mutable-object? objname =>boolean?
;; Returns true if objname is not registered as an immutable object.
(define/contract (mutable-object? v)
  (-> any/c boolean?)
  (not (immutable-object? v)))

;; anonymous-object? objname =>boolean?
;; Returns true if objname is registered as an anonymous object.
(define/contract (anonymous-object? v)
  (-> any/c boolean?)
  (and (object? v) (string-prefix? (symbol->string v) "obj#")))

(define/contract current-construct-objname
  (parameter/c (or/c #f object?))
  (make-parameter #f))
;; construct-objname: a macro that provides the value of current-construct-objname.
(define-syntax construct-objname
  (λ (stx)
    (syntax-parse stx [construct-objname:id #'(current-construct-objname)])))

(define (construct-objname? v)
  (and (object? v) (eq? v construct-objname)))

;; object-register!: objname [properties] =>|
;; objname: symbol?
;; properties: (and/c hash-eq? immutable?)
;; Uniquely adds the object and associated properties with objects.
(define/contract (object-register! objname (properties (make-immutable-hasheq)))
  (-> (not/c object?) (and/c hash-eq? immutable?) any)
  (current-objects (hash-set objects objname properties)))

;; object-update!: objname [properties] =>|
;; objname: symbol?
;; properties: (and/c hash-eq? immutable?)
;; Updates the object's associated properties.
(define/contract (object-update! objname properties)
  (-> object? (and/c hash-eq? immutable?) any)
  (current-objects (hash-set objects objname properties)))

;; object-unregister!: objname =>|
;; objname: object?
;; Removes the object and its associated properties. 
(define/contract (object-unregister! objname) (-> object? any)
  (current-objects (hash-remove objects objname)))

;; object-properties: objname => properties
;; objname: object?
;; properties: (and/c hash-eq? immutable?)
;; Returns the properties table for this object. 
(define/contract (object-properties objname)
  (-> object? (and/c hash-eq? immutable?))
  (hash-ref objects objname))

;; object-ref: objname propname [not-found] => any/c
;; Returns the value of the directly-defined property forthe object.
;; If the object does not directly-define the property the not-found
;; value is returned.
(define/contract (object-ref objname propname (not-found undefined))
  (->* (object? symbol?) (any/c) any)
  (hash-ref (object-properties objname) propname not-found))

;; object-set!: objname propname value =>|
;; Sets the value of the directly-defined property for the object.
(define/contract (object-set! objname propname value)
  (-> object? symbol? any/c any)
  (object-update! objname (hash-set (object-properties objname) propname value)))

;; The default kind is what we use for our list of default
;; kinds. It's also what gets returned by certain functions
;; when we want an undefined?condition to return the default
;; object. 
(define/contract current-default-kind
  (parameter/c (or/c Object object? (listof object?)))
  (make-parameter Object)) ; Our "root"
;; default-kind: a macro that provides the value of current-default-kind.
(define-syntax default-kind
  (λ (stx) (syntax-parse stx [default-kind:id #'(current-default-kind)])))
;; default-kind!: a macro that sets the value of current-default-kind.
(define-syntax default-kind!
  (λ (stx) (syntax-parse stx
             [(_ k0:id k:id ...)
              #'(current-default-kind (list (quote k0) (quote k) ...))])))

;; clauses: props => lsitof (prop val)
;; Produces a list of prop/val pairs for use by
;; the Object macro.
(define-syntax (clauses stx)
  (syntax-parse stx #:literals (λ lambda % quote quasiquote)
    #:datum-literals (flags implements kinds)
    ;; no clause
    [(_)  #'(list)]

    ;; flags clause
    [(_ (flags val0:id val:id ...) clause ...)
     #'(cons (list 'flags val0 val ...)
             (clauses clause ...))]

    ;; implements clause
    [(_ (implements val0:id val:id ...) clause ...)
     #'(cons (list 'implements val0 val ...)
             (clauses clause ...))]
    
    ;; kinds clause
    [(_ (kinds val0:id val:id ...) clause ...)
     #'(cons (list 'kinds val0 val ...)
             (clauses clause ...))]
    
    ;; method clause
    [(_ (prop:id argspec:expr cspec body0:expr body:expr ...) clause ...)
     #'(cons (cons (quote prop) (contract cspec
                                          (λ argspec
                                            (debug-trace-method)
                                            body0 body ...)
                                          '(prop λ argspec)
                                          (current-contract-region) prop #'prop))
             (clauses clause ...))]

    ;; nested object clause
    [(_ (prop:id (% val ...)) clause ...)
     #'(let ([lp (current-lexical-parent)])
         (cons (cons (quote prop) (% (lexical-parent lp) val ...))
               (clauses clause ...)))]

    ;; λ clause
    [(_ (prop:id (λ argspec body0 body ...)) clause ...)
     #'(cons (cons (quote prop) (λ argspec body0 body ...))
             (clauses clause ...))]

    ;; lambda clause
    [(_ (prop:id (lambda argspec body0 body ...)) clause ...)
     #'(cons (cons (quote prop) (λ argspec body0 body ...))
             (clauses clause ...))]

    ;; quote clause
    [(_ (prop:id (quote val)) clause ...)
     #'(cons (cons (quote prop) 'val)
             (clauses clause ...))]

    ;; quasiquote clause
    [(_ (prop:id (quasiquote val)) clause ...)
     #'(cons (cons (quote prop) `val)
             (clauses clause ...))]
    
    ;; list clause
    [(_ (prop:id (v0:expr val:expr ...)) clause ...)
     #'(cons (cons (quote prop)
                   (if (procedure? v0)
                       (v0 val ...)
                       (list v0 val ...)))
             (clauses clause ...))]
    
    ;; empty list clause
    [(_ (prop:id ()) clause ...)
     #'(cons (cons (quote prop) '())
             (clauses clause ...))]

    ;; default clause
    [(_ (prop:id val:expr) clause ...)
     #'(cons (cons (quote prop) val)
             (clauses clause ...))]))

;; mod-clauses: props => lsitof (prop val)
;; Produces a list of prop/val pairs for use by
;; the Object macro.
(define-syntax (mod-clauses stx)
  (syntax-parse stx 
    #:datum-literals (remove replace)
    ;; no clause
    [(_)  #'(list)]
        
    ;; remove clause
    [(_ (remove val0:expr val:expr ...) clause ...)
     #'(cons (list 'remove (if (symbol? val0) val0 'val0)
                   (if (symbol? val) val 'val) ...)
             (clauses clause ...))]
    
    ;; replace props clause
    [(_ (replace val:expr ...) clause ...)
     #'(cons (cons 'replace (clauses val ...))
             (clauses clause ...))]

    ;; default clause
    [(_ clause0 clause ...)
     #'(append (clauses clause0)
               (mod-clauses clause ...))]))

(module+ test
  (test-case "flags, kinds,implements clauses"
             (check-equal? (clauses (flags x y z))
                           '((flags x y z)))

             (check-equal? (clauses (implements x y z))
                           '((implements x y z))))
  (test-case "remove and replace tests"
             (check-equal? (mod-clauses (remove p0 p1 p2) (p3 42) (p4 (x y z)))
                           '((remove p0 p1 p2) (p3 . 42) (p4 x y z)))
             (check-equal? (mod-clauses (replace (p0 0) (p1 1)) (p2 42) (p3 (x y z)))
                           '((replace (p0 . 0) (p1 . 1)) (p2 . 42) (p3 x y z))))
  (test-case "quote, quasiquote tests"
             (check-equal? (clauses (p0 'pi))
                           (list (cons p0 'pi)))
             (check-equal? (clauses (p0 `,pi))
                           (list (cons p0 pi)))
             (check-equal? (clauses (p0 '(pi x y z)))
                           (list (cons p0 '(pi x y z))))
             (check-equal? (clauses (p0 `(,pi x y z)))
                           (list (cons p0 `(,pi x y z)))))
  (test-case "list, empty list tests"
             (check-equal? (clauses (p0 (vector a b pi)))
                           (list (cons p0 #(a b 3.141592653589793))))
             (check-equal? (clauses (p0 (foo a b pi)))
                           (list (cons p0 (list foo a b pi))))

             (check-equal? (clauses (p0 ('list a b pi)))
                           (list (cons p0 `(list a b ,pi))))
             (check-true
              (contract?
               (cdr (car (clauses (p0 (listof (or/c number? string?)))))))))
  (test-case "default clause"
             (check-equal? (clauses (p0 42))
                           '((p0 . 42)))))

;; make-objname: pfx -> symbol?
;; Creates an interned anonymous-object name symbol.
;; Symbol is interned for referencing. 
(define (make-objname (pfx 'obj#))
  (string->symbol (symbol->string (gensym pfx))))

(define current-lexical-parent (make-parameter #f))

;; (% name (prop (arg ...) body0 body ...) ...
;; (% name (prop (val ...)) ...
;; (% name (prop val) ...
(define-syntax (% stx)
  (syntax-parse stx
    [(_ (~optional name:id) clause ...)
     #'(parameterize ([current-lexical-parent (~? (quote name)  (make-objname 'obj#))])
         (let ([props (clauses clause ...)])
           (make-object (current-lexical-parent)
                 (if (assq 'kinds props)
                     props
                     (let ([ks default-kind])
                       (cons `(kinds ,@(if (list? ks) ks (list ks))) props))))))]))

;; (%* peropety ...)
;; (%* kind0 kind ... property)
(define-syntax (%* stx)
  (syntax-parse stx
    ;; Anonymous with kinds
    [(_ kind0:id kind:id ... clause ...)
     #'(parameterize ([current-lexical-parent (make-objname 'obj#)])
         (let ([props (clauses clause ...)])
           (make-object (current-lexical-parent)
                 (if (assq 'kinds props)
                     (raise-user-error (current-lexical-parent)
                                       "kinds property not valid in definition.")
                     (let ([ks (list kind0 kind ...)])
                       (cons `(kinds ,@ks) props))))))]
    ;; Anonymous without kinds
    [(_ clause ...)
     #'(parameterize ([current-lexical-parent (make-objname 'obj#)])
         (let ([props (clauses clause ...)])
           (make-object (current-lexical-parent)
                 (if (assq 'kinds props)
                     (raise-user-error (current-lexical-parent)
                                       "kinds property not valid in definition.")
                     (let ([ks default-kind])
                       (cons `(kinds ,@(if (list? ks) ks (list ks))) props))))))]))

(define (τ-propname? v)
  (and (symbol? v) (string-suffix? (symbol->string v) ":")))

(define (τ-propname-trim v)
  (string->symbol (string-trim #:right? #t (symbol->string v) ":")))

(define (τ-clauses->clauses lst (tmp #f) (acc '()))
  (cond
    [(null? lst) (cond
                   [(and (false? tmp) (empty? acc))
                    empty]
                   [(null? tmp)
                    (reverse acc)]
                   [else (reverse (cons tmp acc))])]
    [(τ-propname? (car lst))
     (τ-clauses->clauses (cdr lst)
                         (τ-propname-trim (car lst))
                         (if (false? tmp)
                             acc
                             (cons tmp acc)))]
    [else (τ-clauses->clauses (cdr lst)
                              (cond
                                [(and (pair? tmp) (pair? (cdr tmp)))
                                 (cons (car tmp)
                                       (append (cdr tmp) (list (car lst))))]
                                [(pair? tmp)
                                 (cons (car tmp)
                                       (list (cdr tmp) (car lst)))]
                                [else (cons tmp (car lst))])
                              acc)]))

;; (τ Text/font string: s 	 	 	 
;;              font-size: fs
;;              color: c
;;              face: f	 	 	 	 
;;              family: fm
;;              style: st	 	 	 	 
;;              weight: w	 	 	 	 
;;              underline?: u)
(define-syntax (τ-clauses stx)
 (syntax-parse stx
   [(_) #'(list)]
   [(_ arg0:id arg ...)
    #:when (regexp-match "[:]" (symbol->string (syntax-e #'arg0)))
    #'(cons (quote arg0) (τ-clauses arg ...))]
   [(_ arg0 arg ...)
    #'(cons arg0 (τ-clauses arg ...))]))


(define-syntax (τ stx)
  (syntax-parse stx
  [(_ kind:id arg ...)
;;   #`(make-object (get-objname ) name (τ-clauses->clauses (τ-clauses arg ...)))
   #'(parameterize ([current-lexical-parent (make-objname 'obj#)])
         (let ([props (τ-clauses->clauses (τ-clauses arg ...))])
           (make-object (current-lexical-parent)
                 (if (assq 'kinds props)
                     (raise-user-error (current-lexical-parent)
                                       "kinds property not valid in definition.")
                     (let ([ks (list kind)])
                       (cons `(kinds ,@ks) props))))))]))

;; make-object: objname props #:construct? => objname
;; objname: (or/c #f (and/c symbol? (not/c object?)))
;; props: (or empty (list-of (propname . value)))
;; construct? boolean?
;; - Registers this name and property list in the objects table.
;; - Establishes the object's kinds and ineritance  o - Calls the object's constructor, if requested.
;; - Returns the object name
(define/contract (make-object #:construct? (construct? #t) #:backup? (backup? #t)
                   objsym props)
  (->i ([name (or/c #f (and/c symbol? (not/c object?)))]
        [ps (name) (listof
                    (or/c
                     (cons/c 'kinds
                             (non-empty-listof
                              (or/c 'Object (and/c (not/c name) object?))))
                     (cons/c (and/c symbol? (not/c 'kinds)) any/c)))])
       (#:construct? [call () boolean?]
        #:backup? [bkp () boolean?])
       (result symbol?))
  (define objname (if (false? objsym)
                      (make-objname 'obj#)
                      objsym))
  ;; Create shallow backup of database
  (when backup? (backup!))
  ;; setup the properties table for the new object
  (object-register! objname (make-immutable-hasheq props))
  ;; Pre-construct property validation. 
  (with-handlers ([exn:fail? (λ (e) (restore!) (raise e))])
    (@ ε-props-assert objname)
    (parameterize ([current-construct-objname objname])
      ;; Enforce any μ-props interfaces this object implements
      (@ μ-props-assert! objname)
      (when construct?    
        (@ construct objname)))
    (unless (@ flags? objname no-assert)               
      ;; Enforce any ι-props interfaces this object implements
      (@ ι-props-assert objname)))
  ;; Return object name
  objname)

;; (%= name (prop (arg ...) body0 body ...) ...
;; (% name (prop (val ...)) ...
;; (% name (prop val) ...
(define-syntax (%= stx)
  (syntax-parse stx
    [(_ name:id clause ...)
     #'(parameterize ([current-lexical-parent name])
         (let ([props (clauses clause ...)])
           (object-replace (current-lexical-parent)
                           (if (assq 'kinds props)
                               props
                               (let ([ks default-kind])
                                 (cons `(kinds ,@(if (list? ks) ks (list ks)))
                                       props))))))]))

(define/contract (object-replace #:construct? (construct? #t)
                                 #:backup? (backup? #t)
                                 objname props)
  (->i ([name (and object? (not/c Object?))]
        [ps (name) (listof
                    (or/c
                     (cons/c 'kinds
                             (non-empty-listof
                              (or/c 'Object (and/c (not/c name) object?))))
                     (cons/c (and/c symbol? (not/c 'kinds)) any/c)))])
       (#:construct? [call () boolean?]
        #:backup? [bkp () boolean?])
       (result symbol?))
  ;; Create shallow backup of database
  (when backup? (backup!))
  (with-handlers ([exn:fail? (λ (e) (restore!) (raise e))])
    (object-remove objname)
    (make-object objname props #:backup? #f))  
  ;; Return object name
  objname)

;; (%+ name (prop (arg ...) body0 body ...) ...
;; (% name (prop (val ...)) ...
;; (% name (prop val) ...
(define-syntax %+
  (syntax-rules ()
    [(_ name clause ...)
     (object-modify (quote name) (mod-clauses clause ...))]
    [(_ #:construct? construct? name (val ...) ...)
     (object-modify (quote name)
                    (mod-clauses ((val ...) ...)) #:construct? construct?)]
    [(_ name #:construct? construct? (val ...) ...)
     (object-modify (quote name)
                    (mod-clauses ((val ...) ...)) #:construct? construct?)]
    [(_ name (val ...) ... #:construct? construct?)
     (object-modify (quote name)
                    (mod-clauses ((val ...) ...)) #:construct? construct?)]))

(define/contract (object-modify #:construct? (construct? #t)
                                #:backup? (backup? #t)
                                objname props)
  (->* [(and object? (not/c Object?))
        (non-empty-listof (cons/c (and/c symbol? (not/c 'kinds)) any/c))]
       [#:construct? boolean?
        #:backup? boolean?]
       symbol?)

  ;; Create shallow backup of database
  (when backup? (backup!))
  
  ;; Create name for modification linking object
  (define modname (string->symbol (symbol->string (make-objname 'mod#))))

  (define (normalize-props modname props)
    (define h0 (make-hasheq props))
    (define rpls (hash-ref h0 'replace '()))
    (define rems (hash-ref h0 'remove '()))
    (unless (empty? rpls) (hash-remove! h0 'replace))
    (unless (empty? rems) (hash-remove! h0 'remove))
    (for ([r rems])
      (hash-remove! h0 r))
    (define props1 (append (hash->list h0) rpls `((kinds . (,modname)))))
    (values (make-immutable-hasheq props1)
            (remove-duplicates (append (map car rpls) rems))))

  (define-values (objhash remkeys) (normalize-props modname props))  
  ;; Remove remkeys from the object and every modification
  (unless (empty? remkeys)
    (define mods (@ modifies objname))
    (for ([name (cons objname mods)])
      (define props (object-properties name))      
      ;; Remove remkeys from this object's properties
      (define modprops (filter-not (λ (prop) (member (car prop) remkeys))
                                   (hash->list props)))
      
      ;; Update this object with a new properties table
      (object-update! name (make-immutable-hasheq modprops))))

  ;; register the object's properties to modname
  (object-register! modname (object-properties objname))

  ;; Update the object's properties
  (object-update! objname objhash)
  
  (with-handlers ([exn:fail? (λ (e) (restore!) (raise e))])
    (@ ε-props-assert objname)
    (parameterize ([current-construct-objname objname])
      ;; Enforce any μ-props interfaces this object implements
      (@ μ-props-assert! objname)
      (when (or construct? (@ prop-defined objname construct  prop-def-directly))    
        (@ construct objname)))
    (unless (@ flags? objname no-assert)               
      ;; Enforce any ι-props interfaces this object implements
      (@ ι-props-assert objname)))

  ;; Return object name
  objname)


;; %-: objname [mods?] => (listof symbol?)
;; objname: object?
;; mods?: boolean?
;; Removes objname and any objects inheriting it from the object register.
;; If mods? is true then the object modifications will be unregistered as well.
;; Returns the list of objects removed.
(define-syntax (%- stx)
  (syntax-parse stx
    [(_ name:id mods?:expr) #'(object-remove (quote name) mods?)]
    [(_ name:id) #'(object-remove (quote name))]))

(define/contract (object-remove objname (mods? #t))
  (->* ((and object? (not/c Object?))) (boolean?) any)
  ;; Get a list of mods for this object if requested.
  (define modnames (if mods? (@ modifies objname) '()))
  ;; Retrieve the list of all objects inheriting objname and
  ;; adds objname to the list to be removed from the object
  ;; register.
  (define objnames (append (@ inherits-kind objname) (list objname) modnames))
  (for ([oname objnames])
    (object-unregister! oname))
  objnames)


;;;================================================================================
;;; (B) Message Passing
;;;=================================================================================

;; debug: 
(define/contract current-debug
  (parameter/c boolean?)
  (make-parameter #f))
(define-syntax debug
  (λ (stx)
    (syntax-parse stx [debug:id #'(current-debug)])))
(define-syntax debug!
  (λ (stx)
    (syntax-parse stx
      [(_) #'(current-debug (not debug))]
      [(_ v:boolean)
       #'(current-debug v)])))


;; kind-order: The kind-order pseudo-variable provides a reference to
;; the object's inheritance.
(define/contract current-kind-order
  (parameter/c (or/c undefined? (listof object?)))
  (make-parameter undefined))
(define-syntax kind-order
  (λ (stx)
    (syntax-parse stx [kind-order:id #'(current-kind-order)])))

;; self: The self pseudo-variable provides a reference to
;; the object whose method was originally invoked to reach
;; the current method. Because of ifnheritance, this is not
;; necessarily the object or class where the current method
;; is actually defined.
(define/contract current-self
  (parameter/c (or/c undefined? object?))
  (make-parameter undefined))
(define-syntax self
  (λ (stx)
    (syntax-parse stx [self:id #'(current-self)])))

;; self?: v => boolean?
;; Returns true if v is self; false otherwise.
(define (self? v) (and (object? v) (eq? v self)))

;; directly-defined-properties: The properties pseudo-variable provides a reference to
;; the object's directly-defined properties whose method was originally invoked to reach
;; the current method. Because of ifnheritance, this is not necessarily the object or 
;; class where the current method is actually defined.
(define/contract current-directly-defined-properties
  (parameter/c (or/c undefined? (and/c immutable? hash-eq?)))
  (make-parameter undefined))
(define-syntax directly-defined-properties
  (λ (stx)
    (syntax-parse stx [directly-defined-properties:id
                       #'(current-directly-defined-properties)])))

;; target-prop: The pseudo-variable target-prop provides access
;; at run-time to the current target property, which is the prperty
;; that was invoked to reach the current method. This complements self, 
;; which gives the object whose property was invoked.
(define/contract current-target-prop
  (parameter/c (or/c undefined? symbol?))
  (make-parameter undefined))
(define-syntax target-prop
  (λ (stx)
    (syntax-parse stx [target-prop:id #'(current-target-prop)])))

;; target-prop-propname?: v => boolean?
;; Returns true if v is target-prop; false otherwise.
(define (target-prop-propname? v) (and (object? v) (eq? v target-prop)))

;; target-obj: The pseudo-variable target-obj provides access at run-time
;; to the original target object of the current method. This is the object
;; that was specified in the method call that reached the current method. 
;; The target object remains unchanged when you use inherited to inherit
;; a kind method, because the method is still executing in the context of
;; the original call to the inheriting method.
;;
;; The target-obj value is the same as self in normal method calls, but not 
;; in calls initiated with the delegated keyword. When delegated is used, 
;; the value of self stays the same as it was in the delegating method, 
;; and target-obj gives the target of the delegated call.
(define/contract current-target-obj
  (parameter/c (or/c undefined? object?))
  (make-parameter undefined))
(define-syntax target-obj
  (λ (stx)
    (syntax-parse stx
      [target-obj:id #'(current-target-obj)])))

;; target-obj?: v => boolean?
;; Returns true if v is target-obj; false otherwise.
(define (target-obj? v) (and (object? v) (eq? v target-obj)))

;; defining-obj: This pseudo-variable provides access at run-time to the current
;; method definer. This is the object that actually defines the method currently 
;; executing; in most cases, this is the object that defined the current method
;; code in the source code of the program.
(define/contract current-defining-obj
  (parameter/c (or/c undefined? object?))
  (make-parameter undefined))
(define-syntax defining-obj
  (λ (stx)
    (syntax-parse stx
      [defining-obj:id #'(current-defining-obj)])))
(define-syntax this
  (λ (stx)
    (syntax-parse stx
      [this:id #'(current-defining-obj)])))

;; defining-obj?: v => boolean?
;; Returns true if v is defining-obj; false otherwise.
(define (defining-obj? v) (and (object? v) (eq? v defining-obj)))

;; invokee: provides a pointer to the currently executing function.
(define/contract current-invokee
  (parameter/c (or/c undefined? procedure?))
  (make-parameter undefined))
(define-syntax invokee
  (λ (stx)
    (syntax-parse stx
      [invokee:id #'(current-invokee)])))

;; invokee-arity: This pseudo-variable contains a normalized arity giving
;; information about the number of by-position arguments accepted by invokee.
(define/contract current-invokee-arity
  (parameter/c (or/c undefined? normalized-arity?))
  (make-parameter undefined))
(define-syntax invokee-arity
  (λ (stx)
    (syntax-parse stx
      [invokee-arity:id #'(current-invokee-arity)])))

;; invokee-args: provides a pointer to the currently executing function arguments.
(define/contract current-invokee-args
  (parameter/c (or/c undefined? list?))
  (make-parameter undefined))
(define-syntax invokee-args
  (λ (stx)
    (syntax-parse stx
      [invokee-args:id #'(current-invokee-args)])))

;; debug-print: fstr args =>|
;; fstr: string?
;; args: list?
;; Prints the format string only when debug is true.
(define/contract (debug-printf fstr . args)
  (->* (string?) #:rest list? any)
  (when debug
    (apply printf fstr args)))

;; debug-show-params: =>|
;; Displays the pseudo-variables used in object message passing.
(define (debug-show-params)
  (debug-printf "[Parameters:]~%")
  (debug-printf "\tself:\t\t~a~%" self)
  (debug-printf "\ttarget-prop:\t~a~%" target-prop)
  (debug-printf "\ttarget-obj:\t~a~%" target-obj)
  (debug-printf "\tkind-order:\t~a~%" kind-order)
  (debug-printf "\tdefining-obj:\t~a~%" defining-obj)
  (debug-printf "\tinvokee:\t~a~%" invokee)
  (debug-printf "\tinvokee-arity:\t~a~%" invokee-arity))

(define (valid-call-type? v)
  (case v
    [(? ! @) #t]
    [(inherited delegated)
     (object? self)]))

;; object-call: call-type propname objname args => any
;; call-type: (or/c '? '! '@ 'inherited 'delegated)
;; propname: symbol?
;; objname: object?
;; args: list?
;; Retrieves the directly-defined or inherited property value
;; for the object. Depending on call-type:
;;   ? - returns the property value for the object.
;;   ! - updates the property value for the object.
;;   @ - returns the property value for the object, if a procedure
;;       applies the arguments to the procedure and returns the result.
;;   inherited - passes retrieval down the object's kind-order.
;;   delegated - passes retrieval to the delegated object.
(define object-call
  (kw-pass-through-lambda
   (call-type propname objname . args)
   ;;(define/contract (object-call call-type propname objname . args)
   ;;  (->* (valid-call-type? symbol? object?) #:rest list? any)
   (debug-printf "[~a: ~a ~a ~a]~%" call-type propname objname args)
  
   ;; Adjusts the defining-obj passed to prop-inherited when inherited supplies
   ;; the previous kind in the kind-order is used. 
   (define (inherited-defining-obj)
     (cond
       [(defining-obj? objname) defining-obj]
       [else (last (for/list ([t kind-order] #:break (eq? t objname)) t))]))
  
   (parameterize* ([current-target-prop propname]
                   [current-self (case call-type
                                   [(inherited delegated) self]
                                   [else objname])]
                   [current-directly-defined-properties (case call-type
                                                          [(inherited delegated)
                                                           (object-properties self)]
                                                          [else (object-properties objname)])]
                   [current-target-obj (case call-type
                                         [(inherited) target-obj]
                                         [else objname])]
                   [current-kind-order (case call-type
                                         [(inherited) kind-order]
                                         [else
                                          ((object-ref Object
                                                       build-kind-order) target-obj)])]
                   [current-defining-obj (case call-type
                                           [(inherited)
                                            ((object-ref Object prop-inherited)
                                             target-prop
                                             target-obj
                                             (inherited-defining-obj)
                                             prop-def-get-kind)]
                                           [else
                                            ((object-ref Object prop-defined)
                                             target-prop
                                             prop-def-get-kind)])])
     (case call-type
       [(!) (object-set! self target-prop (car args))]
       [else
        (define val
          (if (undefined? defining-obj)
              undefined
              (object-ref defining-obj target-prop)))
        (case call-type
          [(?) val]
          [else
           (parameterize* ([current-invokee (if (procedure? val) val undefined)]
                           [current-invokee-arity (if (undefined? invokee)
                                                      undefined
                                                      (procedure-arity invokee))]
                           [current-invokee-args args])
             (when debug (debug-show-params))
             (cond
               [(and (not (eq? propname prop-not-defined))
                     (undefined? invokee)
                     (@ flags? self prop-not-defined))
                (apply @ prop-not-defined self propname args)]
               [(undefined? invokee) val]
               [else (local-keyword-apply invokee args)]))])]))))

;; ?: propname objname when-undefined => any
;; propname: symbol?
;; objname: objeect?
;; when-undefined: any
;; Retrieves the directly-defined or inherited property value for the 
;; object. When the result is undefined returns the when-undefined value.
(define/contract (? #:when-undefined (when-undefined undefined)
                    #:assert (assert #f)
                    propname objname)
  (->* (symbol? object?) (#:when-undefined any/c #:assert any/c) any)
  (define result (object-call '? propname objname))
  (define msg-result (if (undefined? result)
                         when-undefined
                         result))
  (when (procedure? assert)
    (contract assert msg-result
              (string->symbol (format "~a.~a" objname propname))
              (current-contract-region)))
  msg-result)

;; !: propname objname value =>|
;; propname: symbol?
;; objname: objeect?
;; value: any
;; Updates the property value for the object.
(define/contract (! propname objname value)
  (-> symbol? (or/c mutable-object? construct-objname?) any/c any)
  (object-call '! propname objname value))

;; @: propname objname args when-undefined => any
;; propname: symbol?
;; objname: objeect?
;; args: list?
;; when-undefined: any/c
;; Retrieves the directly-defined or inherited property value for the 
;; object. If the value is a procedure then applies value to the arguments. 
;; When the result is undefined returns the when-undefined value.
(define @
  (kw-pass-through-lambda
   (#:when-undefined (when-undefined undefined)
    propname objname . args)
   (unless (symbol? propname)
     (raise-argument-error '@
                           "symbol?"
                           propname))
   (unless (object? objname)
     (raise-argument-error '@
                           "object?"
                           objname))
   (define result (local-keyword-apply object-call `(@ ,propname ,objname ,@args)))
   (if (undefined? result)
       when-undefined
       result)))

;; inherited: [#:propname] [#:objname] [#:when-undefined] args ... => any
;; propname: symbol?
;; objname: objeect?
;; when-undefined: any
;; Retrieves the inherited property value for the specified object.
;; When the result is undefined returns the when-undefined value.
;; This call can only be used from within a property method.
#;(define/contract (inherited #:propname (propname target-prop)
                            #:objname (objname defining-obj)
                            #:when-undefined (when-undefined undefined). args)
  (->i ()
       (#:propname [prop symbol?]
        #:objname [obj () object?]
        #:when-undefined [undef () any/c])
       #:rest [rst () list?]
       #:pre/desc (obj)
       (cond [(undefined? kind-order)
              "Cannot be used outside of @ context."]
             [(unsupplied-arg? obj) #t]
             [(false?(member obj kind-order))
              (format "#:objname ~a not within kind-order ~a."
                      obj kind-order)]
             [(false? (member obj (cdr (member defining-obj kind-order))))
              (format "#:objname ~a must occur later than previous defining-obj ~a in kind-order ~a." obj defining-obj kind-order)]
             [else #t])
       (result () any/c))
  (define result (apply object-call 'inherited propname objname args))
  (if (undefined? result)
      when-undefined
      result))
(define inherited
  (kw-pass-through-lambda
   (#:propname (propname target-prop)
    #:objname (objname defining-obj)
    #:when-undefined (when-undefined undefined). args)   
   (define result (local-keyword-apply object-call `(inherited ,propname ,objname ,@args)))
   (if (undefined? result)
       when-undefined
       result)))

;; delegated: [#:propname] [#:when-undefined] objname arg ... => any
;; propname: symbol?
;; objname: objeect?
;; when-undefined: any
;; Retrieves the inherited property value for the specified object.
;; When the result is undefined returns the when-undefined value.
;; This call can only be used from within a property method.
#;(define/contract (delegated #:propname (propname target-prop)
                            #:when-undefiend (when-undefined undefined)
                            objname . args)
  (->i ([obj object?])
       (#:propname [prop () symbol?]
        #:when-undefiend [undef () any/c])
       #:rest [rst () list?]
       #:pre/desc ()
       (if (undefined? kind-order)
           "Cannot be used outside of @ context."
           #t)
       [result () any/c])
  (define result (apply object-call 'delegated propname objname args))
  (if (undefined? result)
      when-undefined
      result))
(define delegated
  (kw-pass-through-lambda
   (#:propname (propname target-prop)
    #:when-undefiend (when-undefined undefined)
    objname . args)  
   (define result (local-keyword-apply object-call `(delegated ,propname ,objname ,@args)))
   (if (undefined? result)
       when-undefined
       result)))

(define (debug-trace-method)
  (debug-printf "[~a:~a | target=~a self=~a | args=~a]~%"
                target-prop
                defining-obj
                target-obj
                self
                invokee-args))


;;;================================================================================
;;; (C) Object Definition
;;;
;;; Object Inheritance:
;;; The basic rule for multiple inheritance priority is that the leftmost kind
;;; takes precedence over other kinds. By leftmost, we mean the one defined
;;; earliest in the kinds list.
;;;=================================================================================


;;; aux: a macro for defining "aux" variables
;;; where unassigned variables are assigned the value of the object's
;; directly-defined property, if one exists, or undefined if it does not.
;;;
(define-syntax (aux stx)
 (syntax-case stx (@ ?)
   [(_) #'(begin)]
   [(_ (var @ val) . rst)
    (identifier? #'var)
    #'(begin
        (define var (@ (quote var) self #:when-undefined val))
        (aux . rst))]
   [(_ (var @) . rst)
    (identifier? #'var)
    #'(begin
        (define var (@ (quote var) self))
        (aux . rst))]   
   [(_ (var ? val) . rst)
    (identifier? #'var)
    #'(begin
        (define var (? (quote var) self #:when-undefined val))
        (aux . rst))]
   [(_ (var ?) . rst)
    (identifier? #'var)
    #'(begin
        (define var (? (quote var) self))
        (aux . rst))]
   [(_ (var val) . rst)
    (identifier? #'var)
    #'(begin
        (define var val)
        (aux . rst))]
   [(_ var . rst)
    (identifier? #'var)
    #'(begin
        (define var (hash-ref directly-defined-properties (quote var) undefined))
        (aux . rst))]))

(% Object (flags immutable)
   
   ;; flags! toggles the flag setting for a mutable object.
   ;; (@ flags! self) clears the flag setting for the object.
   (flags! args (->* () #:rest list? any)
           (define fs (if (@ prop-defined self flags prop-def-directly)
                          (? flags self)
                          empty))
           (cond
             [(empty? args) (! flags self '())]
             [else (! flags self (append (remove* args fs) (remove* fs args)))]))
   
  ;; flags? returns true if the object directly defines a flags property
  ;; and the flags list contains all the symbols listed in args. 
  (flags? (#:all (all #t) . args)
          (->* () (#:all boolean?) #:rest (non-empty-listof symbol?) boolean?)
          (and (@ prop-defined self flags prop-def-directly)
               ((if (false? all) ormap andmap)
                (λ (f) (member f (? flags self))) args)
               #t))
  
  ;; Returns a list containing the immediate kinds of the object. The
  ;; list contains only the object's direct kinds, which are the objects
  ;; that were explicitly listed in the object's kinds property.
  (get-kinds-list ()
                  (-> any)
                  (? kinds self))
  
  ;; The inheritance order is deterministic (i.e., it will always be the
  ;; same for a given situation), and it depends on the full kind tree of
  ;; the original target object. 
  (build-kind-order ((objname #f)) (->* () ((or/c #f object?)) (listof object?))
                    (define (build-kind-order o (acc (make-parameter empty)))
                      (define ts (remove-duplicates
                                  (flatten (cons o
                                                 (object-ref o
                                                             kinds
                                                             empty)))))
                      (define diff (remove* (acc) ts))
                      (acc (append (acc) diff))
                      (for ([v (remove* (list o) diff)])
                        (build-kind-order v acc))
                      (acc))
                    (build-kind-order (if objname objname target-obj)))
  ;; Returns the pre-built ordering of kinds created
  ;; as part of the objeect-call process. 
  (get-kind-order () (-> any)
                  kind-order)
  
  ;; Returns a list of the properties directly defined by this object. 
  ;; Each entry in the list is a property symbol. The returned list
  ;; contains only properties directly defined by the object; inherited
  ;; properties are not included, but may be obtained by explicitly
  ;; traversing the kinds list and calling this method on each kind.
  (get-prop-list (#:filter (f #f))
                 (->* () (#:filter (or/c boolean? list? procedure?)) list?)
                 (define ks (hash-keys (object-properties self)))
                 (cond
                   [(false? f) ks]
                   [(boolean? f) (remove* '(flags implements kinds) ks)]
                   [(list? f) (remove* f ks)]
                   [else
                    (filter-not f ks)]))

  ;; Returns a list of information associated with the parameters
  ;; and result of the property associated with this object, or #f if
  ;; the property is undefined.
  ;; [1] mask encoding of by-position arguments
  ;; [2] list of required keyword arguments
  ;; [3] list of accepted keyword arguments
  ;; [4] result arity
  (get-prop-params (prop) (-> symbol? any)
                   (define p (? prop self))
                   (cond
                     [(undefined? p) undefined]
                     [(not (procedure? p)) '(0 () () #f)]
                     [else
                      (define-values (required-keywords accepted-keywords)
                        (procedure-keywords p))
                      (list (procedure-arity-mask p)
                            required-keywords
                            accepted-keywords
                            (procedure-result-arity p))]))
  
  ;; Determines if the object is an instance of the kind, or an instance
  ;; inheriting from kind. Returns true if so, #f if not. This method
  ;; always returns true if kind is Object, since every object
  ;; ultimately derives from Object.
  (of-kind? (kind)
            (-> object? boolean?)
            (not (false? (member kind kind-order))))
  
  ;; Determines if the object defines or inherits the property propname,
  ;; according to the flags value. If flags is not specified, a default value
  ;; of prop-def-any is used. The valid flags values are:
  ;; * prop-def-any - the function returns true if the object defines or
  ;;                  inherits the property.
  ;; * prop-def-directly - the function returns true only if the object
  ;;                       directly defines the property; if it inherits the 
  ;;                       property from a superclass, the function returns #f.
  ;; * prop-def-inherits - the function returns true only if the object inherits
  ;;                     the property from a kind; if it defines the property
  ;;                     directly, or doesn't define or inherit the property
  ;;                  at all, the function returns #f.
  ;; * prop-def-get-kind - the function returns the kind object
  ;;                        from which the property is inherited,
  ;;                        or this object if the object defines the
  ;;                        property directly. If the object doesn't
  ;;                        define or inherit the property, the function
  ;;                        returns #f.
  (prop-defined (propname (flag prop-def-any))
                (->* (symbol?)
                     ((or/c prop-def-any
                            prop-def-directly
                            prop-def-inherits
                            prop-def-get-kind))
                     (or/c boolean? object? undefined?))
                (define result
                  (for/first ([kind kind-order]
                              #:when (member propname
                                             (hash-keys (object-properties kind))))
                    kind))
                (case flag
                  [(prop-def-directly) (and (true? result)
                                            (self? result))]
                  [(prop-def-inherits) (and (true? result)
                                            (not (self? result)))]
                  [(prop-def-any) (true? result)]
                  [else (if (false? result)
                            undefined
                            result)]))

  ;; Determines if the object inherits the property prop. target is the
  ;; "original target object," which is the object on which the method was
  ;; originally invoked. definer is the "defining object," which is the
  ;; object defining the method which will be inheriting the kind
  ;; implementation.
  ;;
  ;; The return value depends on the value of the flags argument:
  ;;
  ;;    prop-def-any - the function returns true if the object inherits
  ;;                   the property, false otherwise.
  ;;    prop-def-get-kind - the function returns the kind object
  ;;                         from which the property is inherited, or false
  ;;                         if the property is not inherited.
  ;; This method is most useful for determining if the currently active method
  ;; will invoke an inherited version of the method if it uses the inherited
  ;; operator; this is done by passing targetprop for the prop parameter, targetobj
  ;; for the target parameter, and defining-obj for the definer parameter. When
  ;; a kind is designed as a "mix-in" (which means that the kind is designed
  ;; to be used with multiple inheritance as one of several base kinds, and adds
  ;; some isolated functionality that is "mixed" with the functionality of the
  ;; other base kinds), it sometimes useful to be able to check to see if the
  ;; method is inherited from any other base kind involved in multiple
  ;; inheritance. This method allows the caller to determine exactly what inherited
  ;; will do.
  (prop-inherited (propname target definer (flag prop-def-any))
                  (->* (symbol? object? (or/c undefined? object?))
                       ((or/c prop-def-any
                              prop-def-get-kind))
                       (or/c boolean? object? undefined?))
                  ;; We only need to calculate kind-order when target-obj
                  ;; is different from target.
                  (define target-order
                    (if (target-obj? target)
                        kind-order
                        ((object-ref Object
                                     build-kind-order)
                         target)))
                  ;; When definer is undefined we search the whole order;
                  ;; otherwise we begin with the next kind after definer.
                  (define order                  
                    (cond
                      [(undefined? definer) target-order]
                      [else
                       (define tmp
                         (member definer target-order))
                       (if (false? tmp) '() (cdr tmp))]))
                  (debug-printf "[prop-inherited: order=~a]~%" order)
                  (define result
                    (for/first ([kind order]
                                #:when (member propname
                                               (hash-keys (object-properties kind))))
                      kind))
                  (case flag
                    [(prop-def-any) (true? result)]
                    [else (if (false? result)
                              undefined
                              result)]))
  
  ;; Returns the datatype of the given property of the given object, or undefined
  ;; if the object does not define or inherit the property. This function does not
  ;; evaluate the property, but merely determines its type. The return value is one
  ;; of the symbols returned by the variant funciton of the describe package.
  (prop-type (prop) (-> symbol? symbol?)
             (define val (? prop self))
             (cond
               [(object? val) val]
               [else
                (string->symbol
                 (regexp-replace #rx"^struct:"
                                 (symbol->string (vector-ref (struct->vector val) 0))
                                 ""))]))

  ;; show: [flag] ->|
  ;; flag: (or/c #f '+kinds '+all)
  ;; Displays the defined definition of self object. Flag options are:
  ;;   +kinds - adds those objects from self kinds list to the display.
  ;;   +all    - displays all kinds in self kind-order list.  
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
        (define order 
          (case flag
            [(+kinds) (cons self (@ get-kinds-list self))]
            [(+mods) (cons self (@ modifies self))]
            [(+all) kind-order]
            [else (list self)]))        
        (unless (eq? flag 'chs)            
          (for ([obj order])
            (printf "(% ~a" obj)
            (hash-for-each (object-properties obj)
                           (λ (k v) (printf "~%\t(~a ~a)" k
                                            (cond
                                              [(and (number? v)
                                                    (inexact? v))                                                                                          
                                               (~r v
                                                   #:sign sign
                                                   #:precision precision
                                                   #:notation notation
                                                   #:format-exponent format-exponent)]
                                              [else v])))
                           symbol<?)
            [printf ")~%"]))
        (when (@ template-object? self)
          (printf "~%~a ~a template requirements:" #\u2022 self)
          (for ([r (@ template-objreqs self)])
            (printf "~%\t(~a ~a)"
                    (objreq-propname r)
                    (objreq-value r)))
          (printf "~%")))

  ;; get-objreqs: -> list?
  ;; Returns a list of 2 elements:
  ;; - a list of properties required by interfaces, but missing from this
  ;;   object's definition/inheritance.
  ;; - a list of propertes required by interfaces
  ;; The elements of these lists are triples consisting of:
  ;; - propname
  ;; - interface property value
  ;; - interface name
  (get-objreqs () (-> any)
              (define (type obj)
                (cond
                  [(@ flags? obj 'μ-props) 'μ-props]
                  [(@ flags? obj 'ε-props) 'ε-props]
                  [else 'ι-props]))
            (define raw-ntfs
              (remove-duplicates
               (flatten
                (for/list ([o kind-order]
                           #:when (@ prop-defined o
                                     implements prop-def-directly))
                  (@ implements o)))))
            (define ~ntfs (filter (λ (v)
                                    (string-prefix? (symbol->string v)
                                                    "~"))
                                  raw-ntfs))
            (define +ntfs (map
                           (λ (v) (string->symbol
                                   (string-trim (symbol->string v)
                                                "~" #:left? #t)))
                           ~ntfs))
            (define ntfs (remove* (append ~ntfs +ntfs) raw-ntfs))            
            (define ι-props-required (make-hasheq))
            (define μ-props-required (make-hasheq))
            (define ε-props-required (make-hasheq))
            (for ([ntf ntfs])
              (for ([propname (remove*
                               '(implements flags construct kinds)
                               (@ get-prop-list ntf))]) 
                (define propval (? propname ntf))
                (define req (objreq (type ntf)
                                    ntf propname propval (procedure? propval) #f))
                (define hsh
                  (cond
                    [(eq? (objreq-type req) 'μ-props) μ-props-required]
                    [(eq? (objreq-type req) 'ε-props) ε-props-required]
                    [else ι-props-required]))
                ;; Load keys in ntf order
                (unless (hash-ref hsh propname #f)
                  (hash-set! hsh propname req))))
            (define ι-props-missing
              (for/fold ([acc empty])
                        ([(propname req) ι-props-required])
                (cond
                  [(false? (@ prop-defined self propname prop-def-any))
                   (set-objreq-undefined?! req #t)
                   (values (cons req acc))]
                  [else
                   (define ntf-val (objreq-value req))
                   (define ntf-val-proc? (objreq-proc? req))
                   (define self-val (@ propname self))                   
                   (cond
                     [(and ntf-val-proc?
                           (procedure-arity-includes? ntf-val 1)
                           (ntf-val self-val))
                      (values acc)]
                     [ntf-val-proc?
                      (values (cons req acc))]
                     [(equal? ntf-val self-val)
                      (values acc)]
                     [else (values (cons req acc))])])))
            (define μ-props-missing
              (for/fold ([acc empty])
                        ([(propname req) μ-props-required])
                (cond
                  [(false? (@ prop-defined self propname prop-def-directly))
                   (values (cons req acc))]
                  [else (values acc)])))
            (define ε-props-present
              (for/fold ([acc empty])
                        ([(propname req) ε-props-required])
                (cond
                  [(false? (@ prop-defined self propname prop-def-directly))
                   (values acc)]
                  [else (values (cons req acc))])))
            (list ι-props-missing
                  (hash-values ι-props-required)
                  μ-props-missing
                  (hash-values μ-props-required)
                  ε-props-present
                  (hash-values ε-props-required)))

  ;; template-object?: -> boolean?
  ;; Returns true if this object satisfies the requirements for being a template.
  ;; Otherwise returns false.
  (template-object? () (-> boolean?)
              (and (@ flags? self immutable no-assert)
                   (not (empty? (first (@ get-objreqs self))))))

  ;; characteristics-template?: -> boolean?
  ;; Returns true if the object is a characteristics-template;
  ;; otherwise returns false.
  (characteristics-template? () (-> boolean?) #f)

  ;; template-objreqs: -> list?
  ;; If the object is a template it returns a list of missing objreqs that
  ;; must be supplied by any object deriving from this object. If the object
  ;; is not a template, then an empty list is returned. 
  (template-objreqs () (-> list?)
                    (cond
                      [(and @ flags? self immutable no-assert)
                       (first (@ get-objreqs self))]
                      [else empty]))
  
  ;; ε-props-assert :=>|
  ;; Objects that implement ε-propsobjects must NOT define the ε-propsproperties.
  (ε-props-assert () (-> any)
           (define reqs (fifth (@ get-objreqs self)))
           (unless (empty? reqs)
            (define req (first reqs))
            (raise-user-error
             (format "~a must not define ε-props~a property ~a"
                     self
                     (objreq-objname req)
                     (objreq-propname req))))           )
  
  ;; ι-props-assert: =>|
  ;; Enforces the interfaces this object implements. If the
  ;; kind does not implement a property indicated by one of
  ;; its interfaces an error is thrown. By default this is only
  ;; enforced when the kind is constructed.
  (ι-props-assert () (-> any)
          (define (get-objname o)
            (cond
              [(anonymous-object? o)
               (string-append (symbol->string o) " "
                              (format "~a" (@ kinds o)))]
              [o]))
          (define reqs (first (@ get-objreqs self)))
          (unless (empty? reqs)
            (define req (first reqs))
            (raise-user-error
             (if (objreq-undefined? req)
                 (format "~a does not implement ~a ι-props property (? ~a ~a) -> ~a."
                         (get-objname self)
                         (objreq-objname req)
                         (objreq-propname req)
                         self
                         (objreq-value req))
                 (format "~a does not implement ~a ι-props property ~a ->:~%\tExpected: ~a~%\tActual: ~a"
                         (get-objname self)
                         (objreq-objname req)
                         (objreq-propname req)                         
                         (objreq-value req)
                         (? (objreq-propname req) self))))))
  
  ;; μ-props-assert!: =>|
  ;; Enforces the μ-props this object dimplements. Adds μ-props properties
  ;; to this object when it doesn't directly-define them. The order of 
  ;; μ-props takes precedence.
  (μ-props-assert! () (-> any)
           (define reqs (third (@ get-objreqs self)))
           (for ([req reqs])
             (! (objreq-propname req) self (objreq-value req))))

  ;; modifies: => list?
  ;; Produces a list of objects modified by this object.
  ;; If the object hasn't been modified the list is empty. 
  (modifies () (-> any)
            (for/list ([kind (rest kind-order)]
                       #:break (not (string-prefix? (symbol->string kind) "mod#")))
              kind))

  ;; inherits-kind: => list?
  ;; Produces a list of objects inheriting from this object,
  ;; or an empty list if there are none.
  (inherits-kind () (-> any)
                 (define (loop names acc)
                   (cond
                     [(empty? names) (reverse acc)]
                     [else
                      (define kinds (@ directly-inherits-kind (first names)))
                      (loop (append (rest names) kinds) (append acc kinds))]))
                 (loop (list self) empty))

  ;; inherits-kind? args => boolean?
  ;; Returns true if all the args inherit from this object; false otherwise.
  (inherits-kind? args (->* () #:rest (listof object?) any)
                  (define kinds (@ inherits-kind self))
                  (define result
                    (cond
                      [(empty? args) #f]
                      [else
                       (for/and ([obj args])
                         (member obj kinds))]))
                  (not (false? result)))

  ;; directly-inherits-kind: => list?
  ;; Produces a list of objects whose kinds property contains this object,
  ;; or an empty list if there are none.
  (directly-inherits-kind () (-> any)
                          (for/fold ([acc empty])
                                    ([obj (remove self object-names)])
                            (define kinds (@ get-kinds-list obj))
                            (values(if (member self kinds)
                                       (cons obj acc)
                                       acc))))
  
  ;; directly-inherits-kind? args => boolean?
  ;; Returns true if all the args directly inherit from this object; false otherwise.
  (directly-inherits-kind? args (->* () #:rest (listof object?) any)
                           (define kinds (@ directly-inherits-kind self))
                           (define result
                             (cond
                               [(empty? args) #f]
                               [else
                                (for/and ([obj args])
                                  (member obj kinds))]))
                           (not (false? result)))
    
  ;; Creates a new object that is an identical copy of this object.
  ;; The new object will have the same kinds as the original, and
  ;; the identical set of properties defined in the original.
  ;; No constructor is called in creating the new object, since the
  ;; object is explicitly initialized by this method to have the exact
  ;; property values of the original.
  ;;
  ;; The clone is a "shallow" copy of the original, which means that the
  ;; clone refers to all of the same objects as the original. For example,
  ;;if a property of the original points to a vector, the corresponding 
  ;; property of the clone points to the same vector, not a copy of the vector.
  (create-clone () (-> object?)
                (make-object #f
                  (hash->list
                   (object-properties self))
                  #:construct? #f))
  (create-clone/ε ((objname #f)) (->* () ((or/c #f (and/c symbol? (not/c object?)))) any)
                  (define h0 (object-properties self))
                  (define h (make-hasheq (hash->list h0)))
                  (define εs (map (λ (r) (objreq-propname r))
                                  (fifth (@ get-objreqs self))))
                  (for ([p εs])
                    (hash-remove! h p))
                  (make-object objname
                  (hash->list h)
                  #:construct? #t))

  ;; Creates a new instance of the target object. This method's arguments
  ;; are passed directly to the constructor, if any, of the new object;
  ;; this method doesn't make any other use of the arguments. The method
  ;; creates the object, invokes the new object's constructor, then returns
  ;; the new object.
  (create-instance args (->* () #:rest list? object?)
                   (define result
                     (make-object #f
                       (hash->list
                        (object-properties self))
                       #:construct? #f))
                   (apply @ construct result args)
                   result)

  ;; Creates a new instance based on multiple kinds. This is a "static"
  ;; (kind-level) method, so you can call it directly on kind. With no
  ;; arguments, this simply creates a basic kind instance; this is
  ;; equivalent to the create-instance method with no arguments.
  ;;
  ;; The arguments give the kinds, in "dominance" order. The kinds
  ;; appear in the argument list in the same order in which they'd
  ;; appear in an object definition: the first argument corresponds
  ;; to the leftmost kind in an ordinary object definition. Each
  ;; argument is either a kind or a list. If an argument is a list,
  ;; the first element of the list must be a kind, and the remainder
  ;; of the elements are the arguments to pass to that kind's constructor.
  ;; If an argument is simply a kind (not a list), then the constructor for
  ;; this kind is not invoked at all.
  (create-instance-of args
                      (->* () #:rest list?
                           #:pre/desc
                           (if (self? Object)
                               #t
                               "method must be called on Object.")
                           object?)
                      (define result
                        (make-object #f (list (cons 'kinds (list defining-obj)))
                          #:construct? #f))
                      (define kinds (map (λ (v) (cond
                                                  [(list? v) (car v)]
                                                  [else v]))
                                         args))
                      (cond
                        [(empty? args)
                         (parameterize ([current-construct-objname objname])
                           ;; Enforce any μ-props interfaces this object implements
                           (@ μ-props-assert! objname)
                           (@ construct result))]
                        [else
                         (define kinds (map (λ (v) (if (list? v) (car v) v)) args))
                         (define kind/args (filter list? args))
                         (@ set-kinds-list! result kinds)
                         (for ([v kind/args])
                           (apply @ construct (car v) (cdr v)))])
                      result)
  
  ;; Gets the procedure for one of the object's methods.
  (get-method (prop) (-> symbol? (or/c procedure? undefined?))
              (define result (? prop self #:when-undefined #f))
              (if (procedure? result) result undefined))
  
  ;; Assigns the procedure proc as a method of the object, using the property prop.
  (set-method! (prop proc #:contract (cspec #f))
               (->* (symbol? procedure?) (#:contract (or/c #f contract?)) any)
               (! prop self (if (false? cspec)
                                proc
                                (contract cspec proc
                                          (format "~a ~a" self prop)
                                          (current-contract-region) prop #'prop))))
  
  (set-kinds-list! (objs) (-> (listof object?) any)
                   (! kinds self objs)))

;; object->list objname => list?
;;; Returns a list consisting of objname followed by
;; the object's directly-defined propname/value pairs.
(define (object->list objname)
  (cons objname (sort (hash->list (hash-ref objects objname))
                      symbol<?
                      #:key car)))

;; with-objects: kinds =>|
;; A macro for parameterizing the current-objects,
;; current-default-kind, and current-debug, restoring
;; their values once the context of the macro has terminated.
;;
;; Filter objects by kinds and their inherited objects.
;;
;; Example:
;; (with-objects (A B) ...) will remove all objects except A
;; and B and any objects they inherit, directly or indirectly, from.
;;
;; (with-objects () ...) will use all objects. 
(define-syntax (with-objects stx)
  (syntax-parse stx
    [(_ () body ...)
     #'(parameterize ([current-objects objects]) body ...)]
    [(_ (kinds ...) body ...)
     #'(parameterize ([current-objects (objects-copy #:filter-not? #f
                                                     kinds ...)]
                      [current-default-kind default-kind]
                      [current-debug debug])
         body ...)]))

;; without-objects: kinds =>|
;; A macro for parameterizing the current-objects,
;; current-default-kind, and current-debug, restoring
;; their values once the context of the macro has terminated.
;;
;; Filter-not objects by kinds and their modified and inheriting objects.
;;
;; Example:
;; (without-objects (A B)  ...) will remove A and B and their modifications,
;; as well as any objects inheriting from A or B from the objects database.
;;
;; (without-objects () ...) will use all objects.
(define-syntax (without-objects stx)
  (syntax-parse stx
    [(_ (kinds ...) body ...)
     #'(parameterize ([current-objects (objects-copy #:filter-not? #t
                                                     kinds ...)]
                      [current-default-kind default-kind]
                      [current-debug debug])
         body ...)]))


(module+ test
  
  (define-syntax (output->string stx)
    (syntax-parse stx
      [(_ body:expr ...) #'(with-output-to-string (thunk body ...))]))

  (test-case "nested object tests"
             (parameterize ([current-objects objects]
                            [current-default-kind Object]
                            [current-debug #f])
               (% A (p0 (%)))
               (check-equal? (@ lexical-parent (@ p0 A)) A)))
  (test-case "inerited/delegated tests"
             (parameterize ([current-objects objects]
                            [current-default-kind Object]
                            [current-debug #f])
               (% A (p0 () (-> any) 12))
               (% B (kinds A)
                 (p0 () (-> any) (+ (@ p1 self) (inherited)))
                 (p1 10))
               (% C
                 (p0 () (-> any) (+ (@ p1 self) (delegated A)))
                 (p1 42))
               (check-equal? (@ p0 B) 22)
               (check-equal? (@ p0 C) 54)
               (check-equal? (@ p0 (@ create-instance-of Object B A)) 22)))
  (test-case "inherited/delegated 2 tests"
             (parameterize ([current-objects objects]
                            [current-debug #f])
               (% Z)
               (% A (p0 () (-> any) 12))
               (% B (kinds A)
                 (p0 () (-> any) (+ (@ p1 self) (inherited)))
                 (p1 10))
               (% C (kinds B A)
                 (p0 () (-> any) (+ (@ p1 self) (inherited #:objname A)))
                 (p1 42))
               (check-equal? (@ p0 B) 22)
               (check-equal? (@ p0 C) 54)
               (check-equal? (@ p0 (@ create-instance-of Object B A)) 22)))
  (test-case "kind-order tests"             
             (parameterize ([current-objects objects])
               (% Z (p1 10))
               (% A (kinds Z))
               (% B (kindts Z) (p1 20))
               (% C (kinds A B))
               (check-equal? (@ get-kind-order C)
                             '(C A B Z Object))))
  (test-case "? tests"
             (parameterize ([current-objects objects]
                            [current-debug #f])
               (% A
                 (p0 3)
                 (p4 () (-> symbol?) 'bar))
               (% B (kinds A)
                 (p1 6)
                 (p2 8))
               (check-equal? (? p0 A) 3)
               (check-equal? (? p0 B) 3)
               (check-true (procedure? (? p4 B)))))
  (test-case "! tests"
             (parameterize ([current-objects objects]
                            [current-debug #f])
               (% A
                 (p0 3)
                 (p4 () (-> symbol?) 'bar))
               (% B (kinds A)
                 (p1 6)
                 (p2 8))
               (! p0 A 5)
               (check-equal? (? p0 A) 5)
               (! p0 A (λ () 'foo))
               (check-true (procedure? (? p0 A)))
               (! kinds B '(Object))
               (check-equal? (@ get-kind-order B) '(B Object))))
  (test-case "@ tests"
             (parameterize ([current-objects objects]
                            [current-debug #f])
               (% A
                 (p0 3)
                 (p4 () (-> symbol?) 'bar))
               (% B (kinds A)
                 (p1 6)
                 (p2 8))
               (check-equal? (@ p0 A) 3)
               (check-equal? (@ p0 B) 3)
               (check-equal? (@ p4 B) bar)))
  (test-case "inherited tests"
             (parameterize ([current-objects objects]
                            [current-debug #f])
               (% A
                 (p0 3)
                 (p4 () (-> number?) (+ 7 (@ p0 self))))
               (% B (kinds A)
                 (p1 6)
                 (p2 8)
                 (p4 ()
                     (-> number?)
                     (+ (@ p0 A) (inherited))))
               (check-equal? (@ p4 B) 13)               ))
  (test-case "delegated tests"
             (parameterize ([current-objects objects]
                            [current-debug #f])
               (% A
                 (p0 3)
                 (p4 ()
                     (-> number?)
                     (+ 7 (@ p0 self))))
               (% B (kinds A)
                 (p1 6)
                 (p2 8)
                 (p4 ()
                     (-> number?)
                     (+ (@ p0 A) (inherited))))
               (% C
                 (p0 20)
                 (p1 6)
                 (p2 8)
                 (p4 ()
                     (-> number?)
                     (+ (@ p0 A) (delegated B))))
               (check-equal? (@ p4 C) 33)               ))
  (test-case "flags tests"
             (parameterize ([current-objects objects]
                            [current-debug #f])
               (% A (flags x y z))
               (% B (kinds A))               
               (check-true (@ flags? A x))
               (check-false (@ flags? B x))
               (check-false (@ flags? A w x z))
               (check-true (@ flags? A w x z #:all #f))))
  (test-case "modify object tests"
             (parameterize ([current-objects objects]
                            [current-debug #f])
               (% Z (p0 number?))
               (% A (p0 0))
               (%+ A (p1 10))
               (check-equal? (@ prop-defined A p0 prop-def-get-kind)
                             (car (@ kinds A)))
               (%+ A (replace (p0 20)))
               (check-equal? (@ prop-defined A p0 prop-def-get-kind)
                             A)
               (check-equal? (@ p0 (car (@ kinds A)))
                             undefined)))
  (test-case "modify object w/rollback tests"
             (parameterize ([current-objects objects]
                            [current-debug #f])
               (% Z (p0 number?))
               (% A (p0 0))
               (%+ A (p0 10))
               (%+ A (p0 100))
               (check-exn exn:fail:user?
                          (thunk (%+ A (implements Z)
                                                (p0 #t))))
               (check-equal? (@ p0 A) 100)))
  (test-case "replace object tests"
             (parameterize ([current-objects objects]
                            [current-debug #f])
               (% A (p0 0))
               (check-equal? (@ p0 A) 0)
               (%= A (p0 10))
               (check-equal? (@ p0 A) 10)))
  (test-case "remove object tests"
             (parameterize ([current-objects objects]
                            [current-debug #f])
               (% A)
               (% B (kinds A))
               (check-equal? (list->set (%- A)) (set A B))))
  (test-case "implements interfaces tests"
             (parameterize ([current-objects objects]
                            [current-debug #f])
               (% A (flags x y z)
                 (p0 number?)
                 (p1 1)
                 (p2 2))               
               (check-exn exn:fail:user?
                          (thunk (% B (implements A))))
               (check-equal? B
                             (% B (implements A)
                               (p0 0)
                               (p1 1)
                               (p2 2)))
               (check-exn exn:fail?
                          (thunk (%+ (% C)
                                                (implements A)
                                                (p1 1))))))
  (test-case "implements μ-props tests"
             (parameterize ([current-objects objects]
                            [current-debug #f])
               (% A (flags μ-props)
                 (p0 0))
               (% B (flags μ-props)
                 (implements A)
                 (p1 1))
               (% C (implements A))
               (%+ C (implements B))
               (check-equal? (list->set
                              (@ get-prop-list B #:filter #t))
                             (set p0 p1))
               (check-equal? (list->set
                              (@ get-prop-list C #:filter #t))
                             (set p0 p1))))
  (test-case "prop-not-defined tests"
             (parameterize ([current-objects objects]
                            [current-debug #f])
               (% A (flags prop-not-defined))
               (% B (flags prop-not-defined)
                 (prop-not-defined args (->* () #:rest list? any)
                                   args))
               (% C (kinds B) (flags prop-not-defined))
               (% D (kinds B))
               (check-equal? undefined (@ p0 A 1 2 3))
               (check-equal? '(p0 1 2 3) (@ p0 B 1 2 3))
               (check-equal? '(p0 1 2 3) (@ p0 C 1 2 3))
               (check-equal? undefined (@ p0 D 1 2 3)))))


;;==============================================================
;; 
;; This module defines an object that handles the parent, child,
;; sibling relationships within an Inform-style object tree. Also
;; defines an Inform-style object-loop
;;
(module* Nothing #f
  
  (provide object-loop Nothing?)
  
;; object-loop: (var [pred [acc]]) body0 body ... =>|
;; var: identifier?
;; pred: procedure? 
;; acc: identifier?
;; Iterates over all objects.
;; When pred is supplied the object is considered for selection
;; only when the procedure returns (not/c (or/c #f undefined?)).
;; When acc is supplied the body statements are only called ocne with the
;; list of accumulated objects; otherwise body stateemnts are called once
;; for each object satisfying proc. 
(define-syntax (object-loop stx)
  (syntax-parse stx 
    [(_ (var:id pred:expr acc:id) body0 body ...)
     #'(let ([acc (filter-not void? (for/list ([var (hash-keys (current-objects))])
                                      (when (let ([result ((λ (var) pred) var)])
                                              (cond
                                                [(false? result) #f]
                                                [(undefined? result) #f]
                                                [else #t])) var)))])
         (begin
           ((λ (acc) body0 body ...) acc)))]
    [(_ (var:id pred:expr) body0 body ...)
     #'(let ([vs (filter-not void? (for/list ([var (hash-keys (current-objects))])
                                     (when (let ([result ((λ (var) pred) var)])
                                             (cond
                                               [(false? result) #f]
                                               [(undefined? result) #f]
                                               [else #t])) var)))])
         (for ([var vs])
           ((λ (var) body0 body ...) var)))]
    [(_ (var:id) body0 body ...)
     #'(for ([var (hash-keys (current-objects))])
         ((λ (var) body0 var) var))]))
  
  ;; Nothing?: v => boolean?
  ;; Returns true if v is the Nothing object; otherwise returns false.
  (define (Nothing? v) (and (object? v) (eq? v Nothing)))

  (% ε-Nothing (flags ε-props)
    (sibling undefined)
    (child undefined))
  
  (% Nothing (flags immutable) (implements ε-Nothing)
    ;; construct: ->|
    ;; Initializes self object-tree properties then places self into the object-tree.
    (construct args
               (->* () #:rest list? any)
               (apply inherited args)
               (unless (object-ref self parent #f)
                 (object-set! self parent Nothing))
               (unless (object-ref self child #f)
                 (object-set! self child Nothing))
               (unless (object-ref self sibling #f)
                 (object-set! self sibling Nothing))
               ;; add the new object to the object tree
               (@ move-to self (? parent self #:when-undefined Nothing)))

    ;; in?: objname -> boolean?
    ;; Returns #t if objname is the parent of self;
    ;; Otherwise returns #f.
    (in? (objname)
         (-> object? boolean?)
         (cond
           [(eq? self objname) (if (Nothing? self) #t #f)]
           [else (eq? (? parent self #:when-undefined Nothing) objname)]))

    ;; is-in?: objname -> boolean?
    ;; objname: object?
    ;; Determines if self is in the sub-tree whose parent is objname,
    ;; and if so returns #t; otherwise returns #f.
    (is-in? (objname)
            (-> object? boolean?)
            (cond
              ;; when self is Nothing
              [(Nothing? self) (Nothing? objname)]
              ;; parent of self is objname
              [(eq? (? parent self) objname) #t]
              ;; call property for the parent
              [else (@ is-in? (? parent self) objname)]))

    ;; move-to: objname ->|
    ;; objname: object?
    ;; moves self to objname in the object-tree.
    (move-to (objname)
             (->i ([obj object?])
                  #:pre/desc (obj)
                  (cond [(self? obj) #t]
                        [(not (@ is-in? obj self)) #t]
                        [else (format "circular contents error: is-in? ~a ~a" obj
                                      self)])
                  (result () any/c))
           
             ;; prev-sibling: objname => object?
             ;; If the object has siblings (other than Nothing) it returns
             ;; the immediate youngest sibling. Otherwise 
             (define (prev-sibling begin (end self))
               (cond
                 ;; There is no previous
                 [(eq? begin end) Nothing]
                 [else
                  (define next (? sibling begin #:when-undefined Nothing))
                  (cond
                    ;; This object ends the chain, return the previous.
                    [(eq? next end) begin]
                    ;; End of the line, return the previous.
                    [(Nothing? next) begin]
                    [else (prev-sibling next end)])]))
             (cond
               ; do Nothing when moving an object to itself
               [(self? objname) (void)]
               ; ok to move the objects
               [else
                ;; --- remove from old parent ---
                ;;Get the old parent.
                (define p (? parent self))
                ;; Get the old parent's echild.
                (define c (? child p))
                (cond
                  [(eq? self c) ; make the child self's sibling
                   (object-set! p child (? sibling self #:when-undefined Nothing))]
                  [else
                   ;; Get the previous sibling.
                   (define s (prev-sibling c self))
                   (unless (Nothing? s)
                     (object-set! s sibling (? sibling self #:when-undefined
                                               Nothing)))])
                ;; --- add to new parent ---
                ;; Make its new parent's child the seibling of self.
                (object-set! self sibling
                             (? child objname #:when-undefined Nothing))
                ;; Make the new parent's child self.
                (object-set! objname child self)
                ;; Make objname the new parent of self.
                (object-set! self parent objname)]))

    ;; parents: [fn] [acc] => acc
    ;; fn: (or/c #f procedure?)
    ;; acc: list?
    ;; Accumulates a list by applying fn, if provided to each successive
    ;; parent of self until Nothing is reached. If fn is #f then acc is
    ;; the list of successive parents of the original object. 
    (parents ((fn #f) (acc empty))
             (->* () ((or/c #f procedure?) list?) any)
             (cond
               [(Nothing? self) acc]
               [else (define o (@ parent self))
                     (define v (if (false? fn) o (fn o)))
                     (@ parents o fn (cons v acc))]))
  
    ;; siblings: [fn] [acc] => acc
    ;; fn: (or/c #f procedure?)
    ;; acc: list?
    ;; Accumulates a list by applying fn, if provided to each successive
    ;; sibling of self until Nothing is reached. If fn is #f then acc is
    ;; the list of successive siblings of the original object. 
    (siblings ((fn #f) (acc empty))
              (->* () ((or/c #f procedure?) list?) any)
              (cond
                [(Nothing? self) acc]
                [else (define o (@ sibling self))
                      (define v (if (false? fn) o (fn o)))
                      (@ siblings o fn (cons v acc))]))
  
    ;; children: [fn] [acc] => acc
    ;; fn: (or/c #f procedure?)
    ;; acc: list?
    ;; Accumulates a list by applying fn, if provided to each successive
    ;; child of self until Nothing is reached. If fn is #f then acc is
    ;; the list of successive children of the original object. 
    (children ((fn #f) (acc #f))
              (->* () ((or/c #f procedure?) (or/c #f list?)) any)
              (cond
                [(and (Nothing? self) acc) acc]
                [else (define o (@ child self))
                      (define v (if (false? fn) o (fn o)))
                      (@ children o fn (cons v (if (false? acc) '() acc)))]))
  
    ;; contents: objname => (or () listof object?)
    ;; Returns a list of objects that are the "contents" of
    ;; this object.
    ;; If the object has no contents, returns an empty list.
    (contents () (-> any)
              (define (loop objname acc)
                (cond
                  [(Nothing? objname) (reverse acc)]
                  [else
                   (loop (? sibling objname #:when-undefined Nothing)
                         (cons objname acc))]))
              (reverse (loop (? child self #:when-undefined nothiing) '()))))

  (default-kind! Nothing)

  ;; Testing for Nothing.
  (module+ test
  
    (define-syntax (output->string stx)
      (syntax-parse stx
        [(_ body:expr ...) #'(with-output-to-string (thunk body ...))]))

    
    (test-case "move-to tests"
               (parameterize ([current-objects objects]
                              [current-default-kind Nothing])
                 (% meadow (parent Nothing))
                 (% player (parent meadow))
                 (% stone (parent player))
                 (% torch (parent player))
                 (% battery (parent torch))
                 (% bottle (parent player))
                 (% sceptre (parent player))
                 (% mailbox (parent meadow))
                 (% note (parent mailbox))
                 (check-equal? (length (@ contents player)) 4)
                 (@ move-to torch mailbox)
                 (check-equal? (length (@ contents player)) 3)
                 (check-equal? (? sibling torch) note)
                 (check-equal? (? sibling bottle) stone)
                 (check-equal? (object-loop (x (@ is-in? x Nothing) y)
                                            (apply set y))
                               (set mailbox torch meadow note Nothing battery sceptre
                                    player bottle stone))
                 (check-equal? (object-loop (x (@ in? x player) y)
                                            (apply set y))
                               (set bottle sceptre stone))
                 (object-loop (x (@ in? x player)) (@ move-to x mailbox))
                 (check-equal? (object-loop (x (@ in? x player) y) (length y))
                               0)
                 (check-equal? (object-loop (x (@ in? x mailbox) y) (apply set y))
                               (set bottle note torch sceptre stone))
                 (check-equal? (object-loop (x (@ in? x mailbox) y) (length y)) 5)))    

    (test-case "move-to* tests"
               (parameterize ([current-objects objects]
                              [current-default-kind Nothing]
                              [current-debug #f])
                 (% X)
                 (% Y)
                 (% Z)
                 (check-equal? (@ contents Nothing) '(Z Y X))
                 (@ move-to Z Y)
                 (check-equal? (@ contents Nothing) '(Y X))
                 (check-equal? (? parent Z) Y)
                 (check-equal? (? sibling Z) Nothing)
                 (check-equal? (? child Y) Z)
                 (@ move-to Z Nothing)
                 (@ move-to Y Z)
                 (check-equal? (@ contents Nothing) '(Z X))
                 (check-equal? (? sibling Y) Nothing)))
    (test-case "parents/siblings/children/contents tests"
               (parameterize ([current-objects objects]
                              [current-default-kind Nothing]
                              [current-debug #f])
                 (% A)
                 (% B (parent A))
                 (% C (parent B))
                 (% D (parent C))
                 (% E (parent D))
                 (% F (parent D))
                 (% G (parent D))
                 (% H (parent D))
                 (check-equal? (@ parents D)
                               '(Nothing A B C))
                 (check-equal? (@ siblings H)
                               '(Nothing E F G))
                 (check-equal? (@ contents D)
                               '(H G F E))
                 (check-equal? (@ children Nothing)
                               '(Nothing H D C B A))))))


;;=====================================================================
;; 
;; This module defines a kind for rules. 
;; When the rule receives an exec message its predicate is run, if true
;; the rule's proc is executed. The proc can return 3 states:
;;   * #t indicates the rule handled the action and was successful
;;   * #f indicates the rule handled the action and was unsuccessful
;;
;; In those cases no further processing is done.
;; 
;;   * any other value indicates the rule handled the action and processing continues.
;;
(module* Rule #f

  (provide rule-chain
           raise-rule-value)

  ;; rule-value is only used internally in the raise and handlers.
(struct rule-value (value objname) #:transparent)
  
;; rule-chain: The rule-chain pseudo-variable provides a reference to
;; the objects whose exec method was originally invoked to reach the 
;; current method. 
(define/contract current-rule-chain
  (parameter/c (or/c empty (listof object?)))
  (make-parameter empty))
(define-syntax rule-chain
  (λ (stx)
    (syntax-parse stx [rule-chain:id #'(current-rule-chain)])))
  
  (define/contract (raise-rule-value v (b (cond
                                       [(empty? (cdr rule-chain)) (car rule-chain)]
                                       [else (cadr rule-chain)])))
    (->* (any/c) ((λ (v) (member v (cdr rule-chain))))
         any)
    (raise (rule-value v b)))
  
  (% Rule
  
    ;; Indicates whether the rule is considered active or not. While an inactive
    ;; rule can be called, it is automatically filtered out of rules list processing.
    (active? #t)

    ;; value represents the result of exec rule processing based on
    ;; the rule's pred/proc and rules processing. 
    (value undefined)

    ;; rulebook will be processed if the rule's proc result is not a boolean.
    (rulebook empty)

    ;; By default pred returns the active? state of the object.
    (pred args (->* () #:rest (listof any/c) any) (? active? self))

    ;; By default proc returns undefined, which will continue processing
    ;; the object's rules list. 
    (proc args (->* () #:rest (listof any/c) any) undefined)

    ;; The main method of a rule. This is the method that should be
    ;; called for processing rules. It first calls the pred property,
    ;; continuing if true, terminating if false. Next the proc property is
    ;; called. If the result is a boolean processing halts; Otherwise all
    ;; active rules are then processed sequentially in like manner. The
    ;; final result is stored in the rule's value property and returned.
  (exec args (->* () #:rest list? any)
        (parameterize ([current-rule-chain (cons self rule-chain)])
          (define pred-result (apply @ pred self args))
          (cond
            [(false? pred-result)
             (unless (@ flags? self immutable) (! value self #f))
             #f]
            [else
             (with-handlers ([(not/c exn?)
                              (λ (v)
                                (when (and (not (@ flags? self immutable))
                                           (eq? self (first rule-chain)))
                                  (! value self (if (rule-value? v)
                                                    (rule-value-value v)
                                                    v)))
                                (cond
                                  ;; rule-value-objname matches object
                                  [(and (rule-value? v)
                                        (eq? self (rule-value-objname v)))
                                   (rule-value-value v)]

                                  ;; value at top of rule-chain
                                  [(and (not (rule-value? v))
                                        (eq? (last rule-chain) self)) v]

                                  ;; default: throw the value up the rule-chain
                                  [else (raise v)]))])
               (define result
                 (last
                (cons
                 (apply @ proc self args)
                 (map (λ (r) (apply @ exec r args))
                      (@ rulebook self #:when-undefined empty)))))
               (unless (@ flags? self immutable)
                 (! value self result))
               result)]))))

  (default-kind! Rule))


;;================================================================
;;
;; This module implements Characteristics object.
;;
(module* Characteristics #f
  
  (% Characteristics (flags immutable)

     (construct args (->* () #:rest list? any)
                (when (anonymous-object? self)
                  (@ flags! self immutable))
                (apply inherited args)                            
                (cond
                  [(@ template-object? self) (void)]
                  [(@ flags? self immutable)
                   (@ ι-props-assert self)
                   (define-values (ιs μs) (apply values (@ characteristics self #:prop+val? #t)))
                   ;; Sets the μ-props of this object to their value
                   (for ([property μs])
                     (! (car property) self (cdr property)))]))

     (characteristics (#:prop+val? (prop+val? #f))
                      (->* () (#:prop+val? boolean?) list)
                      (define ιs (sort (map objreq-propname (second (@ get-objreqs self)))
                                       symbol<?))
                      (define μs (sort (map objreq-propname (fourth (@ get-objreqs self)))
                                       symbol<?))
                      (cond
                        [(false? prop+val?)
                         (append (list ιs) (list μs))]
                        [else
                         (if (@ characteristics-template? self)
                             (list (for/list ([propname ιs])
                                     (cons propname undefined))
                                   (for/list ([propname μs])
                                     (cons propname undefined)))
                             (list (for/list ([propname ιs])
                                     (cons propname (@ propname self)))
                                   (for/list ([propname μs])
                                     (cons propname (@ propname self)))))]))
     
     ;; characteristics-template?: -> boolean?
     ;; A template-object derived from the Characteristics object
     ;; that implements μ-props.
     ;; Returns true if the object is a characteristics-template;
     ;; otherwise returns false.
     (characteristics-template? () (-> boolean?)
                                (and (@ template-object? self)
                                     (not (empty? (fourth (@ get-objreqs self))))))
     
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
           (define cs (@ characteristics self
                         #:prop+val? #t
                         #:when-undefined '()))
           (cond
             [(or (empty? cs) (@ template-object? self))
              (printf "~% ~a ~a has no characteristics." #\u2022 self)]
             [else              
              (printf "~% ~a ~a characteristics requirements:" #\u2022 self)              
              (for ([property (first cs)])
                (define v (cdr property))
                (printf "~%\t(~a ~a)" (car property)
                        (cond
                          [(and (number? v)
                                (inexact? v))                                              
                           (~r v
                               #:sign sign
                               #:precision precision
                               #:notation notation
                               #:format-exponent format-exponent)]
                          [else v])))
              (printf "~% ~a ~a characteristics:" #\u2022 self)              
              (for ([property (second cs)])
                (define v (cdr property))
                (printf "~%\t(~a ~a)" (car property)
                        (cond
                          [(and (number? v)
                                (inexact? v))                                              
                           (~r v
                               #:sign sign
                               #:precision precision
                               #:notation notation
                               #:format-exponent format-exponent)]
                          [else v])))])
           (printf "~%"))))


;;===============================================================
;;
;; This module redirects undefined applications to @. This allows
;; an object property to be evaluated such as lA) instead of
;; (@ show A).
;;
(module* @app #f

  (provide (rename-out [sym-app #%app])
           current-@app
           @app)

  
  ;; current-@app: The @app parameter provides a means of setting 
  ;; the default procedure for redirection when an the application is
  ;; not a procedure. If false? then this results in an error, which is
  ;; the equivalent of not requiring this submodule. 
  (define/contract current-@app
    (parameter/c (or/c #f procedure?))
    (make-parameter @))
  ;; @app is a macro that provides the value of current-@app.
  (define-syntax @app
    (λ (stx)
      (syntax-parse stx [@app:id #'(current-@app)])))
  
  (define-syntax (sym-app stx)
    (syntax-case stx ()
      [(_ op arg ...)
       (quasisyntax/loc stx
         (let ([o op])
           (if (or (procedure? o) (false? @app))
               #,(syntax/loc stx (#%app o arg ...))
               #,(syntax/loc stx (#%app @app o arg ...)))))])))


;;===============================================================
;;
;; This module redirects the object, modify-object, %=
;; and %- macros and functions to the %, %+, %=, and %-
;; an object property to be evaluated such as (show A) instead of
;; shorthand forms.
;;
(module* %object #f
  (provide (rename-out [% object]
                       [%* anonymous]                       
                       [%= replace-object]
                       [%+ modify-object]
                       [%- %-])))

(module* scribble #f
  (provide (rename-out [@ $])))
