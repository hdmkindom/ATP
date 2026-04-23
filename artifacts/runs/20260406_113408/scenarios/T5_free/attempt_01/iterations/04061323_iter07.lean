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
    rw [delta0, cyclicChar_sum_zero]
    have hN : (N : ℂ) ≠ 0 := by
      exact_mod_cast (show N ≠ 0 from NeZero.ne N)
    field_simp [hN]
  · rw [delta0, if_neg ht, cyclicChar_sum_of_ne_zero root ht]
    simp

end T5
end TemTH
