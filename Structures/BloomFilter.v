From mathcomp.ssreflect
Require Import ssreflect ssrbool ssrnat eqtype fintype choice ssrfun seq path.

From mathcomp.ssreflect
Require Import tuple.

From mathcomp
Require Import path.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

From BloomFilter
Require Import Parameters Hash Comp Notationv1 .


(* A fomalization of a bloom filter structure *)
Definition BloomFilter k n := k.-tuple (HashState n).

(* The first approximation: a number of axioms *)
About hash.

