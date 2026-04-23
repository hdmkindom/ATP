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
  by_contra hsum
  obtain ⟨g0, hg0⟩ : ∃ g0 : G, χ g0 ≠ 1 := by
    by_contra hno
    apply hχ
    ext g
    by_contra hne
    exact hno ⟨g, hne⟩
  have hmul : (χ g0 : ℂ) * (∑ g : G, (χ g : ℂ)) = ∑ g : G, (χ g : ℂ) := by
    calc
      (χ g0 : ℂ) * (∑ g : G, (χ g : ℂ))
          = ∑ g : G, ((χ g0 : ℂ) * (χ g : ℂ)) := by
              simpa using Finset.mul_sum (χ g0 : ℂ) (fun g : G => (χ g : ℂ))
      _ = ∑ g : G, (χ (g0 * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            simpa using map_mul χ g0 g
      _ = ∑ g : G, (χ g : ℂ) := by
            simpa using Fintype.sum_bijective (fun g : G => g0 * g) (by
              intro a b h
              exact mul_left_cancel h) (by
              intro g
              refine ⟨g0⁻¹ * g, ?_⟩
              simp [mul_assoc])
  have hfactor : ((χ g0 : ℂ) - 1) * (∑ g : G, (χ g : ℂ)) = 0 := by
    linarith [hmul]
  have hneq : ((χ g0 : ℂ) - 1) ≠ 0 := by
    exact sub_ne_zero.mpr hg0
  have : (∑ g : G, (χ g : ℂ)) = 0 := by
    exact mul_eq_zero.mp hfactor |> Or.resolve_left hneq
  exact hsum this

end T1
end TemTH
