/-
`temTH` 模板：`T5` 自由模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import CandidateTheorems.T5.Support

open scoped BigOperators

namespace TemTH
namespace T5

open CandidateTheorems.T3
open CandidateTheorems.T5

variable {N : ℕ} [NeZero N]

theorem candidate_T5_free (root : PrimitiveNthRoot (N := N)) (t : Fin N) :
    delta0 (N := N) t = (1 / (N : ℂ)) * ∑ a : Fin N, cyclicChar root a t := by
  by_cases ht : t = 0
  · subst ht
    rw [delta0]
    simp [cyclicChar, Finset.sum_const, Fintype.card_fin, one_div]
  · rw [delta0, if_neg ht]
    have hsum_zero : ∑ a : Fin N, cyclicChar root a t = 0 := by
      simpa [cyclicChar] using AddChar.sum_apply_eq_zero_iff_ne_zero (a := t)
    rw [hsum_zero]
    simp

end T5
end TemTH
