/-
`temTH` 模板：`T5` 自由模式。
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
    have hprim : AddChar.IsPrimitive (fun x : ZMod N => root.val ^ x.val) := by
      simpa [PrimitiveNthRoot, cyclicChar] using
        AddChar.zmodChar_primitive_of_primitive_root N root.isPrimitive
    have hsumZMod : ∑ x : ZMod N, root.val ^ (x * (t : ZMod N)).val = 0 := by
      simpa using AddChar.sum_mulShift (R := ZMod N) (R' := ℂ)
        (ψ := fun x : ZMod N => root.val ^ x.val) (b := (t : ZMod N)) hprim
    have htZ : (t : ZMod N) ≠ 0 := by
      simpa using ht
    have hsum : ∑ a : Fin N, cyclicChar root a t = 0 := by
      simpa [cyclicChar] using hsumZMod
    rw [hsum]
    simp

end T5
end TemTH
