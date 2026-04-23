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
  let ψ : AddChar (ZMod N) ℂ := AddChar.zmodChar N root.isPrimitiveRoot
  have hψprim : ψ.IsPrimitive := by
    simpa [ψ] using AddChar.zmodChar_primitive_of_primitive_root (n := N) root.isPrimitiveRoot
  have hsumZMod : ∑ x : ZMod N, ψ (x * (a : ZMod N)) = 0 := by
    simpa [ha] using (AddChar.sum_mulShift (R := ZMod N) (R' := ℂ) (ψ := ψ) (b := (a : ZMod N)) hψprim)
  simpa [ψ, cyclicChar] using hsumZMod

end T3
end TemTH
