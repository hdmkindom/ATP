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
  simpa [one_div] using (delta0_eq_avg_sum_cyclicChar (root := root) (t := t))

end T5
end TemTH
