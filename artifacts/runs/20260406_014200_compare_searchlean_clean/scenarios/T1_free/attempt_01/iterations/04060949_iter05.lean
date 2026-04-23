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
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have hS : S ≠ 0 := by
    simpa [S] using hsum
  have hmul : ∀ a : G, (χ a : ℂ) * S = S := by
    intro a
    calc
      (χ a : ℂ) * S
          = (χ a : ℂ) * ∑ g : G, (χ g : ℂ) := by rfl
      _ = ∑ g : G, ((χ a : ℂ) * (χ g : ℂ)) := by
            simpa [mul_sum]
      _ = ∑ g : G, (χ (a * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            simpa using (map_mul χ a g)
      _ = ∑ g : G, (χ g : ℂ) := by
            refine Fintype.sum_bijective (fun g : G => a * g) ?_ ?_
            · intro g
              exact ⟨a⁻¹ * g, by simp [mul_assoc]⟩
            · intro g
              exact ⟨a⁻¹ * g, by simp [mul_assoc]⟩
      _ = S := by rfl
  have hχ_one : ∀ a : G, (χ a : ℂ) = 1 := by
    intro a
    have hEq := hmul a
    have hzero : ((χ a : ℂ) - 1) * S = 0 := by
      nlinarith [hEq]
    have hfac : (χ a : ℂ) - 1 = 0 := by
      exact sub_eq_zero.mp (sub_eq_zero.mp (by
        apply mul_eq_zero.mp hzero |>.resolve_right hS))
    linarith
  have hχ_eq_one : χ = 1 := by
    ext a
    exact hχ_one a
  exact hχ hχ_eq_one

end T1
end TemTH
