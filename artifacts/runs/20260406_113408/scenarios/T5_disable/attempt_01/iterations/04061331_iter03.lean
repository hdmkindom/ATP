/-
`temTH` 模板：`T5` 禁用模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import CandidateTheorems.T5.Support

open scoped BigOperators

namespace TemTH
namespace T5

open CandidateTheorems.T3
open CandidateTheorems.T5

variable {N : ℕ} [NeZero N]

theorem candidate_T5_disable (root : PrimitiveNthRoot (N := N)) (t : Fin N) :
    delta0 (N := N) t = (1 / (N : ℂ)) * ∑ a : Fin N, cyclicChar root a t := by
  classical
  have hsum :
      ∑ a : Fin N, cyclicChar root a t =
        if t = 0 then (N : ℂ) else 0 := by
    simpa [cyclicChar, PrimitiveNthRoot.toAddChar_apply, Fin.ext_iff] using
      AddChar.sum_apply_eq_ite (α := ZMod N) (R := ℂ) (a := (t : ZMod N))
  by_cases ht : t = 0
  · subst ht
    simp [delta0, hsum]
  · have ht0 : ¬((t : ZMod N) = 0) := by
      simpa [Fin.ext_iff] using ht
    simp [delta0, ht, hsum, ht0]

end T5
end TemTH
