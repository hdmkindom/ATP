/-
`temTH` 模板：`T3` 禁用模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import Mathlib.NumberTheory.LegendreSymbol.AddCharacter

open scoped BigOperators

namespace TemTH
namespace T3

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T3_disable (root : PrimitiveNthRoot (N := N)) {a : Fin N} (ha : a ≠ 0) :
    ∑ x : Fin N, cyclicChar root a x = 0 := by
  classical
  let ψ := root.toAddChar
  have hprim : AddChar.IsPrimitive ψ := root.toAddChar_isPrimitive
  have hsum : ∑ x : ZMod N, ψ (x * (a : ZMod N)) = 0 := by
    simpa [ha] using
      (AddChar.sum_mulShift (R := ZMod N)
        (R' := CyclotomicField N ℚ) (ψ := ψ) (b := (a : ZMod N)) hprim)
  simpa [ψ, cyclicChar] using hsum

end T3
end TemTH
