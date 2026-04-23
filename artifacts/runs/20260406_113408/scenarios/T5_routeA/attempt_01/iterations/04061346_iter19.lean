/-
`temTH` 模板：`T5` 路线 A。
-/
import CandidateTheorems.T3.PrimitiveRoot
import CandidateTheorems.T5.Support
import Mathlib.NumberTheory.LegendreSymbol.GaussSum

open scoped BigOperators

namespace TemTH
namespace T5

open CandidateTheorems.T3
open CandidateTheorems.T5

variable {N : ℕ} [NeZero N]

theorem candidate_T5_routeA (root : PrimitiveNthRoot (N := N)) (t : Fin N) :
    delta0 (N := N) t = (1 / (N : ℂ)) * ∑ a : Fin N, cyclicChar root a t := by
  classical
  by_cases ht : t = 0
  · subst ht
    simp [delta0, cyclicChar]
    have hN0 : (N : ℂ) ≠ 0 := by
      exact_mod_cast (show N ≠ 0 from NeZero.ne N)
    rw [show (1 / (N : ℂ)) = ((N : ℂ)⁻¹) by rfl]
    exact (inv_mul_cancel₀ hN0).symm
  · have hsum : ∑ a : Fin N, cyclicChar root a t = 0 := by
      simpa [cyclicChar] using
        AddChar.sum_mulShift (R := Fin N) (R' := ℂ) (ψ := root.toAddChar) t root.isPrimitive
    rw [delta0, if_neg ht, hsum]
    simp

end T5
end TemTH
