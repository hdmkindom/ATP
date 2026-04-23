/-
`temTH` 模板：`T1` 路线 A。
-/
import CandidateTheorems.T1.Support
import Mathlib.Data.Fintype.BigOperators
import Mathlib.NumberTheory.LegendreSymbol.GaussSum

open scoped BigOperators

namespace TemTH
namespace T1

open CandidateTheorems.T1

variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_routeA (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  classical
  obtain ⟨h, hne⟩ := MulChar.ne_one_iff.mp hχ
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have hperm : ∑ g : G, (χ (h * g) : ℂ) = S := by
    simp [S, Function.Bijective.sum_comp, mul_left_bijective]
  have hmul : ∑ g : G, (χ (h * g) : ℂ) = (χ h : ℂ) * S := by
    simp [S, map_mul, Finset.mul_sum]
  have hχh_ne : (χ h : ℂ) ≠ 1 := by
    exact hne
  have hzero : ((χ h : ℂ) - 1) * S = 0 := by
    rw [← hperm] at hmul
    linarith
  have hfactor_ne : (χ h : ℂ) - 1 ≠ 0 := by
    exact sub_ne_zero.mpr hχh_ne
  exact mul_eq_zero.mp hzero |> Or.resolve_left hfactor_ne

end T1
end TemTH
