/-
`temTH` 模板：`T4` 禁用模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import Mathlib.NumberTheory.LegendreSymbol.AddChar

open scoped BigOperators

namespace TemTH
namespace T4

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T4_disable (root : PrimitiveNthRoot (N := N)) (x : Fin N) :
    ∑ a : Fin N, cyclicChar root a x = if x = 0 then (N : ℂ) else 0 := by
  simpa [cyclicChar, mul_comm] using
    (AddChar.sum_mulShift (R := ZMod N) (R' := ℂ)
      (ψ := root.toAddChar) (b := (x : ZMod N)) root.toAddChar_isPrimitive)

end T4
end TemTH
