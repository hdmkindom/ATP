
variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_free (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  have hsum : ∑ g : G, (χ g : ℂ) = 0 := by
    have hχ' : χ ≠ (1 : Character G) := hχ
    simpa using (sum_hom_units_eq_zero (f := χ) hχ')
  exact hsum
