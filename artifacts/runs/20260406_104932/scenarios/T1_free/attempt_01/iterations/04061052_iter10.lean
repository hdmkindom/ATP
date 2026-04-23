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
  by_cases hsum : (∑ g : G, (χ g : ℂ)) = 0
  · exact hsum
  · exfalso
    apply hχ
    ext g
    have hmain : (χ g : ℂ) * ∑ x : G, (χ x : ℂ) = ∑ x : G, (χ x : ℂ) := by
      calc
        (χ g : ℂ) * ∑ x : G, (χ x : ℂ)
            = ∑ x : G, ((χ g : ℂ) * (χ x : ℂ)) := by
                simp [mul_sum]
        _ = ∑ x : G, (χ (g * x) : ℂ) := by
              refine Finset.sum_congr rfl ?_
              intro x hx
              simp
        _ = ∑ y : G, (χ y : ℂ) := by
              exact Fintype.sum_bijective (fun x : G => g * x) (by
                intro a
                simp) 
        _ = ∑ x : G, (χ x : ℂ) := rfl
    have hg : (χ g : ℂ) = 1 := by
      apply mul_right_cancel₀ (show (∑ x : G, (χ x : ℂ)) ≠ 0 from hsum)
      simpa [one_mul] using hmain
    exact hg


end T1
end TemTH
