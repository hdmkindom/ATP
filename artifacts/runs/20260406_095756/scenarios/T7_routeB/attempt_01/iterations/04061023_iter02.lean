/-
`temTH` 模板：`T7` 路线 B。
-/
import CandidateTheorems.T5.Support
import CandidateTheorems.T7.Support

open scoped BigOperators

namespace TemTH
namespace T7

open CandidateTheorems.T7

variable {N : ℕ} [NeZero N]

theorem candidate_T7_routeB
    (data : CandidateTheorems.T5.FourierInversionData (N := N)) (t x : Fin N) :
    deltaAt (N := N) t x =
      (1 / (N : ℂ)) * ∑ a : Fin N, data.ψ a (cyclicSub x t) := by
  have delta_zero_at_shift :
      deltaAt (N := N) (0 : Fin N) (cyclicSub x t) =
        (1 / (N : ℂ)) * ∑ a : Fin N, data.ψ a (cyclicSub x t) := by
    simpa using data.delta_zero_expand (cyclicSub x t)
  simpa [deltaAt_as_deltaZero_sub] using delta_zero_at_shift

end T7
end TemTH
