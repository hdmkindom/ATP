/-
`temTH` 模板：`T5` 禁用模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import CandidateTheorems.T5.Support
import Mathlib.NumberTheory.RootsOfUnity.Basic

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
      ∑ a : Fin N, cyclicChar root a t = if t = 0 then (N : ℂ) else 0 := by
    simpa using root.sum_cyclicChar (t := t)
  by_cases ht : t = 0
  · subst ht
    rw [hsum]
    norm_num [delta0]
  · rw [hsum]
    simp [delta0, ht]

end T5
end TemTH
