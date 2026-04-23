/-
`temTH` 模板：`T1` 自由模式。
-/
import CandidateTheorems.T1.Support
import Mathlib.Data.Fintype.BigOperators

open scoped BigOperators

namespace TemTH
namespace T1

open CandidateTheorems.T1

variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_free (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  classical
  by_cases hunit : (∀ g : G, χ g = 1)
  · exfalso
    apply hχ
    funext g
    exact hunit g
  · obtain ⟨g, hg⟩ : ∃ g : G, χ g ≠ 1 := by
      by_contra h
      apply hunit
      intro g
      by_contra hg'
      exact h (by exact ⟨g, hg'⟩)
    have hmul : (χ g : ℂ) * ∑ x : G, (χ x : ℂ) = ∑ x : G, (χ x : ℂ) := by
      calc
        (χ g : ℂ) * ∑ x : G, (χ x : ℂ)
            = ∑ x : G, ((χ g : ℂ) * (χ x : ℂ)) := by
                rw [Finset.mul_sum]
        _ = ∑ x : G, (χ (g * x) : ℂ) := by
              refine Finset.sum_congr rfl ?_
              intro x hx
              simp [map_mul]
        _ = ∑ x : G, (χ x : ℂ) := by
              exact Fintype.sum_bijective (fun x => g * x) (MulLeftBijective g)
    have hneq : (χ g : ℂ) ≠ 1 := by
      exact hg
    have hs : ∑ x : G, (χ x : ℂ) = 0 := by
      apply eq_of_mul_eq_mul_left_of_ne_zero
      · exact sub_ne_zero.mpr hneq
      · rw [sub_mul, one_mul, sub_eq_zero] at hmul ⊢
        exact hmul
    exact hs

end T1
end TemTH
