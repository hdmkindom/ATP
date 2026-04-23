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
  obtain ⟨h, hh_ne⟩ := MulChar.ne_one_iff.mp hχ
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have h_reindex : ∑ g : G, (χ (h * g) : ℂ) = S := by
    unfold S
    exact Fintype.sum_bijective (fun g : G => h * g) (fun g : G => h⁻¹ * g) (by intro g; simp) (by intro g; simp)
      (by intro g; rfl)
  have h_mul : ∑ g : G, (χ (h * g) : ℂ) = (χ h : ℂ) * S := by
    unfold S
    calc
      ∑ g : G, (χ (h * g) : ℂ)
          = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
              refine Fintype.sum_congr rfl ?_
              intro g
              rw [map_mul]
              ring
      _ = (χ h : ℂ) * ∑ g : G, (χ g : ℂ) := by
            simp [mul_sum]
      _ = (χ h : ℂ) * S := by rfl
  have h_eq : S = (χ h : ℂ) * S := by
    rw [← h_reindex]
    exact h_mul.symm
  have hχh_ne : (χ h : ℂ) ≠ 1 := by
    exact hh_ne
  have h_factor_ne : 1 - (χ h : ℂ) ≠ 0 := by
    exact sub_ne_zero.mpr (ne_comm.mp hχh_ne)
  have h_zero_factor : (1 - (χ h : ℂ)) * S = 0 := by
    rw [h_eq]
    ring
  have hS_zero : S = 0 := by
    exact Or.resolve_left (mul_eq_zero.mp h_zero_factor) h_factor_ne
  exact hS_zero

end T1
end TemTH
