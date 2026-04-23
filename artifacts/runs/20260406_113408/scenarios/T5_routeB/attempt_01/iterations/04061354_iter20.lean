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
    rw [delta0]
    simp only [if_pos rfl]
    rw [AddChar.sum_apply_eq_ite]
    simp
  · rw [delta0]
    simp only [if_neg ht]
    rw [AddChar.sum_apply_eq_ite]
    simp [ht]

end T5
end TemTH
