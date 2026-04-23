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
    simp [cyclicChar]
  · simpa [cyclicChar, hx] using root.zeta_spec.geom_sum_eq_zero (k := N) (hk := by
      have hN : 0 < N := Nat.pos_of_ne_zero (NeZero.ne N)
      omega)

end T4
end TemTH
