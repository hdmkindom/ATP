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
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have hsum_perm : ∑ g : G, (χ (h * g) : ℂ) = S := by
    simp [S, Fintype.sum_bijective, Function.bijective_iff_has_inverse]
  have hmulS : (χ h : ℂ) * S = S := by
    calc
      (χ h : ℂ) * S = ∑ g : G, ((χ h : ℂ) * χ g) := by
        simp [S, Finset.mul_sum]
      _ = ∑ g : G, (χ (h * g) : ℂ) := by
        refine Fintype.sum_congr rfl ?_
        intro g
        simp [map_mul]
      _ = S := hsum_perm
  have hneq : (χ h : ℂ) ≠ 1 := by
    intro hh
    apply hχ
    ext g
    have hh' : (χ h : ℂ) = 1 := hh
    calc
      (χ g : ℂ) = (χ (h * (h⁻¹ * g)) : ℂ) := by simp
      _ = (χ h : ℂ) * χ (h⁻¹ * g) := by simp [map_mul]
      _ = χ (h⁻¹ * g) := by simp [hh']
      _ = (χ h⁻¹ : ℂ) * χ g := by simp [map_mul]
      _ = χ g := by
        have : (χ h⁻¹ : ℂ) = 1 := by
          have hmul : (χ h⁻¹ : ℂ) * χ h = 1 := by simp [map_mul]
          rw [hh'] at hmul
          simpa using hmul
        simp [this]
  have hzero : S = 0 := by
    apply mul_right_cancel₀ (a := (χ h : ℂ) - 1)
    have hm1 : (χ h : ℂ) - 1 ≠ 0 := sub_ne_zero.mpr hneq
    exact hm1
    calc
      ((χ h : ℂ) - 1) * S = (χ h : ℂ) * S - S := by ring
      _ = S - S := by rw [hmulS]
      _ = 0 := sub_self S
  simpa [S] using hzero

end T1
end TemTH
