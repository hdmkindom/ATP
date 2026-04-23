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
  let ψ : AddChar (ZMod N) ℂ :=
    zmodChar N ((IsPrimitiveRoot.iff_def root.ζ N).mp root.isPrimitive).1
  have hψprim : ψ.IsPrimitive := by
    simpa [ψ] using AddChar.zmodChar_primitive_of_primitive_root (n := N) root.isPrimitive
  have hsum : ∑ x : ZMod N, ψ (x * (a : ZMod N)) = 0 := by
    simpa [ha] using AddChar.sum_mulShift (ψ := ψ) (b := (a : ZMod N)) hψprim
  have hchar : ∀ x : Fin N, cyclicChar root a x = ψ ((x : ZMod N) * (a : ZMod N)) := by
    intro x
    simp [ψ, cyclicChar, zmodChar]
  simpa [hchar] using hsum

end T3
end TemTH
