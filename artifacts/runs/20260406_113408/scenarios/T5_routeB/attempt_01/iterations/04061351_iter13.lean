/-
`temTH` 模板：`T5` 路线 B。
-/
import CandidateTheorems.T5.Support
import Mathlib.NumberTheory.LegendreSymbol.AddCharacter

open scoped BigOperators

namespace TemTH
namespace T5

open CandidateTheorems.T5

variable {N : ℕ} [NeZero N]

theorem candidate_T5_routeB
    (data : FourierInversionData (N := N)) (t : Fin N) :
    delta0 (N := N) t = (1 / (N : ℂ)) * ∑ a : Fin N, data.ψ a t := by
  rw [delta0]
  simpa [one_div] using
    (AddChar.expect_apply_eq_ite (α := Fin N) (a := t)).symm

end T5
end TemTH
