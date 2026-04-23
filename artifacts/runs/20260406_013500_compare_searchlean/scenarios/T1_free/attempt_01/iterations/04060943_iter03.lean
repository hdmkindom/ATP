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
  obtain ⟨h, hh⟩ := Character.exists_ne_one_of_ne_one (G := G) χ hχ
  have hmul :
      (χ h : ℂ) * (∑ g : G, (χ g : ℂ)) = ∑ g : G, (χ g : ℂ) := by
    calc
      (χ h : ℂ) * (∑ g : G, (χ g : ℂ))
          = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
              simpa using Finset.mul_sum (χ h : ℂ) (fun g : G => (χ g : ℂ))
      _ = ∑ g : G, (χ (h * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            simpa using (map_mul χ h g)
      _ = ∑ g : G, (χ g : ℂ) := by
            simpa using Character.sum_comp_mul_left (G := G) χ h
  have hχh_ne_one : (χ h : ℂ) ≠ 1 := by
    simpa [Character.one_apply] using hh
  have hχh_eq_one : (χ h : ℂ) = 1 := by
    apply mul_right_cancel₀ hsum
    simpa [mul_assoc] using hmul
  exact hχh_ne_one hχh_eq_one

end T1
end TemTH
