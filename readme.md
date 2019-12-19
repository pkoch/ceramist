# ProbHash -  Verified Hash-based Probabilistic Algorithms
## Installation
Use opam to install dependencies

```
opam install ./opam
```

Then build the project:
```
make clean && make
```


## Project Structure
The structure of the overall development is as follows:
```
.
├── Computation
│   ├── Comp.v
│   └── Notationv1.v
├── Structures
│   ├── Core
│   │   ├── FixedList.v
│   │   ├── FixedMap.v
│   │   ├── Hash.v
│   │   └── HashVec.v
│   ├── BloomFilter
│   │   ├── BloomFilter_Definitions.v
│   │   └── BloomFilter_Probability.v
│   ├── CountingBloomFilter
│   │   ├── CountingBloomFilter_Definitions.v
│   │   └── CountingBloomFilter_Probability.v
│   └── QuotientFilter
│       ├── QuotientFilter_Definitions.v
│       └── QuotientFilter_Probability.v
└── Utils
    ├── InvMisc.v
    ├── rsum_ext.v
    ├── seq_ext.v
    ├── seq_subset.v
    ├── stirling.v
    └── tactics.v

7 directories, 19 files
```

The library is split into separate logical components by directory:
- *Computation* - defines a probability monad and associated notation for it on top of the 'coq-infotheo' probability library.
- *Utils* - collection of utility lemmas and tactics used throughout the development
- *Structures/Core* - contains definitions and properties about the core probabilistic primitives exported by the library.
- *Structures/BloomFilter* - example use of the exported library to prove various probabilistic properties on bloom filters.
- *Structures/CountingBloomFilter* - another exemplar use of the library to prove probabilistic properties on counting bloom filters. 

## Axioms
NO AXIOMS! 

## Tactics
To simplify reasoning about probabilistic computations, we provide a few helper tactics under `ProbHash.Utils`:

- `comp_normalize` - is a tactic which normalizes  probabilistic computations in the goal to a standard
   form consisting of a nested summation with a summand which is the product of each individual statement:
   For example, if our goal contains a term of the form:
```
d[ res <-$ hash n v hsh;
x <- fst res;
ret x ] value
```
    applying `comp_normalize` normalizes it to:
```
\sum_(i in HashState n) 
\sum_(i0 in 'I_Hash_size.+1) 
((d[ hash n v hsh]) (i, i0) *R* 
((value == i0) %R))
``` 
    This tactic works by simply recursively descending the computation and expanding the
    definition of the distribution.

- `comp_simplify` - is a tactic which effectively applies beta
   reduction to the normalized form, substituting any `ret x` (which
   have been normalized to a factor of the form `(x == ...)` by the previous tactic)
   statements into the rest of the computation - applying it to the previous example would result in:
```
\sum_(i in HashState n) 
(d[ hash n v hsh]) (i, value)
```
- `comp_simplify_n n` - is a variant of the previous one which applies
   the reduction a fixed number `n` of times as sometimes the previous
   tactic may loop.
- `comp_possible_decompose` - is a tactic which converts a fact (must
   be first element of goal) about a possible computation 
   `( d[ c1; c2; ....; cn] v != 0)` 
   into a fact about the possibility of the individual statements of
   the computation
   `forall v1,v2, ..., vn, d[ c1 ] v1 != 0 -> d[ c2] v2 -> .... d[ cn] vn != 0`
- `comp_possible_exists` is a tactic which converts a goal about a computation being possible
   `( d[ c1; c2; ....; cn] v != 0)` 
   into a corresponding proof of existance, where one must provide
   possible outcomes for each statement outcome
   `exists v1,v2, ..., vn, d[ c1 ] v1 != 0 /\ d[ c2] v2 /\ .... /\ d[ cn] vn != 0`
- `comp_impossible_decompose` - is a tactic which automatically
   decomposes an impossibility statement 
   `\sum_{v1} ... \sum_{vn} P[c1 = v1] * ... * P[ cn = vn ] = 0` 
   into properties about its component parts 
   `forall v1,..,vn, P[c1 = v1] * ... * P[cn = vn] = 0`

- `exchange_big_inwards f` - is a tactic which moves the outermost
   summation in a series of nested summations to the innermost
   position, then applies the supplied tactic `f` in this context.

- `exchange_big_outwards n` - is a tactic which moves the `n`th
   summation in a series of nested summations to the outermost
   position.

## License
Given its dependencies:

- Coq (distributed under the LGPLv2.1 license)
- MathComp (distributed under the CeCILL-B license)
- Infotheo (distributed under the GPLv3 license)

ProbHash is distributed under the GPLv3 license.
