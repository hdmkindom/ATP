


variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_free (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  -- Standard finite-group character sum vanishing for a nontrivial character.
  simpa using sum_hom_units_eq_zero (f := χ) hχ
