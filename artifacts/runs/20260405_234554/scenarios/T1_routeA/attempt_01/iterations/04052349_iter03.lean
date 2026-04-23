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
  obtain ⟨h, hh⟩ : ∃ h : G, χ h ≠ 1 := by
    by_contra hnot
    apply hχ
    ext g
    have hgh : χ (g * g⁻¹) = χ g * χ g⁻¹ := by simpa using map_mul χ g g⁻¹
    have hgg : χ (g * g⁻¹) = χ 1 := by simp
    have hmul : χ g * χ g⁻¹ = χ 1 := by simpa [hgg] using hgh
    have h1 : χ 1 = 1 := by simpa using not_exists.mp hnot 1
    have hg_inv : χ g⁻¹ = 1 := by simpa using not_exists.mp hnot g⁻¹
    calc
      χ g = χ g * 1 := by simp
      _ = χ g * χ g⁻¹ := by rw [hg_inv]
      _ = χ 1 := hmul
      _ = 1 := h1

  let S : ℂ := ∑ g : G, (χ g : ℂ)

  have hperm :
      ∑ g : G, (χ (h * g) : ℂ) = ∑ g : G, (χ g : ℂ) := by
    simpa using Fintype.sum_bijective (fun g : G => h * g) (mul_left_bijective h)

  have hmulS : (χ h : ℂ) * S = S := by
    calc
      (χ h : ℂ) * S = (χ h : ℂ) * ∑ g : G, (χ g : ℂ) := by rfl
      _ = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
            simpa [S] using (Finset.mul_sum (s := Finset.univ) (a := (χ h : ℂ)) (f := fun g : G => (χ g : ℂ)))
      _ = ∑ g : G, (χ (h * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            simpa using (map_mul χ h g).symm
      _ = ∑ g : G, (χ g : ℂ) := hperm
      _ = S := by rfl

  have hχh_ne_one : (χ h : ℂ) ≠ 1 := by
    exact_mod_cast hh

  by_contra hS
  have hS0 : S = 0 := by simpa [S] using hS
  have hχh_eq_one : (χ h : ℂ) = 1 := by
    have : (χ h : ℂ) * S = 1 * S := by simpa [hS0] using hmulS
    exact mul_right_cancel₀ (by simpa [hS0] : (S : ℂ) ≠ 0) this
  exact hχh_ne_one hχh_eq_one

end T1
end TemTH
