#lang scribble/manual

@title{Rule Object}

The Rule submodule of Conspiracy object implements a conditional control flow datatype.

@verbatim|{
> (require conspiracy/object
           (submod conspiracy/object Rule))
'Object
'Rule
}|

@section{Executing Rules}

@bold{Syntax:}
@verbatim|{
(|@bold{@"@"} |@bold{exec} |@italic{objname} [|@italic{arg} ...] [|@tt{#:when-undefined}])
  |@italic{objname}      : object?
  |@italic{arg}          : any/c
  |@tt{#:when-undefined} : any/c
}|

When a @italic{rule} receives an @tt{exec} message the following sequence occurs:

@itemlist[
 @item{The rule's @tt{pred} property is applied with the same @italic{arg}s supplied to @tt{exec}.}
 @item{If @tt{pred} returns #f, rule processing terminates and #f is returned.}
 @item{The rule's @tt{proc} property is applied with the same @italic{arg}s supplied to @tt{exec}.}
 @item{The rule's @tt{rulebook} property is processed, with each rule of the rulebook repeating the above process.}
 @item{The rule's @tt{value} property is updated with the result of its execution.}]

Rules can be a little hard to wrap your head around. But a simple example involving the nesting of rulebooks should help illustrate their function.

@bold{Examples:}
@verbatim|{

> (% r0 (proc () (-> any) (printf "self=~a~%" self))
     (rulebook (r1 r2 r3)))
'r0
> (% r1 (proc () (-> any) (printf "self=~a~%" self)))
'r1
> (% r2 (proc () (-> any) (printf "self=~a~%" self))
     (rulebook (r21 r22 r23)))
'r2    
> (% r3 (proc () (-> any) (printf "self=~a~%" self)))
'r3
> (% r21 (proc () (-> any) (printf "self=~a~%" self)))
'r21
> (% r22 (proc () (-> any) (printf "self=~a~%" self)))
'r22
> (% r23 (proc () (-> any) (printf "self=~a~%" self)))
'r23
> (@ exec r0)
self=r0
self=r1
self=r2
self=r21
self=r22
self=r23
self=r3
> (@ value r22)
> (@ value r2)
> (@ value r0)           
}|

In the above example @italic{r0} executes, and then executes the rules in its @tt{rulebook}, which in turn execute the rules in their @italic{rulebooks}.  It's a depth-first tree traversal beginning with @italic{r0}.

@subsection{Short-circuiting with @tt{raise}}

@bold{syntax:}
@verbatim|{
(
(|@bold{raise} |@italic{value})
  |@italic{value} : (not/c exn?)
}|

Strictly speaking, @tt{raise} can be used with any value. We're interested in non-exception values because @italic{Rule} will trap those values and perform special processing with them. 

In particular, when you @tt{raise} a non-exception when executing a rule that rule traps the value and stores it in its @tt{value} property, just as it would the result of normal rule processing.

But the processing will terminate at that point, with control going back up the @tt{rule-chain} to what we might consider the root of the call tree, where it is then returned as a normal result. The consequence is that no further rule processing is performed.

@bold{Examples:}
@verbatim|{
> (% r0 (proc () (-> any) (printf "self=~a~%" self))
     (rulebook (r1 r2 r3)))
'r0
> (% r1 (proc () (-> any) (printf "self=~a~%" self)))
'r1
> (% r2 (proc () (-> any) (printf "self=~a~%" self))
     (rulebook (r21 r22 r23)))
'r2    
> (% r3 (proc () (-> any) (printf "self=~a~%" self)))
'r3
> (% r21 (proc () (-> any) (printf "self=~a~%" self)))
'r21
> (% r22 (proc () (-> any) (printf "self=~a~%" self) (raise self)))
'r22
> (% r23 (proc () (-> any) (printf "self=~a~%" self)))
'r23
> (@ exec r0)
self=r0
self=r1
self=r2
self=r21
self=r22
> (@ value r22)
'r22
> (@ value r2)
'r22
> (@ value r0)
'r22
}|

The above examples demonstrates one way to 'short-circuit' rule processing. The next section demonstrates the other.

@subsection{Short-circuiting with @tt{raise-rule-value}}

@bold{Syntax:}
@verbatim|{
(|@bold{raise-rule-value} |@italic{value} [|@italic{objname}])
   |@italic{value}   : any/c
   |@italic{objname} : (λ (v) (member v (cdr rule-chain)))
}|

Raises the value to be caught at any point in @tt{(cdr rule-chain)}. By default this would be the first of that list, or if @tt{empty}, then @tt{(car rule-chain)}.

@bold{Examples:}
@verbatim|{
> (% r0 (proc () (-> any) (printf "self=~a~%" self))
     (rulebook (r1 r2 r3)))
'r0
> (% r1 (proc () (-> any) (printf "self=~a~%" self)))
'r1
> (% r2 (proc () (-> any) (printf "self=~a~%" self))
    (rulebook (r21 r22 r23)))
'r2   
> (% r3 (proc () (-> any) (printf "self=~a~%" self)))
'r3
> (% r21 (proc () (-> any) (printf "self=~a~%" self)))
'r21
> (% r22 (proc () (-> any) (printf "self=~a~%" self) (raise-rule-value self)))
'r22
> (% r23 (proc () (-> any) (printf "self=~a~%" self)))
'r23
> (@ exec r0)
self=r0
self=r1
self=r2
self=r21
self=r22
self=r3
> (@ value r22)
'r22
> (@ value r2)
'r22
> (@ value r0)
}|

Here @tt{raise-rule-value} 'short-circuits' the processing of the @tt{rulebook} in which it is referenced. So @italic{r0} @tt{rulebook} processing continues normally.

Another example:

@verbatim|{
> (% r0 (proc () (-> any) (printf "self=~a~%" self))
     (rulebook (r1 r2 r3)))
'r0
> (% r1 (proc () (-> any) (printf "self=~a~%" self)))
'r1
> (% r2 (proc () (-> any) (printf "self=~a~%" self))
     (rulebook (r21 r22 r23)))
'r2    
> (% r3 (proc () (-> any) (printf "self=~a~%" self)))
'r3
> (% r21 (proc () (-> any) (printf "self=~a~%" self)))
'r21
> (% r22 (proc () (-> any) (printf "self=~a~%" self) (raise-rule-value self r0)))
'r22
> (% r23 (proc () (-> any) (printf "self=~a~%" self)))
'r23
> (@ exec r0)
self=r0
self=r1
self=r2
self=r21
self=r22
'r22
> (@ value r22)
'r22
> (@ value r2)
'r22
> (@ value r0)
'r22
}|

@section{Rule Properties}

The following is an alphabetical listing of properties directly-defined by @tt{Rule}.

@subsection{@tt{active?}}

Boolean indicator signifying whether the rule is active or inactive.

@subsection{@tt{exec}}

The method used to @italic{execute} a rule. This method invokes @tt{pred} first to determine if the rule is prepared to be processed. If it is, then @tt{proc} is invoked, followed by the processing of the rules in the rule's @tt{rulebook}.

@bold{Syntax:}
@verbatim|{
(@ |@bold{exec} |@italic{objname} |@italic{arg} ... [|@tt{#:when-undefined}])
   |@italic{objname}      : |@tt{object?}
   |@italic{arg}          : any/c
   |@tt{#:when-undefined} : any/c
}|

@subsection{@tt{pred}}

Method deciding whether to invoke the rule's @tt{proc} and @tt{rulebook} processing.

@bold{Sample Syntax:}
@verbatim|{
(|@bold{pred} args (->* () #:rest (listof any/c) any) (? active? self))
}|

@subsection{@tt{proc}}

Method representing the rule's 'rule'.

@bold{Sample Syntax:}
@verbatim|{
(|@bold{proc} args (->* () #:rest (listof any/c) any) body0 body ...)
}|

@subsection{@tt{rulebook}}

A list of rules to be @italic{executed} after the rule's @tt{proc} property.

@subsection{@tt{value}}

The result of @tt{exec} processing for the rule.

@section{Rule Functions and Macros}

The following is an alphabetical listing of @tt{Rule} functions and macros.

@subsection{@tt{raise-rule-value}}

Raises the value up the @tt{rule-chain}. Will be handled by the optional @italic{objname}, which defaults to @tt{(first (rest rule-chain))} or to @tt{(first rule-chain} when @tt{(rest rule-chain} is empty. 

@bold{Syntax:}
@verbatim|{
(|@bold{raise-rule-value} |@italic{value} [|@italic{objname}])
  |@italic{value}   : any/c
  |@italic{objname} : |@tt{object?}
}|

@subsection{@tt{rule-chain}}

A macro that represents the execution chain of rules from newest to oldest.