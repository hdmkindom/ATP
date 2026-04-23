/-
`temTH` 模板：`T4` 路线 B。
-/
import CandidateTheorems.T4.RouteB

open scoped BigOperators

namespace TemTH
namespace T4

open CandidateTheorems.T4

variable {N : ℕ} [NeZero N]

theorem candidate_T4_routeB (root : PrimitiveNthRoot (N := N)) (x : Fin N) :
    ∑ a : Fin N, cyclicChar root a x = if x = 0 then (N : ℂ) else 0 := by
  sorry

end T4
end TemTH
