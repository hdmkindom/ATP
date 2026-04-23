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
  by_cases ht : t = 0
  · subst ht
    simp [delta0, data.sum_psi_at_zero]
  · have hsum : ∑ a : Fin N, data.ψ a t = 0 := data.sum_psi_eq_zero_of_ne_zero ht
    simp [delta0, ht, hsum]

end T5
end TemTH
