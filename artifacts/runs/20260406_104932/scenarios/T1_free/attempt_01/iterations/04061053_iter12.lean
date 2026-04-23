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
    ext g
    have hmul : (χ g : ℂ) * S = S := by
      calc
        (χ g : ℂ) * S = (χ g : ℂ) * ∑ x : G, (χ x : ℂ) := by rfl
        _ = ∑ x : G, (χ g : ℂ) * (χ x : ℂ) := by
              simp [S, mul_sum]
        _ = ∑ x : G, (χ (g * x) : ℂ) := by
              refine Finset.sum_congr rfl ?_
              intro x hx
              simp
        _ = ∑ y : G, (χ y : ℂ) := by
              exact Fintype.sum_bijective (fun x : G => g * x)
                (by
                  refine Function.bijective_iff_has_inverse.mpr ?_
                  refine ⟨fun y : G => g⁻¹ * y, ?_, ?_⟩ <;> intro a <;> simp [mul_assoc])
                (fun y : G => (χ y : ℂ))
        _ = S := by rfl
    have hg : (χ g : ℂ) = 1 := by
      apply mul_right_cancel₀ hS
      simpa [one_mul] using hmul
    exact Complex.ofReal_injective <| by
      simpa using hg


end T1
end TemTH
