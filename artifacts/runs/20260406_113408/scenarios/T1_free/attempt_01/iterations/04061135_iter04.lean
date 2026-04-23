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
  by_cases hG : Nonempty G
  · let S : ℂ := ∑ g : G, (χ g : ℂ)
    have h_exists : ∃ h : G, χ h ≠ 1 := by
      by_contra hno
      apply hχ
      ext g
      push_neg at hno
      exact hno g
    rcases h_exists with ⟨h, hh⟩
    have hmul : (χ h : ℂ) * S = S := by
      dsimp [S]
      calc
        (χ h : ℂ) * ∑ g : G, (χ g : ℂ)
            = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
                rw [Finset.mul_sum]
        _ = ∑ g : G, ((χ (h * g) : ℂ)) := by
              refine Finset.sum_congr rfl ?_
              intro g _
              norm_num
              rw [map_mul]
        _ = ∑ g : G, (χ g : ℂ) := by
              exact Finset.sum_bijective (fun g => h * g) (by intro g; simp)
    have hχh_ne_zero : (χ h : ℂ) - 1 ≠ 0 := by
      intro hz
      apply hh
      have : (χ h : ℂ) = 1 := sub_eq_zero.mp hz
      exact_mod_cast this
    have hmain : ((χ h : ℂ) - 1) * S = 0 := by
      calc
        ((χ h : ℂ) - 1) * S = (χ h : ℂ) * S - S := by ring
        _ = S - S := by rw [hmul]
        _ = 0 := sub_self S
    have hS : S = 0 := by
      apply eq_of_mul_eq_mul_left ?_
      · exact hχh_ne_zero
      · simpa [S] using hmain
    simpa [S] using hS
  · exfalso
    exact hG (Classical.choice inferInstance)

end T1
end TemTH
