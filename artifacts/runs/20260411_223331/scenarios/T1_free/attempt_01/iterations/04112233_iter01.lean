import Mathlib




variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_free (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  -- `Character G` is a multiplicative character valued in `ℂˣ`.
  -- We use the standard orthogonality lemma for nontrivial multiplicative characters.
  have hsum_units : (∑ g : G, χ g) = 0 := by
    simpa using MulChar.sum_eq_zero_of_ne_one (χ := χ) hχ
  -- Coerce the equality from `ℂˣ`-valued sum interpreted in `ℂ`.
  simpa using hsum_units
