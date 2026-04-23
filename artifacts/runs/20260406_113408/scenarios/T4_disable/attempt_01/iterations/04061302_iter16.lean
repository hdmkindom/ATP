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
  let ψ : AddChar (ZMod N) ℂ := root.toAddChar.mulShift (x : ZMod N)
  have hsum : ∑ a : ZMod N, ψ a = if (x : ZMod N) = 0 then (N : ℂ) else 0 := by
    simpa [ψ] using
      (AddChar.sum_mulShift (R := ZMod N) (R' := ℂ) (ψ := root.toAddChar)
        (b := (x : ZMod N)) root.toAddChar_isPrimitive)
  have hcoe : (x : ZMod N) = 0 ↔ x = 0 := by
    exact Fin.ext_iff.mp
      ((show ((x : Fin N).val : ZMod N) = ((0 : Fin N).val : ZMod N) ↔ x = 0 from by
        simpa using (Fin.val_injective.eq_iff' : x.val = (0 : Fin N).val ↔ x = 0)))
  simpa [cyclicChar, AddChar.mulShift, hcoe] using hsum

end T4
end TemTH
