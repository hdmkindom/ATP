/-
`temTH` 模板：`T7` 路线 B。
-/
import CandidateTheorems.T5.Support
import CandidateTheorems.T7.Support

open scoped BigOperators

namespace TemTH
namespace T7

open CandidateTheorems.T7

variable {N : ℕ} [NeZero N]

theorem candidate_T7_routeB (root : PrimitiveNthRoot (N := N)) (t x : Fin N) :
    deltaAt (N := N) t x =
      (1 / (N : ℂ)) * ∑ a : Fin N, cyclicChar root a (cyclicSub x t) := by
  sorry

end T7
end TemTH
