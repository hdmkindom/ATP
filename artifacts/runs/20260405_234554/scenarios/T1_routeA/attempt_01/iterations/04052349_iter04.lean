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
  -- Pick h with χ h ≠ 1
  obtain ⟨h, hh⟩ : ∃ h : G, χ h ≠ 1 := by
    by_contra hnot
    apply hχ
    ext g
    have hall : ∀ x : G, χ x = 1 := by
      intro x
      by_contra hx
      exact hnot ⟨x, hx⟩
    simpa using hall g

  let S : ℂ := ∑ g : G, (χ g : ℂ)

  -- Reindex by the permutation g ↦ h * g
  have hperm :
      ∑ g : G, (χ (h * g) : ℂ) = ∑ g : G, (χ g : ℂ) := by
    simpa using
      (Fintype.sum_bijective (fun g : G => h * g)
        (Function.bijective_iff_has_inverse.mpr
          ⟨fun g => h⁻¹ * g, by intro g; simp [mul_assoc], by intro g; simp [mul_assoc]⟩))

  -- Hence χ h * S = S
  have hmulS : (χ h : ℂ) * S = S := by
    calc
      (χ h : ℂ) * S = (χ h : ℂ) * ∑ g : G, (χ g : ℂ) := by rfl
      _ = ∑ g : G, (χ h : ℂ) * (χ g : ℂ) := by
            simp [S, mul_sum]
      _ = ∑ g : G, (χ (h * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            simpa using (map_mul χ h g).symm
      _ = ∑ g : G, (χ g : ℂ) := hperm
      _ = S := by rfl

  have hχh_ne_zero : (χ h : ℂ) - 1 ≠ 0 := by
    intro h0
    apply hh
    apply Sub_eq_zero.mp
    exact_mod_cast h0

  have hfactor : ((χ h : ℂ) - 1) * S = 0 := by
    calc
      ((χ h : ℂ) - 1) * S = (χ h : ℂ) * S - 1 * S := by ring
      _ = S - S := by simpa [hmulS]
      _ = 0 := by ring

  have hSzero : S = 0 := by
    exact mul_eq_zero.mp hfactor |> Or.resolve_left hχh_ne_zero

  simpa [S] using hSzero

end T1
end TemTH
