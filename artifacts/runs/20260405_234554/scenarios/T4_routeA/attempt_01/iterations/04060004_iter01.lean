/-
`temTH` 模板：`T4` 路线 A。
-/
import CandidateTheorems.T3.PrimitiveRoot

open scoped BigOperators

namespace TemTH
namespace T4

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T4_routeA (root : PrimitiveNthRoot (N := N)) (x : Fin N) :
    ∑ a : Fin N, cyclicChar root a x = if x = 0 then (N : ℂ) else 0 := by
  by_cases hx : x = 0
  · subst hx
    simpa [cyclicChar_zero_right] using sum_cyclicChar_eq_card (root := root) (x := (0 : Fin N))
  · have hsum : ∑ a : Fin N, cyclicChar root a x = 0 :=
      sum_cyclicChar_eq_zero_of_ne_zero (root := root) (x := x) hx
    simpa [hx] using hsum

end T4
end TemTH
