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
    simp [delta0, cyclicChar, Finset.sum_const, Fintype.card_fin, CandidateTheorems.T5.geomSum_zero]
  · have hsum : ∑ a : Fin N, cyclicChar root a t = 0 := by
      simpa [cyclicChar] using CandidateTheorems.T5.sum_cyclicChar_eq_zero_of_ne_zero (root := root) ht
    rw [hsum]
    simp [delta0, ht]

end T5
end TemTH
