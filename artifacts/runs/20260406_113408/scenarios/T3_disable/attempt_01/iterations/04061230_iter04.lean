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
  let ψ : AddChar (ZMod N) ℂ :=
    AddChar.zmodChar N ((IsPrimitiveRoot.iff_def root.ζ N).mp root.isPrimitive).1
  have hprim : ψ.IsPrimitive :=
    AddChar.zmodChar_primitive_of_primitive_root (n := N) root.isPrimitive
  have hsum : ∑ x : ZMod N, ψ (x * (a : ZMod N)) = 0 := by
    simpa [ha] using AddChar.sum_mulShift (R := ZMod N) (R' := ℂ) (ψ := ψ) (b := (a : ZMod N)) hprim
  simpa [cyclicChar, ψ] using hsum

end T3
end TemTH
