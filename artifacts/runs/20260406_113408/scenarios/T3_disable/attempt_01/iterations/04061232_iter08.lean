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
  let ψ : AddChar (ZMod N) ℂ :=
    AddChar.zmodChar N ((IsPrimitiveRoot.iff_def root.zeta N).mp root.isPrimitive).1
  have hψprim : ψ.IsPrimitive := by
    simpa [ψ] using AddChar.zmodChar_primitive_of_primitive_root (n := N) root.isPrimitive
  have hmul : (a : ZMod N) ≠ 0 := by
    exact_mod_cast ha
  have hsum : ∑ y : ZMod N, ψ (y * (a : ZMod N)) = 0 := by
    simpa [hmul] using AddChar.sum_mulShift (ψ := ψ) (b := (a : ZMod N)) hψprim
  have hchar : ∀ x : Fin N, cyclicChar root a x = ψ ((x : ZMod N) * (a : ZMod N)) := by
    intro x
    simp [cyclicChar, ψ, mul_comm, mul_left_comm, mul_assoc]
  have hsum' : ∑ x : Fin N, cyclicChar root a x = ∑ y : ZMod N, ψ (y * (a : ZMod N)) := by
    simp [hchar]
  rw [hsum']
  exact hsum

end T3
end TemTH
