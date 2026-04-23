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
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  by_cases hS : S = 0
  · simpa [S] using hS
  · exfalso
    apply hχ
    apply MulChar.ext'
    intro g
    have hmul : (χ g : ℂ) * S = S := by
      calc
        (χ g : ℂ) * S = (χ g : ℂ) * ∑ x : G, (χ x : ℂ) := by rfl
        _ = ∑ x : G, (χ g : ℂ) * (χ x : ℂ) := by
              rw [mul_sum]
        _ = ∑ x : G, (χ (g * x) : ℂ) := by
              refine Fintype.sum_congr ?_ ?_
              · rfl
              · intro x
                simp
        _ = ∑ y : G, (χ y : ℂ) := by
              exact Function.Bijective.sum_comp
                (e := fun x : G => g * x)
                (by
                  refine ⟨?_, ?_⟩
                  · intro a b hab
                    simpa using (mul_left_cancel hab)
                  · intro y
                    refine ⟨g⁻¹ * y, ?_⟩
                    simp [mul_assoc]
                )
                (fun y : G => (χ y : ℂ))
        _ = S := by rfl
    have hg : (χ g : ℂ) = 1 := by
      apply mul_right_cancel₀ hS
      simpa [one_mul] using hmul
    exact hg


end T1
end TemTH
