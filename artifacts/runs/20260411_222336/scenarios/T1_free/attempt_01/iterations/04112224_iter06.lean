import Mathlib




variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_free (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  have hsum : ∑ g : G, ((χ g : ℂˣ) : ℂ) = 0 := by
    simpa using sum_hom_units_eq_zero (f := χ) hχ
  simpa using hsum
