
variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_free (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  let χℂ : G →* ℂ := (Units.val : ℂˣ →* ℂ).comp χ
  have hχℂ : χℂ ≠ 1 := by
    intro h1
    apply hχ
    ext g
    apply Units.ext
    have hg : χℂ g = (1 : G →* ℂ) g := by
      exact congrArg (fun φ : G →* ℂ => φ g) h1
    simpa [χℂ] using hg
  have hsum : ∑ g : G, χℂ g = 0 := sum_hom_units_eq_zero χℂ hχℂ
  simpa [χℂ] using hsum
