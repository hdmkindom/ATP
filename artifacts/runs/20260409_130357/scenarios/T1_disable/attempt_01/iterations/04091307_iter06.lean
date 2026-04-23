/-
`temTH` 模板：`T1` 禁用模式。
-/
import CandidateTheorems.T1.Support
import Mathlib.Data.Fintype.BigOperators

open scoped BigOperators

namespace TemTH
namespace T1

open CandidateTheorems.T1

variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_disable (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  classical
  by_cases hsum : (∑ g : G, (χ g : ℂ)) = 0
  · exact hsum
  · exfalso
    apply hχ
    ext g
    by_contra hg
    have hmul : (χ g : ℂ) * (∑ x : G, (χ x : ℂ)) = ∑ x : G, (χ x : ℂ) := by
      calc
        (χ g : ℂ) * (∑ x : G, (χ x : ℂ))
            = ∑ x : G, ((χ g : ℂ) * (χ x : ℂ)) := by
                simpa [mul_sum]
        _ = ∑ x : G, (χ (g * x) : ℂ) := by
              refine Finset.sum_congr rfl ?_
              intro x hx
              norm_num [map_mul]
        _ = ∑ y : G, (χ y : ℂ) := by
              refine Finset.sum_bijective (fun x => g * x) ?_
              exact Equiv.bijective (Equiv.mulLeft g)
        _ = ∑ x : G, (χ x : ℂ) := rfl
    have hg1 : (χ g : ℂ) = 1 := by
      exact mul_right_cancel₀ hsum hmul
    apply hg
    exact Subtype.ext (by simpa using hg1)

end T1
end TemTH
