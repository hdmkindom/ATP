/-
`temTH` 模板：`T3` 禁用模式。
-/
import CandidateTheorems.T3.PrimitiveRoot

open scoped BigOperators

namespace TemTH
namespace T3

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T3_disable (root : PrimitiveNthRoot (N := N)) {a : Fin N} (ha : a ≠ 0) :
    ∑ x : Fin N, cyclicChar root a x = 0 := by
  classical
  simpa [cyclicChar] using AddChar.sum_mulShift (R := ZMod N)
    (R' := CyclotomicField N ℚ) (ψ := root.toAddChar) (b := (a : ZMod N)) root.toAddChar_isPrimitive

end T3
end TemTH
