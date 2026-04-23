/-
`temTH` 模板：`T5` 禁用模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import CandidateTheorems.T5.Support
import Mathlib.NumberTheory.AdditiveCharacters

open scoped BigOperators

namespace TemTH
namespace T5

open CandidateTheorems.T3
open CandidateTheorems.T5

variable {N : ℕ} [NeZero N]

theorem candidate_T5_disable (root : PrimitiveNthRoot (N := N)) (t : Fin N) :
    delta0 (N := N) t = (1 / (N : ℂ)) * ∑ a : Fin N, cyclicChar root a t := by
  classical
  have hsum : ∑ a : Fin N, cyclicChar root a t = if t = 0 then (N : ℂ) else 0 := by
    simpa [cyclicChar] using (AddChar.sum_apply_eq_ite (a := t) (α := Fin N))
  rw [hsum]
  by_cases ht : t = 0
  · subst ht
    have hN : (N : ℂ) ≠ 0 := by
      exact_mod_cast (NeZero.ne N)
    simp [delta0, hN]
  · simp [delta0, ht]

end T5
end TemTH
