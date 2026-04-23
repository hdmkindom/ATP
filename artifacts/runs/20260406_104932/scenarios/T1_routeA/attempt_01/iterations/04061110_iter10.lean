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
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  by_contra hS
  have h_all_one : ∀ g : G, χ g = 1 := by
    intro g
    by_contra hg
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
      calc
        ∑ x : G, (χ (g * x) : ℂ)
            = ∑ x : G, ((χ g : ℂ) * (χ x : ℂ)) := by
                apply Finset.sum_congr rfl
                intro x hx
                norm_num [map_mul]
        _ = (χ g : ℂ) * S := by
              simp [S, Finset.mul_sum]
    have hfixed : S = (χ g : ℂ) * S := by
      calc
        S = ∑ x : G, (χ x : ℂ) := by rfl
        _ = ∑ x : G, (χ (g * x) : ℂ) := by simpa using hperm.symm
        _ = (χ g : ℂ) * S := hmul
    have hfactor : (1 - (χ g : ℂ)) * S = 0 := by
      rw [sub_mul, one_mul, hfixed, sub_self]
    have hneqS : S ≠ 0 := by
      simpa [S] using hS
    have honeC : (1 - (χ g : ℂ)) = 0 := by
      exact Or.resolve_right (mul_eq_zero.mp hfactor) hneqS
    have hg_eq_one_complex : (χ g : ℂ) = 1 := by
      have := congrArg (fun z : ℂ => z + (χ g : ℂ)) honeC
      simpa using this
    have hg_eq_one : χ g = 1 := by
      exact Subtype.ext (by simpa using hg_eq_one_complex)
    exact hg hg_eq_one
  have hχeq : χ = 1 := by
    ext g
    exact h_all_one g
  exact hχ hχeq

end T1
end TemTH
