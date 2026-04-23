/-
`temTH` 模板：`T4` 自由模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import Mathlib.NumberTheory.LegendreSymbol.GaussSum

open scoped BigOperators

namespace TemTH
namespace T4

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T4_free (root : PrimitiveNthRoot (N := N)) (x : Fin N) :
    ∑ a : Fin N, cyclicChar root a x = if x = 0 then (N : ℂ) else 0 := by
  classical
  by_cases hx : x = 0
  · simp [hx, cyclicChar]
  · have hprim : AddChar.IsPrimitive (fun y : ZMod N => root.ζ ^ y.val) := by
      simpa [AddChar.zmodChar_apply] using
        (AddChar.zmodChar_primitive_of_primitive_root (n := N) (ζ := root.ζ) root.isPrimitive)
    have hsum := AddChar.sum_mulShift (R := ZMod N) (R' := ℂ)
      (ψ := fun y : ZMod N => root.ζ ^ y.val) (b := (x : ZMod N)) hprim
    have hx' : ((x : ZMod N) = 0) = False := by
      apply propext
      constructor
      · intro h
        exact (hx (Fin.ext h))
      · intro hfalse
        cases hfalse
    simpa [cyclicChar, hx, hx'] using hsum

end T4
end TemTH
