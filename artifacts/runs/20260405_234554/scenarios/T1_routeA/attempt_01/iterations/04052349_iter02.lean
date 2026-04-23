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
  by_contra hsum
  have hχ1 : χ 1 ≠ 1 := by
    intro h1
    apply hχ
    ext g
    calc
      χ g = χ (g * 1) := by simp
      _ = χ g * χ 1 := by simpa using map_mul χ g 1
      _ = χ g * 1 := by rw [h1]
      _ = χ g := by simp
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have hS_ne_zero : S ≠ 0 := by
    simpa [S] using hsum
  have hmulS : (χ 1 : ℂ) * S = S := by
    calc
      (χ 1 : ℂ) * S = (χ 1 : ℂ) * ∑ g : G, (χ g : ℂ) := by rfl
      _ = ∑ g : G, ((χ 1 : ℂ) * (χ g : ℂ)) := by simp [mul_sum]
      _ = ∑ g : G, (χ (1 * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            simpa [map_mul]
      _ = ∑ g : G, (χ g : ℂ) := by simp
      _ = S := by rfl
  have hχ1_eq_one : (χ 1 : ℂ) = 1 := by
    exact mul_right_cancel₀ hS_ne_zero (by simpa [hmulS] using hmulS)
  exact hχ1 (by simpa using hχ1_eq_one)

end T1
end TemTH
