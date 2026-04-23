/-
`temTH` 模板：`T3` 自由模式。
-/
import CandidateTheorems.T3.PrimitiveRoot

open scoped BigOperators

namespace TemTH
namespace T3

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T3_free (root : PrimitiveNthRoot (N := N)) {a : Fin N} (ha : a ≠ 0) :
    ∑ x : Fin N, cyclicChar root a x = 0 := by
  classical
  let ψ : AddChar (ZMod N) ℂ := AddChar.zmodChar N root.isPrimitiveRoot
  have hψ : ψ.IsPrimitive := AddChar.zmodChar_primitive_of_primitive_root N root.isPrimitiveRoot
  have hsum := AddChar.sum_mulShift (R := ZMod N) (R' := ℂ) a hψ
  have ha' : (a : ZMod N) ≠ 0 := ha
  simp [ψ, cyclicChar, ha'] at hsum
  simpa using hsum

end T3
end TemTH
