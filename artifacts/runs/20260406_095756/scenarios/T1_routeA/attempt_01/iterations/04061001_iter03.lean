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
    have hg : ¬ χ g ≠ 1 := by exact fun hg' => hnot ⟨g, hg'⟩
    exact not_not.mp hg

  let S : ℂ := ∑ g : G, (χ g : ℂ)

  have hmul : (χ h : ℂ) * S = S := by
    calc
      (χ h : ℂ) * S
          = (χ h : ℂ) * ∑ g : G, (χ g : ℂ) := by rfl
      _ = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
            simp [mul_sum]
      _ = ∑ g : G, (χ (h * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g _
            simpa using (map_mul χ h g)
      _ = ∑ g : G, (χ g : ℂ) := by
            simpa using
              (Fintype.sum_bijective (fun g : G => h * g)
                (Function.bijective_iff_has_inverse.mpr
                  ⟨fun g => h⁻¹ * g, by intro g; simp [mul_assoc], by intro g; simp [mul_assoc]⟩))
      _ = S := by rfl

  have hsub : S - (χ h : ℂ) * S = 0 := by
    rw [hmul, sub_self]

  have hone_sub : (1 - (χ h : ℂ)) * S = 0 := by
    simpa [sub_eq_add_neg, left_distrib, right_distrib, mul_assoc, add_comm, add_left_comm, add_assoc]
      using hsub

  have hcoeff_ne_zero : (1 - (χ h : ℂ)) ≠ 0 := by
    intro hzero
    apply hh
    linarith

  have hS_zero : S = 0 := by
    exact (mul_eq_zero.mp hone_sub).resolve_left hcoeff_ne_zero

  simpa [S] using hS_zero

end T1
end TemTH
