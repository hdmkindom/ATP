import Mathlib/Algebra/BigOperators/Basic
import Mathlib/RepresentationTheory/Character




variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_free (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  have hsum : ∑ g : G, (χ g : ℂ) = 0 := by
    simpa using MulChar.sum_eq_zero_of_ne_one (χ := χ) hχ
  exact hsum
