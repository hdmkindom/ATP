/-
`temTH` 模板：`T4` 禁用模式。
-/
import CandidateTheorems.T3.PrimitiveRoot

open scoped BigOperators

namespace TemTH
namespace T4

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T4_disable (root : PrimitiveNthRoot (N := N)) (x : Fin N) :
    ∑ a : Fin N, cyclicChar root a x = if x = 0 then (N : ℂ) else 0 := by
  classical
  by_cases hx : x = 0
  · subst hx
    simp [cyclicChar]
  · have hprim : AddChar.IsPrimitive (AddChar.zmodChar N root.pow_eq_one) := by
      exact AddChar.zmodChar_primitive_of_primitive_root (n := N) root.isPrimitiveRoot
    have hsum := AddChar.sum_mulShift (R := ZMod N) (R' := ℂ)
      (ψ := AddChar.zmodChar N root.pow_eq_one) (b := (x : ZMod N)) hprim
    have hx' : ((x : ZMod N) ≠ 0) := by
      simpa using hx
    have hif : (if (x : ZMod N) = 0 then (Fintype.card (ZMod N) : ℂ) else 0) = 0 := by
      simp [hx']
    have hcard : (Fintype.card (ZMod N) : ℂ) = (N : ℂ) := by simp
    simpa [cyclicChar, hif, hcard, Fin.ext_iff] using hsum

end T4
end TemTH
