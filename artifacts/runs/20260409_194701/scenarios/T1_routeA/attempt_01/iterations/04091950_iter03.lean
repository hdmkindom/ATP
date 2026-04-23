/-
`temTH` 模板：`T1` 路线 A。
-/
import CandidateTheorems.T1.Support
import Mathlib.Data.Fintype.BigOperators

open scoped BigOperators

namespace TemTH
namespace T1

open CandidateTheorems.T1

variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_routeA (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  classical
  rcases Character.exists_ne_one_apply_of_ne_one (χ := χ) hχ with ⟨h, hh⟩
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have hmul : (χ h : ℂ) * S = S := by
    dsimp [S]
    calc
      (χ h : ℂ) * ∑ g : G, (χ g : ℂ)
          = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
              simp [Finset.mul_sum]
      _ = ∑ g : G, (χ (h * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            simp [map_mul]
      _ = ∑ g : G, (χ g : ℂ) := by
            simpa using Character.sum_comp_left_mul (χ := χ) h
  have hχh_ne : (χ h : ℂ) - 1 ≠ 0 := by
    intro hzero
    apply hh
    exact sub_eq_zero.mp hzero
  have hS_zero : S = 0 := by
    have h1 : ((χ h : ℂ) - 1) * S = 0 := by
      calc
        ((χ h : ℂ) - 1) * S = (χ h : ℂ) * S - S := by ring
        _ = S - S := by simpa [hmul]
        _ = 0 := sub_self S
    have hmulzero := mul_eq_zero.mp h1
    rcases hmulzero with hleft | hright
    · exact (hχh_ne hleft).elim
    · exact hright
  simpa [S] using hS_zero

end T1
end TemTH
