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
  set S : ℂ := ∑ g : G, (χ g : ℂ)
  have hS : S ≠ 0 := by simpa [S] using hsum
  have hχ1 : ∀ h : G, χ h = 1 := by
    intro h
    have hmul : (χ h : ℂ) * S = S := by
      calc
        (χ h : ℂ) * S
            = (χ h : ℂ) * ∑ g : G, (χ g : ℂ) := by simp [S]
        _ = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
              rw [Finset.mul_sum]
        _ = ∑ g : G, ((χ (h * g) : ℂ)) := by
              refine Finset.sum_congr rfl ?_
              intro g hg
              simp [map_mul]
        _ = ∑ g : G, (χ g : ℂ) := by
              simpa using (Fintype.sum_bijective (f := fun g : G => h * g) (by
                intro a b hab
                exact mul_left_cancel hab))
        _ = S := by simp [S]
    have : ((χ h : ℂ) - 1) * S = 0 := by
      nlinarith [hmul]
    have hχh : (χ h : ℂ) - 1 = 0 := by
      exact sub_eq_zero.mp (eq_of_mul_eq_mul_right (by simpa using hS) (by simpa [sub_mul] using this))
    exact Subtype.ext (sub_eq_zero.mp hχh)
  have : χ = 1 := by
    ext h
    exact hχ1 h
  exact hχ this

end T1
end TemTH
