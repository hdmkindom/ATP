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
  obtain ⟨h, h_ne⟩ := exists_ne_one_apply_of_ne_one (χ := χ) hχ
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have hmul : (χ h : ℂ) * S = S := by
    dsimp [S]
    calc
      (χ h : ℂ) * ∑ g : G, (χ g : ℂ)
          = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
              simp [Finset.mul_sum]
      _ = ∑ g : G, (χ (h * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g _
            simp [map_mul]
      _ = ∑ g : G, (χ g : ℂ) := by
            refine Finset.sum_bij (fun g _ => h * g) ?_ ?_ ?_ ?_
            · intro g _
              simp
            · intro g _
              simp
            · intro g₁ g₂ _ _ hEq
              exact mul_left_cancel hEq
            · intro g _
              refine ⟨h⁻¹ * g, by simp, ?_⟩
              simp [mul_assoc]
  have hχh_ne_one : (χ h : ℂ) ≠ 1 := by
    intro hEq
    exact h_ne (by simpa using hEq)
  have hS : S = 0 := by
    have hfactor : ((χ h : ℂ) - 1) * S = 0 := by
      calc
        ((χ h : ℂ) - 1) * S = (χ h : ℂ) * S - 1 * S := by ring
        _ = S - S := by simpa [hmul]
        _ = 0 := sub_self S
    have hfactor_ne : ((χ h : ℂ) - 1) ≠ 0 := sub_ne_zero.mpr hχh_ne_one
    exact mul_eq_zero.mp hfactor |> Or.resolve_left hfactor_ne
  simpa [S] using hS

end T1
end TemTH
