#lang racket

;;;
;;; Conspiracy Universe Rules
;;;

(provide (struct-out state-event)
         (struct-out state-tick-event)
         (struct-out state-key-event)
         (struct-out state-mouse-event)
         (struct-out state-button-event)
         tick-handler
         key-handler
         mouse-handler
         print-evt
         (all-from-out "object.rkt"))

(require racket/undefined
         2htdp/universe
         anaphoric
         "object.rkt"
         (submod "object.rkt" Rule))

(struct state-event                      (state))
(struct state-tick-event   state-event   ())
(struct state-key-event    state-event   (key))
(struct state-mouse-event  state-event   (x y evt))
(struct state-button-event state-event   (ctn btn))


(define (print-evt evt)
  (cond
    
    #;[(state-tick-event? evt)
     (printf "~a " self)
     (printf "state-tick-event:~%\tstate=~a~%"
             (state-event-state evt))]
    #;[(state-key-event? evt)
     (printf "state-key-event:~%\tke=~a~%\tstate=~a~%"
             (state-key-event-key evt)
             (state-event-state evt))]
    #;[(state-mouse-event? evt)
     (printf "state-mouse-event:~%\tx=~a~%\ty=~a~%\tevt=~a~%\tstate=~a~%"
             (state-mouse-event-x evt)
             (state-mouse-event-y evt)
             (state-mouse-event-evt evt)
             (state-event-state evt))]
    [(state-button-event? evt)
     (printf "state-button-event:~%\tctn=~a~%\tbtn=~a~%\tstate=~a~%"
             (state-button-event-ctn evt)
             (state-button-event-btn evt)
             (state-event-state evt))]))

;; A base trait for rules. 
;; When the rule receives an exec message its predicate is run, if true
;; the rule's proc is executed. The proc can return 3 states:
;; * #t indicates the rule handled the action and was successful
;; * #f indicates the rule handled the action and was unsuccessful
;; In those cases no further processing is done.
;; * any other value indicates the rule handled the action and processing continues.
(% Universe-Rule (kinds Rule)
  (accepting state-event?)
  (pred (evt) (-> state-event? any) #t)
  (proc (evt) (-> state-event? any) undefined)
  (exec (evt) (-> state-event? any)
        (print-evt evt)
        (cond
          [(false? ((? accepting self) evt)) (! value self #f)]
          [else
           (inherited evt)])
        (print-evt evt)
        (state-event-state evt)))


;;;=======================================================================================
;;; Rules for handling the passage of time.
;;;=======================================================================================

;; A Tick-Rule requires a state-tick-event for both pred and proc.
;; Returns a world state. 
(% Tick-Rule (kinds Universe-Rule)
  (accepting state-tick-event?)
  (pred (evt) (-> state-tick-event? boolean?) (inherited evt))
  (proc (evt) (-> state-tick-event? any) (void)))

;; Tick-Rules is called by tick-handler with
;; a state-tick-event and world-state. 
(% Tick-Rules (kinds Universe-Rule))

;; tick-handler should be part of big-bang's on-tick clause. 
(define (tick-handler ws)
  (@ exec Tick-Rules (state-tick-event ws)))


;;;======================================================================================
;;; Rules for handling keyboard input
;;;======================================================================================

(% Key-Rule (kinds Universe-Rule)
  (accepting state-key-event?)
  (pred (evt) (-> state-key-event? boolean?) (inherited evt))
  (proc (evt) (-> state-key-event? any) (void)))

(% Key-Rules (kinds Universe-Rule))

;; key-handler should be part of big-bang's on-key clause.
(define/contract (key-handler ws ke) (-> any/c key-event? any)
  (@ exec Key-Rules (state-key-event ws ke)))


;;;======================================================================================
;;; Rules for handling mouse input and klicker button up-actions.
;;;======================================================================================

(% Mouse-Rule (kinds Universe-Rule)
  (accepting state-mouse-event?)
  (pred (evt) (-> state-mouse-event? boolean?) (inherited evt))
  (proc (evt) (-> state-mouse-event? any) (void)))

(% Mouse-Rules (kinds Universe-Rule))

(% Button-Rule (kinds Universe-Rule)
  (accepting state-button-event?)
  (ctn-name #f)
  (btn-name #f)
  (btn-name-eq? #t)
  (pred (evt) (-> state-button-event? boolean?)
        (and-let
         [ctns (? containers button-rules)]
         [rule-ctn-name (? ctn-name self)]
         [rule-btn-name (? btn-name self)]
         [not (xor (? btn-name-eq? self)
                   (and (eq? rule-ctn-name
                             (container-name (state-button-event-ctn evt)))
                        (eq? rule-btn-name
                             (button-name (state-button-event-btn evt)))))]))
  (proc (evt) (-> state-button-event? any) (void)))

(% Button-Rules (kinds Universe-Rule)
  (containers '()))
 
(define/contract (mouse-handler ws x y evt)
  (-> any/c integer? integer?
      (or/c "button-down" "button-up" "drag" "move" "enter" "leave")
      any)
  (define result (select-container/button (@ containers button-rules) ws x y evt))
  (cond
    [(false? result) (@ exec Mouse-Rules (state-mouse-event ws x y evt))]
    [else
     (@ exec Button-Rules (state-button-event ws
                                              (first result)
                                              (second result)))])
  ws)
