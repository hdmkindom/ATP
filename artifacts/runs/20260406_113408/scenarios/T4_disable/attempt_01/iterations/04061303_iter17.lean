/-
`temTH` 模板：`T4` 禁用模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import Mathlib.NumberTheory.LegendreSymbol.GaussSum

open scoped BigOperators

namespace TemTH
namespace T4

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T4_disable (root : PrimitiveNthRoot (N := N)) (x : Fin N) :
    ∑ a : Fin N, cyclicChar root a x = if x = 0 then (N : ℂ) else 0 := by
  classical
  let ψ : AddChar (ZMod N) ℂ := AddChar.zmodChar N root.pow_eq_one
  have hprim : AddChar.IsPrimitive ψ := by
    simpa [ψ] using AddChar.zmodChar_primitive_of_primitive_root N root.isPrimitive
  have hsum : ∑ a : ZMod N, ψ (a * (x : ZMod N)) = if (x : ZMod N) = 0 then (N : ℂ) else 0 := by
    simpa [ψ] using AddChar.sum_mulShift (R := ZMod N) (R' := ℂ) (ψ := ψ) (b := (x : ZMod N)) hprim
  have hcoex : ((x : ZMod N) = 0) ↔ x = 0 := by
    constructor
    · intro hx
      apply Fin.ext
      simpa using congrArg ZMod.val hx
    · intro hx
      simpa [hx]
  have hreindex :
      ∑ a : Fin N, cyclicChar root a x = ∑ a : ZMod N, ψ (a * (x : ZMod N)) := by
    refine Fintype.sum_equiv (Fin.castIso (by simp)) ?_
    intro a
    simp [cyclicChar, ψ, mul_comm]
  rw [hreindex, hsum]
  simp [hcoex]

end T4
end TemTH
