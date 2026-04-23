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
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have hχ_ne_one_val : ∃ g0 : G, (χ g0 : ℂ) ≠ 1 := by
    by_contra hforall
    apply hχ
    ext g
    have : (χ g : ℂ) = 1 := by
      by_contra hg
      exact hforall ⟨g, hg⟩
    exact_mod_cast this
  rcases hχ_ne_one_val with ⟨g0, hg0⟩
  have hmul : (χ g0 : ℂ) * S = S := by
    calc
      (χ g0 : ℂ) * S
          = (χ g0 : ℂ) * ∑ g : G, (χ g : ℂ) := rfl
      _ = ∑ g : G, ((χ g0 : ℂ) * (χ g : ℂ)) := by
            simp
      _ = ∑ g : G, (χ (g0 * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            simpa using (map_mul χ g0 g)
      _ = ∑ g : G, (χ g : ℂ) := by
            simpa using Fintype.sum_bijective (fun g : G => g0 * g)
      _ = S := rfl
  have hfactor : ((χ g0 : ℂ) - 1) * S = 0 := by
    calc
      ((χ g0 : ℂ) - 1) * S = (χ g0 : ℂ) * S - S := by ring
      _ = S - S := by simpa [hmul]
      _ = 0 := sub_self S
  have hS0 : S = 0 := (mul_eq_zero.mp hfactor).resolve_left (sub_ne_zero.mpr hg0)
  exact hsum (by simpa [S] using hS0)

end T1
end TemTH
