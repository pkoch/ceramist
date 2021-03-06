(** * Structures/BloomFilter/BloomFilter_Definitions.v
-----------------

Provides the definitions and deterministic operations of a Bloom
Filter and uses them to instantiate the AMQ interface.

This file is a good example of the recommended structure to use when
defining new AMQ data structures.  *)

From mathcomp.ssreflect
     Require Import ssreflect ssrbool ssrnat eqtype fintype choice ssrfun seq path bigop finfun .
From mathcomp.ssreflect
     Require Import tuple.
From mathcomp
     Require Import path.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

From ProbHash.Utils
     Require Import InvMisc.
From ProbHash.Computation
     Require Import Comp Notationv1.
From ProbHash.Core
     Require Import Hash HashVec FixedList AMQ AMQHash.



Module BloomFilterDefinitions (Spec: HashSpec).

Module HashVec := (HashVec Spec).
Export HashVec.

(**
   A fomalization of a bloom filter structure and properties
   *)
Section BloomFilter.
  (**
    k - number of hashes
   *)
  Variable k: nat.
  (**
    n - maximum number of hashes supported
   *)
  Variable n: nat.
  Variable Hkgt0: k >0.

  Definition BitVector := (Hash_size.+1).-tuple bool.

  (**
     list of hash functions used in the bloom filter
   *)
  Record BloomFilter := mkBloomFilter {
                            bloomfilter_state: BitVector
                          }.

  Definition BloomFilter_prod (bf: BloomFilter) :=
    (bloomfilter_state bf).

  Definition prod_BloomFilter  pair := let: (state) := pair in @mkBloomFilter state.

  Lemma bloomfilter_cancel : cancel (BloomFilter_prod) (prod_BloomFilter).
  Proof.
      by case.
  Qed.

  Definition bloomfilter_eqMixin :=
    CanEqMixin bloomfilter_cancel .

  Canonical bloomfilter_eqType  :=
    Eval hnf in EqType BloomFilter  bloomfilter_eqMixin .

  Definition bloomfilter_choiceMixin :=
    CanChoiceMixin bloomfilter_cancel.

  Canonical bloomfilter_choiceType  :=
    Eval hnf in ChoiceType BloomFilter  bloomfilter_choiceMixin.

  Definition bloomfilter_countMixin :=
    CanCountMixin bloomfilter_cancel.

  Canonical bloomfilter_countType :=
    Eval hnf in CountType BloomFilter  bloomfilter_countMixin.

  Definition bloomfilter_finMixin :=
    CanFinMixin bloomfilter_cancel .

  Canonical bloomfilter_finType :=
    Eval hnf in FinType BloomFilter  bloomfilter_finMixin.

  Definition bloomfilter_set_bit (value: 'I_(Hash_size.+1)) bf : BloomFilter :=
    mkBloomFilter
      (set_tnth (bloomfilter_state bf) true value).

  Definition bloomfilter_get_bit (value: 'I_(Hash_size.+1)) bf : bool :=
    (tnth (bloomfilter_state bf) value).

  Fixpoint bloomfilter_add_internal (items: seq 'I_(Hash_size.+1)) bf : BloomFilter :=
    match items with
      h::t => bloomfilter_add_internal t (bloomfilter_set_bit h bf)
    | [::]   => bf
    end.


  Definition bloomfilter_query_internal (items: seq 'I_(Hash_size.+1)) bf : bool :=
    all (fun h => bloomfilter_get_bit h bf) items.

  Definition bloomfilter_query (value: hash_keytype) (hashes: k.-tuple (HashState n)) (bf: BloomFilter) : Comp [finType of (k.-tuple (HashState n)) * bool ] :=
    hash_res <-$ (HashVec.hash_vec_int value hashes);
      let (new_hashes, hash_vec) := hash_res in
      let qres := bloomfilter_query_internal (tval hash_vec) bf in
      ret (new_hashes, qres).

  
  Definition bloomfilter_new : BloomFilter.
    apply mkBloomFilter.
    apply Tuple with (nseq Hash_size.+1 false).
      by rewrite size_nseq.
  Defined.
  
  Lemma bloomfilter_new_empty_bits b : ~~ bloomfilter_get_bit b bloomfilter_new .
  Proof.
    clear k n Hkgt0.
    rewrite/bloomfilter_get_bit/bloomfilter_new //=.
    elim: Hash_size b => [[[|//=] Hm]|//= n IHn] //=.
    move=> [[| b] Hb]; rewrite /tnth //=.
    move: (Hb); move/ltn_SnnP: Hb => Hb' Hb;move: (IHn (Ordinal Hb'));rewrite /tnth //=.
    clear.
    move: (size_nseq n.+1 _)  => Hprf.
    move:(tnth_default _ _) (tnth_default _ _); clear Hb => b1 b2.
    have ->: (false :: nseq n false) = (nseq n.+1 false); first by [].
    move: Hb'; rewrite -Hprf; clear Hprf.
    move: (n.+1); clear n; elim: b => [//= n'|]; first by case: (nseq n' _).
    move=>  b IHb.
    case => [//=| n].
      by move=>//=/ltn_SnnP/(IHb n) IHb' H; apply IHb'.
  Qed.

  Lemma bloomfilter_new_empty bs : length bs > 0 -> ~~ bloomfilter_query_internal bs bloomfilter_new .
  Proof.
    clear k n Hkgt0.
    case: bs => [//=| b1 [//=| b2 bs]] Hlen; first by rewrite Bool.andb_true_r; apply bloomfilter_new_empty_bits.
    rewrite Bool.negb_andb; apply/orP; left; apply bloomfilter_new_empty_bits.
  Qed.
  
  Lemma bloomfilter_set_bitC bf ind ind':
    (bloomfilter_set_bit ind (bloomfilter_set_bit ind' bf)) =
    (bloomfilter_set_bit ind' (bloomfilter_set_bit ind bf)).
  Proof.
    rewrite /bloomfilter_set_bit/bloomfilter_state//.
    apply f_equal => //.
    apply eq_from_tnth => pos.
    case Hpos: (pos == ind); case Hpos': (pos == ind').
    - by rewrite !FixedList.tnth_set_nth_eq.
    - rewrite FixedList.tnth_set_nth_eq; last by [].
      rewrite FixedList.tnth_set_nth_neq; last by move/Bool.negb_true_iff: Hpos' ->.
        by rewrite FixedList.tnth_set_nth_eq; last by [].
    - rewrite FixedList.tnth_set_nth_neq; last by move/Bool.negb_true_iff: Hpos ->.
      rewrite FixedList.tnth_set_nth_eq; last by [].
        by rewrite FixedList.tnth_set_nth_eq; last by [].
    - rewrite FixedList.tnth_set_nth_neq; last by move/Bool.negb_true_iff: Hpos ->.  
      rewrite FixedList.tnth_set_nth_neq; last by move/Bool.negb_true_iff: Hpos' ->.
      rewrite FixedList.tnth_set_nth_neq; last by move/Bool.negb_true_iff: Hpos' ->.  
        by rewrite FixedList.tnth_set_nth_neq; last by move/Bool.negb_true_iff: Hpos ->.
  Qed.

  Lemma bloomfilter_add_internal_hit bf (ind: 'I_Hash_size.+1) hshs :
    (ind \in hshs) ->
    (tnth (bloomfilter_state (bloomfilter_add_internal hshs bf)) ind).
  Proof.
    elim: hshs bf  => //= hsh hshs IHs bf.
    rewrite in_cons => /orP [/eqP -> | H]; last by apply IHs.
    clear IHs ind.
    elim: hshs bf hsh => //.
    - rewrite /bloomfilter_add_internal/bloomfilter_set_bit/bloomfilter_state //.
        by move=> bf hsh; rewrite FixedList.tnth_set_nth_eq => //=.
    - move=> hsh hshs IHs bf hsh'.    
      move=> //=.
      rewrite bloomfilter_set_bitC .
        by apply IHs.
  Qed.

  Lemma bloomfilter_add_internal_preserve bf ind hshs:
    tnth (bloomfilter_state bf) ind ->
    tnth (bloomfilter_state (bloomfilter_add_internal hshs bf)) ind.
  Proof.
    elim: hshs bf ind => //= hsh hshs IHs bf ind Htnth.
    apply IHs.
    rewrite /bloomfilter_set_bit/bloomfilter_state //.
    case Hhsh: (ind == hsh).
    - by rewrite FixedList.tnth_set_nth_eq //=.
    - rewrite FixedList.tnth_set_nth_neq; first by move: Htnth; rewrite/bloomfilter_state//=.
        by move/Bool.negb_true_iff: Hhsh.
  Qed.

  Lemma bloomfilter_add_internal_miss
        bf (ind: 'I_Hash_size.+1) hshs :
    ~~ tnth (bloomfilter_state bf) ind ->
    ~~ ( ind \in hshs) ->
    (~~ tnth (bloomfilter_state (bloomfilter_add_internal hshs bf)) ind).
  Proof.
    move=> Htnth.
    elim: hshs bf Htnth => //= hsh hshs IHs bf Htnth.
    move=> H; move: (H).
    rewrite in_cons.
    rewrite negb_or => /andP [Hneq Hnotin].
    apply IHs.
    rewrite /bloomfilter_state/bloomfilter_set_bit.
    rewrite FixedList.tnth_set_nth_neq => //=.
    exact Hnotin.
  Qed.

  Lemma bloomfilter_add_internal_hit_infer bf (ind: 'I_Hash_size.+1) inds:
    ~~ bloomfilter_get_bit ind bf ->
    tnth (bloomfilter_state (bloomfilter_add_internal inds bf)) ind ->
    ind \in inds.
  Proof.
    move=> Hbit Htnth.
    case Hind: (ind \in inds) =>//=; move/Bool.negb_true_iff: Hind => Hind.
      by move/Bool.negb_true_iff: (bloomfilter_add_internal_miss Hbit Hind) Htnth ->.
  Qed.

  Lemma bloomfilter_set_get_eq hash_value bf :
    bloomfilter_get_bit hash_value (bloomfilter_set_bit hash_value bf).
  Proof.
      by rewrite /bloomfilter_get_bit/bloomfilter_set_bit//
                 /bloomfilter_state FixedList.tnth_set_nth_eq //=.
  Qed.
  
  Lemma bloomfilter_add_insert_contains l (bf: BloomFilter) (inds: l.-tuple 'I_Hash_size.+1 )
        (ps: seq 'I_Hash_size.+1) :
    all (fun p => p \in inds) ps -> all (bloomfilter_get_bit^~ (bloomfilter_add_internal inds bf)) ps.
  Proof.                  
    move=>/allP HinP; apply/allP => [p Hp].
      by rewrite /bloomfilter_get_bit/bloomfilter_state bloomfilter_add_internal_hit //=; move: (HinP p Hp).
  Qed.
  
  Lemma bloomfilter_set_bit_conv bf b b':
    (bloomfilter_set_bit b (bloomfilter_set_bit b' bf)) =
    (bloomfilter_set_bit b' (bloomfilter_set_bit b bf)).
  Proof.
    rewrite/bloomfilter_set_bit/bloomfilter_state; apply f_equal.
    case: bf; rewrite/BitVector=>bf .
      by rewrite  fixedlist_set_nthC.
  Qed.

  Lemma bloomfilter_add_multiple_cat bf b others:
    (bloomfilter_add_internal others (bloomfilter_add_internal b bf)) =
    (bloomfilter_add_internal (others ++ b) bf).
  Proof.
    elim: others bf => [//=|other others Hothers] bf //= .
    rewrite -Hothers; apply f_equal; clear Hothers others.
    elim: b bf => [//=| b bs Hbs] bf //=.
    rewrite  bloomfilter_set_bit_conv.
      by rewrite Hbs.
  Qed.
  
  
End BloomFilter.
End BloomFilterDefinitions.


(** instantiation of AMQ interface *)
Module BloomFilterAMQ (Spec: HashSpec).
  Module BasicHashVec := BasicHashVec Spec.
  Module BloomFilterDefinitions :=  BloomFilterDefinitions Spec.

  Export BasicHashVec.
  Export BloomFilterDefinitions.

  Module AMQ <: AMQ BasicHashVec.

    Definition AMQStateParams := True.

    Definition AMQState (val:AMQStateParams) : finType :=
      [finType of BloomFilterDefinitions.BloomFilter ].

    Section AMQ.
      Variable p: AMQStateParams.
      Variable h: BasicHashVec.AMQHashParams.

      Definition AMQ_add_internal
                 (amq: AMQState p)
                 (inds: BasicHashVec.AMQHashValue h) : AMQState p :=
        BloomFilterDefinitions.bloomfilter_add_internal
          inds amq.

      Definition AMQ_query_internal
                 (amq: AMQState p) (inds: BasicHashVec.AMQHashValue h) : bool :=

        BloomFilterDefinitions.bloomfilter_query_internal
          inds amq.
      Definition AMQ_available_capacity (_: BasicHashVec.AMQHashParams) (amq: AMQState p) (l:nat) : bool := true.
      Definition AMQ_valid (amq: AMQState p) : bool := true.

      Definition AMQ_new: AMQState p :=
        BloomFilterDefinitions.bloomfilter_new.

      
      Lemma AMQ_new_nqueryE: forall vals, ~~ AMQ_query_internal  AMQ_new vals.
      Proof.
        move=> //= vals.
        apply BloomFilterDefinitions.bloomfilter_new_empty.
          by rewrite -length_sizeP size_tuple => //=.
      Qed.
      
      Lemma AMQ_new_validT: AMQ_valid AMQ_new.
      Proof.
          by [].
      Qed.
      
      Section DeterministicProperties.
        Variable amq: AMQState p.

        Lemma AMQ_available_capacityW: forall  n m,
            AMQ_valid amq -> m <= n -> AMQ_available_capacity h amq n -> AMQ_available_capacity h amq m.
        Proof.
            by [].
        Qed.
        
        Lemma AMQ_add_query_base: forall (amq: AMQState p) inds,
            AMQ_valid amq -> AMQ_available_capacity h amq 1 ->
            AMQ_query_internal (AMQ_add_internal amq inds) inds.
        Proof.
          move=> //= amq' inds _ _.
          move: inds => [inds Hinds] //=.
          rewrite/AMQ_query_internal/AMQ_add_internal//=; clear Hinds.
          elim: inds  amq' => //= ind inds IHinds amq'.
          apply/andP;split.
            by apply bloomfilter_add_internal_preserve; apply tnth_set_nth_eq.
            apply IHinds.
        Qed.
        
        Lemma AMQ_add_valid_preserve: forall (amq: AMQState p) inds,
            AMQ_valid amq -> AMQ_available_capacity h amq 1 ->
            AMQ_valid (AMQ_add_internal amq inds).
        Proof.
            by [].
        Qed.
        
        Lemma AMQ_add_query_preserve: forall (amq: AMQState p) inds inds',
            AMQ_valid amq -> AMQ_available_capacity h amq 1 -> AMQ_query_internal amq inds ->
            AMQ_query_internal (AMQ_add_internal amq inds') inds.
        Proof.
          move=> amq' inds inds' _ _.
          move=>/allP Hquery; apply/allP => v Hv; move: (Hquery v Hv).
          apply bloomfilter_add_internal_preserve.
        Qed.
        
        Lemma AMQ_add_capacity_decr: forall (amq: AMQState p) inds l,
            AMQ_valid amq -> AMQ_available_capacity h amq l.+1 ->
            AMQ_available_capacity h (AMQ_add_internal amq inds) l.
        Proof.
            by [].
        Qed.
        
        Lemma AMQ_query_valid_preserve: forall (amq: AMQState p) inds,
            AMQ_valid amq -> AMQ_valid (AMQ_add_internal amq inds).
        Proof.
            by [].
        Qed.
        
        Lemma AMQ_query_capacity_preserve: forall (amq: AMQState p) inds l,
            AMQ_valid amq -> AMQ_available_capacity h amq l.+1 -> AMQ_available_capacity h (AMQ_add_internal amq inds) l.
        Proof.
            by [].
        Qed.

      End DeterministicProperties.
    End AMQ.
  End AMQ.

End BloomFilterAMQ.
