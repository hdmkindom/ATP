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
  -- Pick an element where χ is not 1.
  obtain ⟨h, hh⟩ : ∃ h : G, χ h ≠ 1 := by
    by_contra hforall
    apply hχ
    ext g
    by_contra hne
    exact hforall ⟨g, hne⟩

  let S : ℂ := ∑ g : G, (χ g : ℂ)

  have hmul : (χ h : ℂ) * S = S := by
    calc
      (χ h : ℂ) * S
          = (χ h : ℂ) * ∑ g : G, (χ g : ℂ) := by rfl
      _ = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
            rw [Finset.mul_sum]
      _ = ∑ g : G, (χ (h * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            norm_num [map_mul]
      _ = ∑ g : G, (χ g : ℂ) := by
            exact Fintype.sum_bijective (fun g : G => h * g) (by intro g; simp)
      _ = S := by rfl

  have hone_sub : (1 - (χ h : ℂ)) * S = 0 := by
    have hs' : S - (χ h : ℂ) * S = 0 := by
      linarith [hmul]
    simpa [sub_eq_add_neg, add_comm, add_left_comm, add_assoc, left_distrib, right_distrib,
      mul_comm, mul_left_comm, mul_assoc] using hs'

  have hχh_ne_one : (χ h : ℂ) ≠ 1 := by
    exact hh

  have hcoeff_ne_zero : (1 - (χ h : ℂ)) ≠ 0 := by
    intro hzero
    apply hχh_ne_one
    linarith

  have hS_zero : S = 0 := by
    exact mul_eq_zero.mp hone_sub |> Or.resolve_left hcoeff_ne_zero

  simpa [S] using hS_zero

end T1
end TemTH
