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
  by_cases hsum : ∑ g : G, (χ g : ℂ) = 0
  · exact hsum
  · have h_exists : ∃ h : G, χ h ≠ 1 := by
      by_contra h_not_exists
      apply hχ
      ext g
      by_contra hg
      exact h_not_exists ⟨g, hg⟩
    rcases h_exists with ⟨h, hh_ne⟩
    let S : ℂ := ∑ g : G, (χ g : ℂ)
    have h_reindex : ∑ g : G, (χ (h * g) : ℂ) = S := by
      unfold S
      simpa using
        (Function.Bijective.sum_comp
          (e := fun g : G => h * g)
          (by
            refine ⟨?_, ?_⟩
            · intro a b hab
              simpa using congrArg (fun x => h⁻¹ * x) hab
            · intro g
              refine ⟨h⁻¹ * g, ?_⟩
              simp⟩)
          (g := fun g : G => (χ g : ℂ)))
    have h_mul : ∑ g : G, (χ (h * g) : ℂ) = (χ h : ℂ) * S := by
      calc
        ∑ g : G, (χ (h * g) : ℂ)
            = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
                apply Fintype.sum_congr rfl
                intro g
                simp
        _ = (χ h : ℂ) * ∑ g : G, (χ g : ℂ) := by
              simp [S, mul_add, mul_assoc]
        _ = (χ h : ℂ) * S := by rfl
    have h_eq : S = (χ h : ℂ) * S := by
      calc
        S = ∑ g : G, (χ (h * g) : ℂ) := by symm; exact h_reindex
        _ = (χ h : ℂ) * S := h_mul
    have hfac : (1 - (χ h : ℂ)) * S = 0 := by
      have := h_eq
      dsimp [S] at this ⊢
      linarith
    have hχh_ne : (1 - (χ h : ℂ)) ≠ 0 := by
      intro hzero
      apply hh_ne
      linarith
    have hS_zero : S = 0 := by
      exact eq_of_mul_eq_mul_left hχh_ne (by simpa using hfac.symm)
    exact hS_zero

end T1
end TemTH
