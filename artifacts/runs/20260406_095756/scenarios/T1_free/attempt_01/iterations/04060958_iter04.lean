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
  rcases not_forall.mp hχ with ⟨h, hne⟩
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have hmul : (χ h : ℂ) * S = S := by
    calc
      (χ h : ℂ) * S
          = (χ h : ℂ) * ∑ g : G, (χ g : ℂ) := by rfl
      _ = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
            simp [S, Finset.mul_sum]
      _ = ∑ g : G, (χ (h * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            simp [map_mul]
      _ = ∑ g : G, (χ g : ℂ) := by
            exact Finset.sum_bijective (fun g : G => h * g) (by intro g; simp)
      _ = S := by rfl
  have hχh_ne_one : (χ h : ℂ) ≠ 1 := by
    intro hh1
    apply hne
    ext g
    calc
      χ g = χ (h * (h⁻¹ * g)) := by simp [mul_assoc]
      _ = χ h * χ (h⁻¹ * g) := by simp [map_mul]
      _ = (1 : ℂ) * χ (h⁻¹ * g) := by simpa [hh1]
      _ = χ (h⁻¹ * g) := by simp
      _ = χ h⁻¹ * χ g := by simp [map_mul, mul_assoc]
      _ = ((χ h : ℂ)⁻¹) * χ g := by simpa using congrArg (fun z : ℂ => z⁻¹) hh1
      _ = χ g := by simp [hh1]
  have hzero : S = 0 := by
    apply mul_eq_zero.mp
    have : ((χ h : ℂ) - 1) * S = 0 := by
      linarith [hmul]
    exact this
  simpa [S] using hzero

end T1
end TemTH
