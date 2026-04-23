/-
`temTH` 模板：`T7` 路线 A。
-/
import CandidateTheorems.T3.PrimitiveRoot
import CandidateTheorems.T7.Support

open scoped BigOperators

namespace TemTH
namespace T7

open CandidateTheorems.T3
open CandidateTheorems.T7

variable {N : ℕ} [NeZero N]

theorem candidate_T7_routeA (root : PrimitiveNthRoot (N := N)) (t x : Fin N) :
    deltaAt (N := N) t x =
      (1 / (N : ℂ)) * ∑ a : Fin N, cyclicChar root a (cyclicSub x t) := by
  by_cases htx : x = t
  · subst htx
    simp [deltaAt, cyclicSub]
  · have hneq : t ≠ x := by
      exact fun h => htx h.symm
    simp [deltaAt, cyclicSub, htx, hneq]


end T7
end TemTH
