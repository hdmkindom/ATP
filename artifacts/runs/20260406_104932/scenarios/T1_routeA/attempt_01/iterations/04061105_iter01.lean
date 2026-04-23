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
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have hperm : ∑ g : G, (χ (hχ.some * g) : ℂ) = S := by
    simp [S]
  have hmul : ∑ g : G, (χ (hχ.some * g) : ℂ) = (χ hχ.some : ℂ) * S := by
    calc
      ∑ g : G, (χ (hχ.some * g) : ℂ)
          = ∑ g : G, ((χ hχ.some : ℂ) * (χ g : ℂ)) := by
              refine Finset.sum_congr rfl ?_
              intro g hg
              rw [map_mul]
      _ = (χ hχ.some : ℂ) * S := by
            simp [S, Finset.mul_sum]
  have hfixed : S = (χ hχ.some : ℂ) * S := by
    rw [← hperm]
    exact hmul
  have hone_ne : (χ hχ.some : ℂ) ≠ 1 := by
    intro h1
    apply hχ
    ext g
    have := congrArg (fun z : ℂ => z * (χ g : ℂ)) h1
    simp at this
    simpa using this
  have hzero_factor : (1 - (χ hχ.some : ℂ)) * S = 0 := by
    linarith [hfixed]
  have hfactor_ne : 1 - (χ hχ.some : ℂ) ≠ 0 := by
    intro h
    apply hone_ne
    linarith
  exact mul_eq_zero.mp (by simpa [sub_eq_add_neg, mul_add, add_mul] using hzero_factor) |>.resolve_left hfactor_ne

end T1
end TemTH
