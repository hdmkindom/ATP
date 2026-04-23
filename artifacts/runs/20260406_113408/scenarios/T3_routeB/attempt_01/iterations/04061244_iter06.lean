/-
`temTH` 模板：`T3` 路线 B。
-/
import CandidateTheorems.T3.RouteB

open scoped BigOperators

namespace TemTH
namespace T3

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T3_routeB
    (data : AbstractAdditiveCharacterData (N := N)) {a : Fin N} (ha : a ≠ 0) :
    ∑ x : Fin N, data.ψ a x = 0 := by
  classical
  exact AddChar.sum_eq_zero_of_ne_one (ψ := data.ψ a) fun htriv =>
    ha <| data.psi_injective a (by simpa [AddChar.coe_eq_one] using htriv)

end T3
end TemTH
