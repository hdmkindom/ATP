/-
`temTH` 模板：`T3` 自由模式。
-/
import CandidateTheorems.T3.PrimitiveRoot

open scoped BigOperators

namespace TemTH
namespace T3

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T3_free (root : PrimitiveNthRoot (N := N)) {a : Fin N} (ha : a ≠ 0) :
    ∑ x : Fin N, cyclicChar root a x = 0 := by
  classical
  simpa using root.sum_cyclicChar_eq_zero (a := a) ha

end T3
end TemTH
