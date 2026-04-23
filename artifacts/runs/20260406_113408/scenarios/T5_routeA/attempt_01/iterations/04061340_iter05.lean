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
  by_cases ht : t = 0
  · subst ht
    simp [delta0, cyclicChar]
    have hN : ((N : ℂ)) ≠ 0 := by
      exact_mod_cast (show N ≠ 0 from NeZero.ne N)
    field_simp [hN]
  · have hT4 := candidate_T4 (root := root) (t := t)
    rw [hT4]
    simp [delta0, ht]

end T5
end TemTH
