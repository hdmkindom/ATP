/-
`temTH` 模板：`T5` 自由模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import CandidateTheorems.T5.Support
import Mathlib.NumberTheory.RootsOfUnity.Basic

open scoped BigOperators

namespace TemTH
namespace T5

open CandidateTheorems.T3
open CandidateTheorems.T5

variable {N : ℕ} [NeZero N]

theorem candidate_T5_free (root : PrimitiveNthRoot (N := N)) (t : Fin N) :
    delta0 (N := N) t = (1 / (N : ℂ)) * ∑ a : Fin N, cyclicChar root a t := by
  by_cases ht : t = 0
  · subst ht
    rw [delta0, if_pos rfl]
    have hsum : ∑ a : Fin N, cyclicChar root a 0 = (N : ℂ) := by
      simp [cyclicChar]
    rw [hsum]
    have hN0 : (N : ℂ) ≠ 0 := by
      exact_mod_cast (show N ≠ 0 from NeZero.ne N)
    rw [one_div]
    simpa [hN0] using (inv_mul_cancel₀ hN0).symm
  · rw [delta0, if_neg ht]
    have hprim : (root.toAddChar.char : AddChar (Fin N) ℂ).IsPrimitive := by
      simpa using root.toAddChar.prim
    have hsum_ite := AddChar.sum_mulShift (R := Fin N)
      (R' := ℂ) (ψ := (root.toAddChar.char : AddChar (Fin N) ℂ)) t hprim
    have hsum_zero : ∑ a : Fin N, cyclicChar root a t = 0 := by
      simpa [cyclicChar, ht] using hsum_ite
    rw [hsum_zero]
    simp

end T5
end TemTH
