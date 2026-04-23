
variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_free (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  let f : G →* ℂ := (Units.val : ℂˣ →* ℂ).comp χ
  have hf_ne_one : f ≠ 1 := by
    intro hf
    apply hχ
    ext g
    apply Units.ext
    have hfg : f g = (1 : G →* ℂ) g := by
      exact congrArg (fun φ : G →* ℂ => φ g) hf
    simpa [f] using hfg
  have hsum : ∑ g : G, f g = 0 := by
    exact sum_hom_units_eq_zero f hf_ne_one
  simpa [f] using hsum
