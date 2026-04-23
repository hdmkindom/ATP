/-
`temTH` 模板：`T4` 路线 B。
-/
import CandidateTheorems.T4.RouteB

open scoped BigOperators

namespace TemTH
namespace T4

open CandidateTheorems.T4

variable {N : ℕ} [NeZero N]

theorem candidate_T4_routeB
    (data : AdditiveOrthogonalityData (N := N)) (x : Fin N) :
    ∑ a : Fin N, data.ψ a x = if x = 0 then (N : ℂ) else 0 := by
  simpa [Fintype.card_fin] using
    (AddChar.sum_eq_ite (ψ := data.toAddChar x))

end T4
end TemTH
