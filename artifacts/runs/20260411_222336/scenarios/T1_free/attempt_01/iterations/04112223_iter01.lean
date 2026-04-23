import Mathlib




variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_free (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  -- `Character G` is a multiplicative character into `ℂˣ`.
  -- Use the general finite-group lemma for monoid homs into units.
  simpa using sum_hom_units_eq_zero (f := χ) hχ
