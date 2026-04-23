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
  by_cases hG : IsEmpty G
  · letI : Fintype G := Fintype.ofIsEmpty G
    simp
  · push_neg at hG
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
        (χ h : ℂ) * S = (χ h : ℂ) * ∑ g : G, (χ g : ℂ) := by rfl
        _ = ∑ g : G, (χ h : ℂ) * (χ g : ℂ) := by
          rw [mul_assoc]
          exact Finset.mul_sum _ _
        _ = ∑ g : G, (χ (h * g) : ℂ) := by
          refine Fintype.sum_congr ?_
          intro g
          exact congrArg (fun z : ℂˣ => (z : ℂ)) (map_mul χ h g)
        _ = ∑ g : G, (χ g : ℂ) := by
          let e : G ≃ G :=
            { toFun := fun g => h * g
              invFun := fun g => h⁻¹ * g
              left_inv := by
                intro g
                simp [mul_assoc]
              right_inv := by
                intro g
                simp [mul_assoc]
            }
          simpa using (Equiv.sum_comp e fun g : G => (χ g : ℂ))
        _ = S := by rfl
    have hχh_ne : (χ h : ℂ) ≠ 1 := by
      intro hcast
      apply hh
      apply Units.ext
      exact hcast
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
      · have hfac : (χ h : ℂ) - 1 = 0 := by
          exact Or.resolve_right (mul_eq_zero.mp hmain) hzero
        exact False.elim (hsub_ne_zero hfac)
    exact hS

end T1
end TemTH
