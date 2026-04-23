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
    have hperm : ∑ x : G, (χ (g * x) : ℂ) = ∑ x : G, (χ x : ℂ) := by
      simpa using
        (Function.Bijective.sum_comp
          (e := fun x : G => g * x)
          (by
            refine ⟨?_, ?_⟩
            · intro a b hab
              exact mul_left_cancel hab
            · intro y
              refine ⟨g⁻¹ * y, by simp⟩)
          (fun x : G => (χ x : ℂ)))
    have hmul_ptwise : ∀ x : G, (χ (g * x) : ℂ) = (χ g : ℂ) * (χ x : ℂ) := by
      intro x
      rw [map_mul]
      norm_num
    have hmul : ∑ x : G, (χ (g * x) : ℂ) = (χ g : ℂ) * S := by
      calc
        ∑ x : G, (χ (g * x) : ℂ)
            = ∑ x : G, ((χ g : ℂ) * (χ x : ℂ)) := by
                apply Finset.sum_congr rfl
                intro x hx
                exact hmul_ptwise x
        _ = ∑ x : G, (fun x => (χ g : ℂ) * (χ x : ℂ)) x := by rfl
        _ = (χ g : ℂ) * S := by
              simp [S, Finset.sum_mul]
    have hfixed : S = (χ g : ℂ) * S := by
      calc
        S = ∑ x : G, (χ x : ℂ) := by rfl
        _ = ∑ x : G, (χ (g * x) : ℂ) := by simpa using hperm.symm
        _ = (χ g : ℂ) * S := hmul
    have hfactor : (1 - (χ g : ℂ)) * S = 0 := by
      calc
        (1 - (χ g : ℂ)) * S = S - (χ g : ℂ) * S := by ring
        _ = S - S := by rw [hfixed]
        _ = 0 := sub_self S
    have hneqS : S ≠ 0 := by
      simpa [S] using hS
    have honeC : 1 - (χ g : ℂ) = 0 := by
      exact Or.resolve_right (mul_eq_zero.mp hfactor) hneqS
    have hg_eq_one : χ g = 1 := by
      have h1 : (χ g : ℂ) = 1 := by linarith
      exact h1
    exact hg_eq_one
  have hχeq : χ = 1 := by
    ext g
    exact congrArg (fun z => (z : ℂ)) (h_all_one g)
  exact hχ hχeq

end T1
end TemTH
