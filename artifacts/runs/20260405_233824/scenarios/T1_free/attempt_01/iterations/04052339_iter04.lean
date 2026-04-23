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
  have hne_one_val : ∃ h : G, χ h ≠ 1 := by
    by_contra hforall
    apply hχ
    ext g
    specialize hforall g
    exact hforall
  rcases hne_one_val with ⟨h, hh⟩
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have hS_ne : S ≠ 0 := by
    simpa [S] using hsum
  have hmul : (χ h : ℂ) * S = S := by
    dsimp [S]
    calc
      (χ h : ℂ) * (∑ g : G, (χ g : ℂ))
          = ∑ g : G, ((χ h : ℂ) * (χ g : ℂ)) := by
              simpa using Finset.mul_sum (χ h : ℂ) (fun g : G => (χ g : ℂ))
      _ = ∑ g : G, (χ (h * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            norm_num [map_mul]
      _ = ∑ g : G, (χ g : ℂ) := by
            simpa using
              (Fintype.sum_bijective (fun g : G => h * g) (mul_left_bijective h)
                (fun g => (χ g : ℂ)))
      _ = S := by rfl
  have hχh_eq_one : (χ h : ℂ) = 1 := by
    apply mul_right_cancel₀ hS_ne
    simpa [one_mul] using hmul
  exact hh (by
    apply Subtype.ext
    exact hχh_eq_one)

end T1
end TemTH
