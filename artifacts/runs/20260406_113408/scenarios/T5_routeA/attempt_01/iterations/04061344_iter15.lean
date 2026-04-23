/-
`temTH` 模板：`T5` 路线 A。
-/
import CandidateTheorems.T3.PrimitiveRoot
import CandidateTheorems.T5.Support

open scoped BigOperators

namespace TemTH
namespace T5

open CandidateTheorems.T3
open CandidateTheorems.T5

variable {N : ℕ} [NeZero N]

theorem candidate_T5_routeA (root : PrimitiveNthRoot (N := N)) (t : Fin N) :
    delta0 (N := N) t = (1 / (N : ℂ)) * ∑ a : Fin N, cyclicChar root a t := by
  classical
  by_cases ht : t = 0
  · subst ht
    simp [delta0, cyclicChar]
    symm
    exact inv_mul_cancel₀ (N : ℂ)
  · have hsum : ∑ a : Fin N, cyclicChar root a t = 0 := by
      simpa [cyclicChar] using
        (AddChar.sum_apply_eq_zero_iff_ne_zero (α := Fin N) (a := t) (ψ := root.toAddChar)).2 ht
    rw [delta0, if_neg ht, hsum]
    simp

end T5
end TemTH
