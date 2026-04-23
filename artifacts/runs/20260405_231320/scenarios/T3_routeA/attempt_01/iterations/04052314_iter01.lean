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
  simpa [cyclicChar_eq_geomSum] using geomSum_eq_zero_of_ne_one (root := root) (a := a) ha

end T3
end TemTH
