import Mathlib/NumberTheory/LegendreSymbol/QuadraticChar/Basic




variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_free (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  have hsum_units : (∑ g : G, χ g) = 0 := by
    exact MulChar.sum_eq_zero_of_ne_one (χ := χ) hχ
  exact_mod_cast hsum_units
