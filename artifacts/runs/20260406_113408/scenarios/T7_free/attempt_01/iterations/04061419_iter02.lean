/-
`temTH` 模板：`T7` 自由模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import CandidateTheorems.T7.Support

open scoped BigOperators

namespace TemTH
namespace T7

open CandidateTheorems.T3
open CandidateTheorems.T7

variable {N : ℕ} [NeZero N]

theorem candidate_T7_free (root : PrimitiveNthRoot (N := N)) (t x : Fin N) :
    deltaAt (N := N) t x =
      (1 / (N : ℂ)) * ∑ a : Fin N, cyclicChar root a (cyclicSub x t) := by
  by_cases h : x = t
  · subst h
    simp [deltaAt, cyclicSub]
  · have hxt : x ≠ t := h
    have hsub : cyclicSub x t ≠ 0 := by
      simpa [cyclicSub] using hxt
    simp [deltaAt, hxt, hsub]


end T7
end TemTH
