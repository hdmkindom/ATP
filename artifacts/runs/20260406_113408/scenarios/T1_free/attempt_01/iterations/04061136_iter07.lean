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
  by_contra hsum
  have h_exists : ∃ h : G, χ h ≠ 1 := by
    by_contra hnone
    apply hχ
    ext g
    have hg : χ g = 1 := by
      by_contra hne
      exact hnone ⟨g, hne⟩
    exact congrArg (fun z : ℂˣ => (z : ℂ)) hg
  rcases h_exists with ⟨h, hh⟩
  have hmul : (χ h : ℂ) * (∑ g : G, (χ g : ℂ)) = ∑ g : G, (χ g : ℂ) := by
    calc
      (χ h : ℂ) * (∑ g : G, (χ g : ℂ))
          = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
              rw [mul_sum]
      _ = ∑ g : G, (χ (h * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            exact congrArg (fun z : ℂˣ => (z : ℂ)) (map_mul χ h g).symm
      _ = ∑ g : G, (χ g : ℂ) := by
            simpa using Fintype.sum_bijective (fun g : G => h * g)
              (fun _ _ => rfl) (fun g => h⁻¹ * g) (by intro g; simp) (by intro g; simp)
  have hχh_ne : (χ h : ℂ) ≠ 1 := by
    intro hcast
    apply hh
    ext
    exact hcast
  have hsub_ne_zero : (χ h : ℂ) - 1 ≠ 0 := by
    intro hz
    apply hχh_ne
    linarith
  have hmain : ((χ h : ℂ) - 1) * (∑ g : G, (χ g : ℂ)) = 0 := by
    calc
      ((χ h : ℂ) - 1) * (∑ g : G, (χ g : ℂ))
          = (χ h : ℂ) * (∑ g : G, (χ g : ℂ)) - ∑ g : G, (χ g : ℂ) := by ring
      _ = (∑ g : G, (χ g : ℂ)) - ∑ g : G, (χ g : ℂ) := by rw [hmul]
      _ = 0 := sub_self _
  have hzero : ((χ h : ℂ) - 1) = 0 := by
    exact eq_zero_of_mul_right_eq_zero hsum hmain
  exact hsub_ne_zero hzero

end T1
end TemTH
