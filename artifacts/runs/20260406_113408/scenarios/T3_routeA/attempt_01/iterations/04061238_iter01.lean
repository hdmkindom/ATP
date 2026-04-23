/-
`temTH` 模板：`T3` 路线 A。
-/
import CandidateTheorems.T3.PrimitiveRoot

open scoped BigOperators

namespace TemTH
namespace T3

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T3_routeA (root : PrimitiveNthRoot (N := N)) {a : Fin N} (ha : a ≠ 0) :
    ∑ x : Fin N, cyclicChar root a x = 0 := by
  classical
  simpa [cyclicChar] using root.isPrimitiveRoot.geom_sum_eq_zero (by
    have hN : 0 < N := Nat.pos_of_ne_zero (NeZero.ne N)
    omega)

end T3
end TemTH
