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
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have h_exists : ∃ h : G, χ h ≠ 1 := by
    by_contra hnone
    apply hχ
    ext g
    have hg : χ g = 1 := by
      by_contra hne
      exact hnone ⟨g, hne⟩
    exact congrArg (fun z : ℂˣ => (z : ℂ)) hg
  rcases h_exists with ⟨h, hh⟩
  have hmul : (χ h : ℂ) * S = S := by
    calc
      (χ h : ℂ) * S = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
        simp [S, mul_add, mul_assoc]
      _ = ∑ g : G, (χ (h * g) : ℂ) := by
        refine Fintype.sum_congr ?_
        intro g
        exact congrArg (fun z : ℂˣ => (z : ℂ)) (map_mul χ h g).symm
      _ = ∑ g : G, (χ g : ℂ) := by
        exact Function.Bijective.sum_comp
          (g := fun g : G => (χ g : ℂ))
          (by
            refine ⟨?_, ?_⟩
            · intro a b hab
              exact mul_left_cancel hab
            · intro g
              refine ⟨h⁻¹ * g, ?_⟩
              simp [mul_assoc] )
      _ = S := by rfl
  have hχh_ne : (χ h : ℂ) ≠ 1 := by
    intro hcast
    apply hh
    exact Units.ext (by simpa using hcast)
  have hsub_ne_zero : (χ h : ℂ) - 1 ≠ 0 := by
    intro hz
    apply hχh_ne
    linarith
  have hmain : ((χ h : ℂ) - 1) * S = 0 := by
    calc
      ((χ h : ℂ) - 1) * S = (χ h : ℂ) * S - S := by ring
      _ = S - S := by rw [hmul]
      _ = 0 := sub_self _
  have hS : S = 0 := by
    by_cases hzero : S = 0
    · exact hzero
    · have : (χ h : ℂ) - 1 = 0 := by
        apply mul_eq_zero.mp
        simpa [hzero] using hmain
      exact False.elim (hsub_ne_zero this)
  simpa [S] using hS

end T1
end TemTH
