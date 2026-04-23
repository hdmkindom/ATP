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
    by_contra hg
    exact hnot ⟨g, hg⟩

  let S : ℂ := ∑ g : G, (χ g : ℂ)

  have hmul : (χ h : ℂ) * S = S := by
    calc
      (χ h : ℂ) * S = (χ h : ℂ) * ∑ g : G, (χ g : ℂ) := by rfl
      _ = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
            simp [S, Finset.mul_sum]
      _ = ∑ g : G, (χ (h * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g _
            simpa using (map_mul χ h g)
      _ = ∑ g : G, (χ g : ℂ) := by
            simpa using
              (Fintype.sum_bijective (fun g : G => h * g)
                (Function.bijective_iff_has_inverse.mpr
                  ⟨fun g => h⁻¹ * g,
                    by intro g; simp [mul_assoc],
                    by intro g; simp [mul_assoc]⟩)
                (fun g => (χ g : ℂ)))
      _ = S := by rfl

  have hone_sub : (1 - (χ h : ℂ)) * S = 0 := by
    have : S - (χ h : ℂ) * S = 0 := by simpa [hmul] using sub_self S
    simpa [sub_eq_add_neg, add_comm, add_left_comm, add_assoc, left_distrib, right_distrib, mul_assoc]
      using this

  have hcoeff_ne_zero : (1 - (χ h : ℂ)) ≠ 0 := by
    intro hzero
    apply hh
    apply Complex.ofReal_injective
    have hzero' : ((1 - (χ h : ℂ)) : ℂ) = 0 := hzero
    linarith

  have hS_zero : S = 0 := by
    exact (mul_eq_zero.mp hone_sub).resolve_left hcoeff_ne_zero

  simpa [S] using hS_zero

end T1
end TemTH
