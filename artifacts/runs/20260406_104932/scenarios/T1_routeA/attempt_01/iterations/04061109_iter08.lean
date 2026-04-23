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
  have h_all_one : ∀ g : G, χ g = 1 := by
    intro g
    by_contra hg
    let S : ℂ := ∑ x : G, (χ x : ℂ)
    have hperm : ∑ x : G, (χ (g * x) : ℂ) = ∑ x : G, (χ x : ℂ) := by
      simpa using
        (Function.Bijective.sum_comp
          (e := fun x : G => g * x)
          (by
            refine ⟨?_, ?_⟩
            · intro a b hab
              exact mul_left_cancel hab
            · intro y
              refine ⟨g⁻¹ * y, ?_⟩
              simp [mul_assoc] )
          (fun x : G => (χ x : ℂ)))
    have hmul : ∑ x : G, (χ (g * x) : ℂ) = (χ g : ℂ) * S := by
      simp [S, map_mul, mul_sum]
    have hfixed : S = (χ g : ℂ) * S := by
      rw [← hperm, hmul]
    have hfactor : (1 - (χ g : ℂ)) * S = 0 := by
      rw [sub_mul, one_mul, hfixed, sub_self]
    have hneqS : S ≠ 0 := by
      simpa [S] using hsum
    have honeC : (1 - (χ g : ℂ)) = 0 := by
      exact sub_eq_zero.mp (eq_of_mul_eq_mul_right_of_ne_zero hneqS hfactor)
    have hgC : (χ g : ℂ) = 1 := by
      linarith
    exact hg (by
      ext
      simpa using hgC)
  have hχeq : χ = 1 := by
    ext g
    exact h_all_one g
  exact hχ hχeq

end T1
end TemTH
