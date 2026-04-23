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
  simpa [mul_comm] using TemTH.T4.candidate_T4_routeA (N := N) root t

end T5
end TemTH
