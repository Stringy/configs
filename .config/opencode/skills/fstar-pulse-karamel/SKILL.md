---
name: fstar-pulse-karamel
description: "Develop, verify, and extract programs using F* (proof-oriented programming), Pulse (concurrent separation logic DSL), and Karamel (F* to C extraction). Covers the full stack from pure functional proofs through low-level verified C code."
---

# F*, Pulse & Karamel Development Skill

You are assisting with development in F* (a dependently typed programming language and proof assistant), Pulse (F*'s concurrent separation logic DSL), and/or Karamel (extraction of F* to C). Apply the knowledge below precisely. Do not hallucinate syntax, library functions, or rules that are not documented here.

**Reference**: https://fstar-lang.org/tutorial/book/index.html

---

## 1. F* Language Fundamentals

### 1.1 Module Structure

- One module per `.fst` file; interfaces in `.fsti` files
- Module name must match filename: `module Part1.Foo` lives in `Part1.Foo.fst`
- Module names start with a capital letter
- Top-level forms: `val f : t`, `let [rec] f = e`, `type t = ...`

```fstar
module MyModule
open FStar.Mul   (* required to use * for multiplication *)

let incr (x:int) : int = x + 1
```

### 1.2 Primitive Types

| Type | Values | Notes |
|------|--------|-------|
| `bool` | `true`, `false` | Lowercase |
| `int` | Unbounded mathematical integers | No negative literals: write `(- 1)` not `-1` |
| `nat` | `x:int{x >= 0}` | Refinement of int |
| `pos` | `x:int{x > 0}` | Refinement of int |
| `unit` | `()` | Single value |
| `string` | String literals | |
| `False` | (none) | Empty type (no inhabitants) |
| `True` | (trivial) | |

### 1.3 Key Operators

**Gotcha**: `*` is reserved for tuples by default. Use `open FStar.Mul` to get integer multiplication.

Boolean (decreasing precedence): `not`, `&&`, `||`

Integer: `-` (unary), `+`, `-`, `op_Multiply` (or `*` with `FStar.Mul`), `/`, `%`, `<`, `<=`, `>`, `>=`

Equality:
- `=` : decidable boolean equality (requires `eqtype`)
- `==` : propositional equality (any `Type`, returns `prop`)
- `=!=` : propositional disequality

Logical connectives (on `prop`, decreasing precedence): `~`, `/\`, `\/`, `==>`, `<==>`, `forall`, `exists`

### 1.4 Refinement Types

```fstar
let nat = x:int{x >= 0}
let even = x:int{x % 2 = 0}
let between (lo hi:int) = x:int{lo <= x && x < hi}
```

Subtyping rules:
1. **Elimination**: `x:t{p}` is always a subtype of `t`
2. **Introduction**: `e : t` is subtype of `x:t{p}` when SMT proves `p[e/x]`

### 1.5 Functions

```fstar
(* Lambda *)
fun (x:int) -> x + 1

(* Named *)
let incr (x:int) : int = x + 1

(* Recursive *)
let rec factorial (n:nat) : nat =
  if n = 0 then 1 else n * factorial (n - 1)

(* With return type annotation *)
val max : x:int -> y:int -> z:int{z >= x && z >= y && (z = x || z = y)}
let max x y = if x >= y then x else y
```

### 1.6 Arrow Types (Function Types)

```fstar
x:t0 -> t1           (* dependent arrow; shorthand for x:t0 -> Tot t1 *)
int -> int            (* non-dependent shorthand *)
int -> (d:int{d <> 0}) -> int   (* refinement on parameter *)
x:int -> y:int{y = x + 1}      (* dependent result type *)
```

### 1.7 Implicit Arguments

```fstar
let id (#a:Type) (x:a) : a = x

(* Call without type arg: *)
let _ = id true         (* a inferred as bool *)

(* Explicitly provide implicit arg: *)
let _ = id #nat 0
```

- `#` before parameter in definition = implicit
- `#` before argument at call site = explicitly provide implicit
- `_` = wildcard/hole for inference

### 1.8 Polymorphism

Types are first-class: `Type` is itself a type. Polymorphism = dependent arrow with `Type` argument.

```fstar
let id (#a:Type) (x:a) : a = x
let compose (#a #b #c:Type) (f:b -> c) (g:a -> b) (x:a) : c = f (g x)
```

### 1.9 Inductive Types

```fstar
(* Enumeration *)
type colour = | Red | Green | Blue

(* Parameterised *)
type option a = | None | Some of a

(* Records *)
type point = { x:int; y:int; z:int }
let origin = { x=0; y=0; z=0 }
let p' = { p with x = p.x + 1 }   (* functional update *)

(* Lists *)
type list a = | Nil : list a | Cons : hd:a -> tl:list a -> list a
(* Sugar: [], [v1;v2], hd :: tl *)

(* Indexed / GADT *)
type vec (a:Type) : nat -> Type =
  | Nil : vec a 0
  | Cons : #n:nat -> hd:a -> tl:vec a n -> vec a (n + 1)
```

Parameters (in parens) vs indexes (after colon): parameters are fixed across all constructors; indexes can vary per constructor.

Auto-generated: `T?` discriminator, `T?.field` projector.

**`noeq`**: Required when the type contains functions (no decidable equality).
**`unopteq`**: Derive conditional equality.

### 1.10 Pattern Matching

```fstar
match x with
| Nil -> 0
| Cons hd tl -> 1 + length tl
```

Exhaustiveness is checked semantically (using SMT). Unreachable cases can be omitted when refinements prove impossibility:
```fstar
let hd #a (l:list a{Cons? l}) : a = let Cons h _ = l in h
```

### 1.11 Tuples

```fstar
a & b             (* type *)
x, y              (* value *)
fst p, snd p      (* projections *)
(* Dependent pairs: *)
x:a & b x         (* type: dtuple2 *)
(| x, y |)        (* value *)
```

---

## 2. Proofs and Specifications

### 2.1 Propositions and Assertions

```fstar
(* Compile-time assertion (checked by SMT, erased at runtime) *)
let _ = assert (forall x. x * x >= 0)

(* Assumption (dangerous, can introduce unsoundness) *)
let _ = assume (some_property)

(* Admit (gives any type, most dangerous) *)
let _ : nat = admit ()

(* Normalisation-based assertion *)
let _ = assert_norm (pow2 12 == 4096)
```

### 2.2 Lemmas

```fstar
(* Full form *)
let rec factorial_is_pos (x:int)
  : Lemma (requires x >= 0)
          (ensures factorial x > 0)
  = if x = 0 then () else factorial_is_pos (x - 1)

(* Shorthand forms *)
val my_lemma : x:nat -> Lemma (some_property x)
val my_lemma : x:nat -> Lemma (requires pre x) (ensures post x)

(* Lemma is an abbreviation for: *)
(* Pure unit (requires pre) (ensures fun _ -> post) *)
```

Proofs by induction = total recursive functions returning unit. The induction hypothesis is available as the recursive call with a guarded type (argument must be smaller).

### 2.3 Termination

All functions in `Tot` must terminate. Termination proven via a measure that strictly decreases on `<<` (well-founded partial order).

```fstar
(* Explicit decreases clause *)
let rec length #a (l:list a) : Tot nat (decreases l) = ...

(* Lexicographic ordering *)
let rec ackermann (m n:nat)
  : Tot nat (decreases %[m; n])
  = if m = 0 then n + 1
    else if n = 0 then ackermann (m - 1) 1
    else ackermann (m - 1) (ackermann m (n - 1))

(* Mutual recursion *)
let rec foo (l:list int) : Tot int (decreases %[l; 0]) = ...
and bar (l:list int) : Tot int (decreases %[l; 1]) = foo l
```

Default measure: lexicographic ordering of all non-function-typed arguments, left to right.

The `<<` relation:
- On `nat`: strict `<`
- On inductives: sub-term ordering (direct sub-terms are smaller)

### 2.4 Intrinsic vs Extrinsic Proofs

**Intrinsic**: Properties encoded in the function's type.
```fstar
let rec append #a (l1 l2:list a) : l:list a{length l = length l1 + length l2} = ...
```

**Extrinsic**: Properties proven as separate lemmas.
```fstar
let rec rev_involutive #a (l:list a) : Lemma (reverse (reverse l) == l) = ...
```

### 2.5 SMT Patterns

```fstar
val mem_empty (#a:eqtype) (x:a)
  : Lemma (not (mem x empty))
    [SMTPat (mem x empty)]
```

**Critical**: Patterns should decompose terms into smaller sub-terms. Avoid patterns that create new matching candidates (matching loops).

**Bad** (matching loop):
```fstar
[SMTPat (mem x s1); SMTPat (mem x s2)]   (* pairs trigger on ALL combinations *)
```

---

## 3. Effect System

### 3.1 Effect Hierarchy

```
        DIV (partial correctness WPs)
       /
   GHOST    Dv (may diverge)
     |     /
    GTot
     |
    Tot (bottom — pure, total)
     |
   PURE (WP-indexed)
```

- `Tot < GTot < ...` and `Tot < Dv`
- `lub Tot GTot = GTot`, `lub Tot Dv = Dv`
- `Tot` can only depend on `Tot`
- Ghost code is erased by the compiler

### 3.2 Core Effects

| Effect | Meaning | Use |
|--------|---------|-----|
| `Tot` | Total, pure, terminating | Core logic, specifications |
| `GTot` | Ghost total (erased) | Specification-only code |
| `Dv` | May diverge | General recursion, Turing-complete |
| `Pure a req ens` | Hoare-style pure with pre/post | Rich specifications |
| `Lemma` | `Pure unit req ens` | Proofs |
| `Ghost a req ens` | Hoare-style ghost | Erased specifications |
| `Div a req ens` | Hoare-style divergent | Partial correctness |
| `PURE a wp` | WP-indexed pure | Low-level WP control |

### 3.3 Ghost and Erasure

```fstar
(* Ghost function — erased at compile time *)
let rec factorial (n:nat) : GTot nat = if n = 0 then 1 else n * factorial (n - 1)

(* erased type — computationally irrelevant wrapper *)
open FStar.Ghost
let x : erased nat = hide 42
let y : GTot nat = reveal x    (* incurs GTot effect *)
```

- `reveal` : `erased a -> GTot a`
- `hide` : `a -> Tot (erased a)`
- Implicit coercions: F* auto-inserts `hide`/`reveal` in many contexts
- Non-informative types (`Type`, `prop`, `erased t`, `unit`) allow GTot→Tot promotion

### 3.4 Divergence

```fstar
let rec collatz (n:pos) : Dv (list pos) = ...   (* may not terminate *)
let rec loop () : Dv unit = loop ()              (* always diverges *)
```

- `Dv` disables the termination checker
- Partial correctness: if it terminates, the result has the specified type
- Cannot cast `Dv` to `Tot` (prevents unsoundness)
- Properties of `Dv` computations must be encoded intrinsically
- `Dv` relaxes strict positivity and universe restrictions

---

## 4. Modularity

### 4.1 Interfaces (.fsti)

- `.fsti` declares types and signatures; `.fst` provides implementations
- One interface per module, one implementation per interface
- `val f : t` without definition makes `f` abstract
- `let` definitions in interfaces provide logical models

```fstar
(* UInt32.fsti *)
module UInt32
val t : eqtype
val v (x:t) : nat
val add (a:t) (b:t{fits (+) a b}) : y:t{v y == v a + v b}
```

**Gotcha**: Definition order in `.fst` must match `val` order in `.fsti` (interleaving constraint).

### 4.2 Typeclasses

```fstar
class printable (a:Type) = { to_string : a -> string }

instance printable_bool : printable bool = { to_string = string_of_bool }
instance printable_int : printable int = { to_string = string_of_int }

(* Parameterised instances *)
instance printable_list (#a:Type) (x:printable a) : printable (list a) = { ... }

(* Using typeclass parameters *)
let print_any #a {| printable a |} (x:a) = to_string x

(* Typeclass inheritance via record fields *)
class ops (a:Type) = {
  [@@@TC.no_method] base : bounded a;
  add : a -> a -> a;
}
```

- `{| ... |}` for typeclass parameters
- `[@@@no_method]` prevents method generation for a field
- Resolution is goal-directed backwards search

### 4.3 Monadic Syntax Overloading

```fstar
class monad (m:Type -> Type) = {
  return : #a:Type -> a -> m a;
  ( let! ) : #a:Type -> #b:Type -> m a -> (a -> m b) -> m b;
}

(* Defines let!, ;!, match!, if! *)
(* Any suffix of operator chars works: let+, let?, etc. *)
```

---

## 5. Tactics and Metaprogramming (Meta-F*)

### 5.1 Basic Usage

```fstar
assert (pow2 19 == 524288) by compute ();    (* normaliser reduces *)
assert (some_fact) by (mapply (`some_lemma));  (* apply lemma backwards *)
assert (p /\ q) by (split (); smt (); smt ());
```

### 5.2 Key Tactics

| Tactic | Purpose |
|--------|---------|
| `compute()` | Full normalisation |
| `trivial()` | Solve trivially true goals |
| `smt()` | Defer goal to SMT solver |
| `mapply (\`lemma)` | Apply lemma backwards |
| `split()` | Split conjunction into two goals |
| `left()` / `right()` | Choose disjunct |
| `implies_intro()` | Introduce implication hypothesis |
| `forall_intro()` | Introduce universal variable |
| `assumption()` | Prove from context hypothesis |
| `dump "label"` | Print proof state (debugging) |
| `norm [steps]` | Fine-grained normalisation |
| `` unfold_def `t `` | Unfold specific definition |
| `focus (fun () -> ...)` | Isolate current goal |

### 5.3 Quotations

`` `Name `` creates a `term` (abstract AST). Antiquotation: `` `(1 + `#t) ``.

---

## 6. SMT Solver Interaction

### 6.1 Fuel Control

```fstar
#push-options "--fuel 2 --ifuel 1"    (* set fuel levels *)
#push-options "--z3rlimit_factor 2"   (* double resource limit *)
```

- `--fuel n` : recursive function unfolding depth
- `--ifuel n` : inductive type inversion depth
- `--z3rlimit_factor n` : multiply resource limit
- Rule of thumb: if you need `--fuel > 2`, restructure the proof

### 6.2 Performance Options

```fstar
(* Disable non-linear arithmetic (recommended for stable proofs) *)
#push-options "--z3smtopt '(set-option :smt.arith.nl false)'"

(* Linear arithmetic optimisation *)
#push-options "--smtencoding.l_arith_repr native --smtencoding.elim_box true"

(* Split queries for better rlimit utilisation *)
#push-options "--split_queries always"

(* Restrict available facts *)
#push-options "--using_facts_from 'Prims FStar.Seq'"

(* Quake testing for flaky proofs *)
#push-options "--quake 5/k"
```

### 6.3 Opaque Definitions

```fstar
[@@"opaque_to_smt"]
let my_def x = complex_expression x

(* Selectively reveal in a proof scope *)
let my_lemma x = reveal_opaque (`%my_def) (my_def x); ...
```

### 6.4 allow_inversion

```fstar
#push-options "--ifuel 0"
let f (x:option int) =
  allow_inversion (option int);    (* removes ifuel guard for this type *)
  match x with | Some v -> v | None -> 0
```

Only use on small/bounded types. Never on unbounded types like `list` or `nat`.

### 6.5 Hints

```bash
fstar.exe --record_hints File.fst    # record Z3 unsat cores
fstar.exe --use_hints File.fst       # replay with pruned context
```

### 6.6 Profiling

```fstar
#push-options "--query_stats"
#restart-solver                       (* clean statistics *)
```

```bash
z3 file.smt2 smt.qi.profile=true > qiprofile
grep quantifier_instances qiprofile | sort -k 4 -n
```

---

## 7. Universes

```fstar
Type u#0 : Type u#1 : Type u#2 : ...   (* predicative hierarchy *)

(* Universe of arrows: max of domain and codomain *)
(* Universe of inductive: max of all constructor field universes *)
(* squash : Type u#a -> Type u#0  — limited impredicativity *)
```

Tips:
- Use `#push-options "--print_universes"` to debug universe errors
- Prefer parameters over indexes for lower universes
- Universe polymorphism is top-level only (local functions are monomorphic)

---

## 8. Pulse — Concurrent Separation Logic DSL

### 8.1 Enabling Pulse

```fstar
#lang-pulse
open Pulse.Lib.Pervasives
```

Pulse and F* interoperate bidirectionally in the same file.

### 8.2 Separation Logic Basics

**`slprop`** describes properties about program resources (heap state).

Key connectives:
- `emp` — empty/trivial
- `pure p` — heap-independent predicate
- `pts_to x v` — reference `x` points to value `v`
- `p ** q` — separating conjunction (disjoint resources)
- `exists* x. p` — existential quantification
- `forall* x. p` — universal quantification
- `p @==> q` — separating implication (trade/view shift)

**Frame Rule**: If `{p} c {q}` then `{p ** f} c {q ** f}` for any `f`.

### 8.3 Function Signatures

```fstar
fn name (#implicit:Type) (explicit:arg_type)
requires precondition_slprop
preserves preserved_slprop       (* sugar: both requires and ensures *)
returns v:return_type
ensures postcondition_slprop
{
  body
}
```

### 8.4 Implicit Logical Variables

`'i` is shorthand for an implicitly bound `erased` variable:
```fstar
fn incr (x:ref int)
requires pts_to x 'i              (* 'i is erased int *)
ensures pts_to x ('i + 1)
{ let v = !x; x := v + 1; }
```

### 8.5 References

**Stack references** (`ref t`):
```fstar
let mut i = 0;      (* creates i:ref int with pts_to i 0 *)
(* Scoped — cannot be returned from functions *)
(* Reclaimed automatically; requires pts_to x #1.0R _ at scope exit *)
```

**Heap references** (`Pulse.Lib.Box.box t`):
```fstar
module Box = Pulse.Lib.Box
let r = Box.alloc 0;    (* heap-allocated, can be returned *)
Box.free r;              (* explicit deallocation *)
```

**Read/Write**:
```fstar
let v = !x;     (* read: requires pts_to x #p 'v for any p > 0 *)
x := v + 1;     (* write: requires pts_to x #1.0R _ (full permission) *)
```

### 8.6 Fractional Permissions

```fstar
pts_to x #p v     (* p:perm in (0.0R, 1.0R] *)
(* 1.0R = exclusive read/write *)
(* any p > 0.0R suffices for reading *)
(* writing REQUIRES 1.0R *)

share r;    (* split permission in half *)
gather r;   (* combine halves; also proves values are equal *)
```

### 8.7 Existentials

```fstar
(* Elimination *)
with w. assert (pts_to x w);     (* binds erased witness w *)

(* Introduction *)
introduce exists* v. pts_to x v ** pure (v > 0)
with (old_v + 1);                 (* provide witness *)
```

### 8.8 User-defined Predicates

```fstar
let is_point (p:point) (xy:int & int) =
  pts_to p.x (fst xy) ** pts_to p.y (snd xy)
```

Must explicitly `fold`/`unfold`:
```fstar
unfold (is_point p 'v);    (* replace predicate with definition *)
fold (is_point p new_v);   (* replace definition with predicate *)
```

Use `[@@@mkey]` on the matching key argument.

### 8.9 Rewriting

```fstar
rewrite each x as p.x, y as p.y;            (* parallel rewrite *)
with x1 ... xn. rewrite p as q;             (* general rewrite *)
```

### 8.10 Conditionals

```fstar
if (cond) { branch1 } else { branch2 }
```

**Gotcha**: Non-tail conditionals require explicit `ensures` annotation:
```fstar
if (cond)
ensures exists* r. pts_to result r ** pure (some_prop r)
{ ... }
else { ... };
```

### 8.11 Pattern Matching

```fstar
match r {
  Some x -> { ... }
  None -> { ... }
}
```

Restrictions: simple patterns only (one constructor + variables), no nested patterns, no negated path conditions. Use `norewrite` annotation when needed.

### 8.12 Loops

```fstar
while (guard)
invariant (b:bool). p_b
{ body }
(* Postcondition: p false *)
```

- Guard returns `bool`; body returns `unit`
- `exists* b. p` must hold at loop entry and as body postcondition
- Loop postcondition is `p false` (invariant with b=false)
- Guard can be an arbitrary Pulse program

### 8.13 Recursion

```fstar
fn rec my_function (args)
requires ...
ensures ...
decreases measure     (* REQUIRED — Pulse does not infer default decreases *)
{ ... }
```

### 8.14 Arrays

```fstar
(* Stack array *)
let mut a = [| 0; 4sz |];    (* size must be compile-time constant *)

(* Heap array *)
module V = Pulse.Lib.Vec
let a = V.alloc 0 4sz;
V.free a;

(* Read/Write *)
arr.(i)          (* read at index i:SZ.t *)
arr.(i) <- v     (* write at index *)
```

Array contents modelled as `FStar.Seq.seq t`.

### 8.15 Ghost Functions

```fstar
ghost
fn my_ghost_fn (x:erased int)
requires some_slprop
ensures some_slprop
{ ... }
```

- Erased at runtime
- Cannot return informative types to non-ghost callers
- Recursive ghost functions require `decreases`
- Ghost references: `Pulse.Lib.GhostReference`

### 8.16 Higher-Order Functions

Three computation types:
- `stt` — general (reads/writes state, may diverge), universe `u#0`
- `stt_ghost` — ghost/total, universe `u#4` (cannot be stored in state)
- `stt_atomic` — single atomic step, total, universe `u#4`

```fstar
fn apply (#a #b:Type0) (#pre:a -> slprop) (#post:(x:a -> b x -> slprop))
         (f: (x:a -> stt (b x) (pre x) (fun y -> post x y)))
         (x:a)
requires pre x
returns y:b x
ensures post x y
{ f x }
```

### 8.17 Trades and Quantification

```fstar
(* Trade: single-use separating implication *)
p @==> q                        (* if you have p, trade for q (consumes both) *)
I.intro p q r (fun _ -> ...);   (* introduce trade *)
I.elim p q;                     (* eliminate trade *)
I.refl p;                       (* reflexive trade: p @==> p *)
I.trans p q r;                  (* transitive composition *)

(* Universal quantification *)
forall* (x:t). p x
FA.intro #t #p v (fun x -> ...);
FA.elim #t #p v;

(* Combined: forall+trade *)
forall* x. p x @==> q x
```

### 8.18 Invariants and Atomics

```fstar
(* Create invariant (consumes p) *)
let i = new_invariant p;

(* Open invariant for ONE atomic step *)
with_invariants i
returns x:t
ensures post
{ body }    (* body must be stt_atomic or stt_ghost *)

(* Invariant is duplicable *)
dup_inv i p;

(* Later credits for impredicative invariants *)
later_credit_buy n;
```

**Rules**: Cannot open same invariant twice. Body of `with_invariants` limited to one atomic step. `later_credit` needed for non-timeless predicates.

### 8.19 Spin Locks

```fstar
(* Pulse.Lib.SpinLock *)
let l = new_lock p;     (* consumes p *)
acquire l;              (* provides p, spins until available *)
release l;              (* consumes p *)
dup_lock_alive l p;     (* lock permissions are duplicable *)
```

### 8.20 Parallel Composition

```fstar
parallel
requires p1 and p2
ensures q1 and q2
{ e1 }
{ e2 }
```

Requires disjoint resources (separating conjunction).

### 8.21 Proof Commands Summary

| Command | Purpose |
|---------|---------|
| `show_proof_state` | Inspect proof state (aborts checker) |
| `fold p` | Introduce user-defined predicate |
| `unfold p` | Eliminate user-defined predicate |
| `rewrite p as q` | Equational rewriting |
| `rewrite each e1 as e1', ...` | Parallel rewriting |
| `with x. assert p` | Eliminate existential |
| `introduce exists* x. p with w` | Introduce existential |
| `share r` / `gather r` | Split/combine permissions |
| `assert p` | Assert provable in context |

---

## 9. Karamel — F* to C Extraction

### 9.1 Overview

Karamel compiles F* programs (specifically the Low* subset) to readable C code. All proofs and specifications are erased. The generated C is semantics-preserving (proven in ICFP 2017 paper).

### 9.2 Low* — The Extractable Subset

Low* = first-order F* + C-modelling libraries.

**Base types**: `UInt8.t`, `UInt16.t`, `UInt32.t`, `UInt64.t`, `UInt128.t`, `Int8.t`..`Int64.t`, `bool`, `unit`

```fstar
let square (x: UInt32.t): UInt32.t =
  let open FStar.UInt32 in x *%^ x
(* Extracts to: uint32_t square(uint32_t x) { return x * x; } *)
```

### 9.3 Memory Model — HyperStack

**Critical**: Always use `FStar.HyperStack.ST`, NOT `FStar.ST`.

```fstar
module ST = FStar.HyperStack.ST
module HS = FStar.HyperStack
module B = LowStar.Buffer
```

Effects: `Stack` (stack only), `ST` (stack + heap), `St` (trivial pre/post).

**Stack frames** (mandatory for stateful Stack-effect functions):
```fstar
let f () : Stack unit (...) (...) =
  push_frame ();
  let b = B.alloca 0ul 8ul in    (* stack-allocated buffer *)
  (* ... use b ... *)
  pop_frame ()
```

### 9.4 Buffers (C Arrays)

```fstar
open LowStar.BufferOps

(* Stack allocation *)
let b = B.alloca 0ul 8ul in       (* uint32_t b[8] = {0}; *)

(* Heap allocation *)
let b = B.malloc HS.root 0ul 8ul   (* calloc(8, sizeof(uint32_t)) *)
B.free b                           (* free(b) *)

(* Read/Write *)
let v = b.(0ul) in                 (* b[0] *)
b.(0ul) <- 42ul;                   (* b[0] = 42; *)

(* Sub-buffer (pointer arithmetic) *)
let b2 = B.sub b 4ul 4ul           (* b + 4, length 4 *)
```

Buffer length is ghost-only (like C). Thread length as a separate parameter:
```fstar
val process (buf:B.buffer UInt32.t) (len:UInt32.t{UInt32.v len = B.length buf}) : St unit
```

### 9.5 Structs

```fstar
type pair = { fst: UInt32.t; snd: UInt32.t }
(* Extracts to: typedef struct { uint32_t fst; uint32_t snd; } pair; *)
```

Functional updates compile to C field mutations.

### 9.6 Data Type Compilation Schemes

| Pattern | C result |
|---------|----------|
| Single constructor, single arg | Unwrapped (e.g., `type t = T of uint32` → `uint32_t`) |
| Only constant constructors | `uint8_t` enum |
| Single constructor, multiple fields | `struct` (no tag) |
| One non-constant + constants | `struct` with `uint8_t tag` (no union) |
| General | Tagged union |

### 9.7 What Gets Erased

Erased: all proofs, specifications, ghost/erased arguments, unit arguments, unused arguments (if module-private and first-order), HyperStack model, push_frame/pop_frame, modifies clauses.

Retained: machine integer operations, buffer alloc/read/write, structs, control flow, constants, string literals.

### 9.8 Constraints

- **No local closures** — use `[@inline_let]` or manual closure state
- **No recursive data types** — compile to infinite-size C structs
- **No polymorphic `assume val`** — refused by Karamel
- **No indexed/dependent types at runtime** — generates broken `void*`
- Karamel performs whole-program monomorphisation for polymorphic code

### 9.9 Extraction Commands

```bash
# F* to .krml
fstar.exe --codegen krml --extract 'Module1 Module2' --odir obj *.fst

# Karamel to C
krml -tmpdir dist -skip-compilation obj/*.krml \
  -bundle 'Impl.Foo=Impl.Foo.*[rename=Foo]' \
  -minimal -add-include '<stdint.h>'
```

### 9.10 Bundling

Controls C file organisation and visibility:
```
-bundle PublicModule=PrivatePattern1,PrivatePattern2
```

Never mix headers from different Karamel runs (monomorphisation conflicts).

---

## 10. Pulse Extraction

### 10.1 Three Targets

**Rust**:
```bash
fstar.exe --codegen Extension --cmi --load_cmxs pulse *.fst
./pulse2rust/main.exe Module.ast -o output.rs
```

**C** (via Karamel): Requires monomorphic wrappers for polymorphic functions.
```bash
fstar.exe --codegen krml *.fst
krml -skip-compilation out.krml
```

**OCaml**:
```bash
fstar.exe --codegen OCaml *.fst
```

### 10.2 Current Limitations

- Rust: ghost args appear as `()` params; all refs extracted as `&mut`; trait bounds hardcoded
- C: requires monomorphic wrappers (no C generics)
- OCaml: `let mut` becomes heap-allocated; relies on GC

---

## 11. Common Gotchas Reference

### F* Core
1. `*` is NOT multiplication — use `open FStar.Mul`
2. No negative integer literals — write `(- 1)` not `-1`
3. `false : bool` vs `False : Type` (empty type)
4. `=` (decidable, `eqtype`) vs `==` (propositional, any `Type`)
5. Typechecking is undecidable — can timeout
6. Module name must match filename
7. Full functional extensionality is UNSOUND in F*
8. Definition order in `.fst` must match `val` order in `.fsti`

### Proofs
9. Named functions work better than lambda literals with SMT
10. Keep fuel low (0-2); restructure if you need more
11. Disable non-linear arithmetic and use `FStar.Math.Lemmas`
12. Alternating forall/exists without patterns cause matching loops — make them opaque
13. `assert` is compile-time only (erased); `assume` is dangerous; `admit` is most dangerous
14. Strengthening the induction hypothesis is a critical proof technique

### Pulse
15. `**` uses two stars (not one) to avoid clash with multiplication
16. Writing requires full `1.0R` permission
17. Stack refs cannot be returned from functions
18. Non-tail conditionals require explicit `ensures` annotation
19. Pattern matching: simple patterns only, no nesting
20. Recursive Pulse functions require explicit `decreases`
21. `fold`/`unfold` are manual for user-defined predicates

### Karamel / Low*
22. Use `FStar.HyperStack.ST`, NOT `FStar.ST`
23. Forgetting `push_frame`/`pop_frame` causes verification errors
24. Buffer length is ghost-only — thread as separate parameter
25. Only base pointers can be `free`d, not sub-buffers
26. No local closures — use `[@inline_let]` or manual state
27. Never mix headers from different Karamel runs
