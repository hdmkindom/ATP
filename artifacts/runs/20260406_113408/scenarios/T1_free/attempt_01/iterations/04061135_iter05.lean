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
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have h_exists : ∃ h : G, χ h ≠ 1 := by
    by_contra hnone
    apply hχ
    ext g
    have hg : χ g = 1 := by
      by_contra hne
      exact hnone ⟨g, hne⟩
    change ((χ g : ℂ) = (1 : ℂ))
    simpa using congrArg (fun z : ℂˣ => (z : ℂ)) hg
  rcases h_exists with ⟨h, hh⟩
  have hmul : (χ h : ℂ) * S = S := by
    dsimp [S]
    calc
      (χ h : ℂ) * ∑ g : G, (χ g : ℂ)
          = ∑ g : G, (χ h : ℂ) * (χ g : ℂ) := by
              simp [mul_sum]
      _ = ∑ g : G, (χ (h * g) : ℂ) := by
            refine congrArg (fun t : ℂ => t) ?_
            refine Fintype.sum_congr ?_
            intro g
            simp
      _ = ∑ g : G, (χ g : ℂ) := by
            exact Function.Bijective.sum_comp (Group.mulLeft_bijective h) (fun g : G => (χ g : ℂ))
  have hχh_ne : (χ h : ℂ) ≠ 1 := by
    intro hcast
    apply hh
    ext
    exact hcast
  have hsub_ne_zero : (χ h : ℂ) - 1 ≠ 0 := by
    intro hz
    apply hχh_ne
    linarith
  have hmain : ((χ h : ℂ) - 1) * S = 0 := by
    calc
      ((χ h : ℂ) - 1) * S = (χ h : ℂ) * S - S := by ring
      _ = S - S := by rw [hmul]
      _ = 0 := sub_self S
  have hS : S = 0 := by
    apply Or.resolve_left (eq_zero_or_eq_zero_of_mul_eq_zero hmain)
    exact hsub_ne_zero
  simpa [S] using hS

end T1
end TemTH
