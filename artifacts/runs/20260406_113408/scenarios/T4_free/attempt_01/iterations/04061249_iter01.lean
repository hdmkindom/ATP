/-
`temTH` 模板：`T4` 自由模式。
-/
import CandidateTheorems.T3.PrimitiveRoot

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
  · have hprim : (fun a : ZMod N => cyclicChar root ⟨a.val, a.is_lt⟩ x) =
      AddMonoidAlgebra.zero := by
      ext a
      simp
    have hsum := AddChar.sum_mulShift (R := ZMod N)
      (R' := ℂ)
      (ψ := fun a => cyclicChar root ⟨a.val, a.is_lt⟩ 1) x
      ?_ ?_
    · simpa [hx] using hsum
    · simpa using root.isPrimitive
    · ext a
      simp [cyclicChar, Fin.ext_iff]

end T4
end TemTH
