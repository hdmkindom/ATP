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
  by_cases ht : t = 0
  · subst ht
    have hsum : ∑ a : Fin N, data.ψ a 0 = (N : ℂ) := by
      simpa using AddChar.sum_eq_ite (ψ := data.ψAt 0)
    rw [if_pos rfl]
    rw [hsum]
    field_simp
  · have hsum : ∑ a : Fin N, data.ψ a t = 0 := by
      have hne : data.ψAt t ≠ 0 := by
        simpa [data.ψAt, ht]
      simpa using AddChar.sum_eq_ite (ψ := data.ψAt t)
    rw [if_neg ht]
    rw [hsum]
    simp

end T5
end TemTH
