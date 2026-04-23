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
  simpa [cyclicChar] using AddChar.sum_eq_zero_of_ne_one (R := ZMod N)
    (R' := ℂ) (ψ := AddChar.zmod N ((a : ZMod N))) (by
      simpa [AddChar.zmod_char_ne_one_iff] using ha)

end T3
end TemTH
