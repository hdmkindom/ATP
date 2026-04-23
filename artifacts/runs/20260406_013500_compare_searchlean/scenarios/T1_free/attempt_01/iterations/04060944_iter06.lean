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
  rcases Character.exists_apply_ne_one (G := G) χ hχ with ⟨h, hh⟩
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have hmul : (χ h : ℂ) * S = S := by
    calc
      (χ h : ℂ) * S
          = (χ h : ℂ) * ∑ g : G, (χ g : ℂ) := rfl
      _ = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
            simp [mul_sum]
      _ = ∑ g : G, ((χ (h * g) : ℂ)) := by
            congr with g
            simpa [map_mul]
      _ = ∑ g : G, (χ g : ℂ) := by
            simpa using (Character.sum_comp_mul_left (G := G) χ h)
      _ = S := rfl
  have hχh_ne_zero : (χ h : ℂ) - 1 ≠ 0 := by
    have hχh_ne_one : (χ h : ℂ) ≠ 1 := by
      simpa using hh
    exact sub_ne_zero.mpr hχh_ne_one
  have hzero : S = 0 := by
    apply mul_eq_zero.mp
    refine ⟨?_, rfl⟩
    exact hχh_ne_zero
      (by
        calc
          (χ h : ℂ) - 1 = (χ h : ℂ) - 1 := rfl)
  have hfactor : ((χ h : ℂ) - 1) * S = 0 := by
    calc
      ((χ h : ℂ) - 1) * S = (χ h : ℂ) * S - S := by ring
      _ = S - S := by simpa [hmul]
      _ = 0 := sub_self S
  have hS : S = 0 := by
    exact (mul_eq_zero.mp hfactor).resolve_left hχh_ne_zero
  simpa [S] using hS

end T1
end TemTH
