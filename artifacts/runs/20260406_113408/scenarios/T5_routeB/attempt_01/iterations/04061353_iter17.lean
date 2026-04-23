/-
`temTH` 模板：`T5` 路线 B。
-/
import CandidateTheorems.T5.Support

open scoped BigOperators

namespace TemTH
namespace T5

open CandidateTheorems.T5

variable {N : ℕ} [NeZero N]

theorem candidate_T5_routeB
    (data : FourierInversionData (N := N)) (t : Fin N) :
    delta0 (N := N) t = (1 / (N : ℂ)) * ∑ a : Fin N, data.ψ a t := by
  rw [delta0]
  have hsum : ∑ a : Fin N, data.ψ a t = if t = 0 then (N : ℂ) else 0 := by
    simpa using (AddChar.sum_apply_eq_ite (a := t))
  rw [hsum]
  by_cases ht : t = 0
  · rw [if_pos ht]
    have hN : ((N : ℂ) ≠ 0) := by
      exact_mod_cast (NeZero.ne N)
    field_simp [hN]
  · rw [if_neg ht]
    simp [ht]

end T5
end TemTH
