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
    simp [delta0, cyclicChar, Finset.sum_const, Nat.smul_def, mul_assoc, mul_left_comm, mul_comm]
  · have hsum : ∑ a : Fin N, cyclicChar root a t = 0 := by
      simpa [cyclicChar] using root.geom_sum_eq_zero (t := t) ht
    rw [hsum]
    simp [delta0, ht]

end T5
end TemTH
