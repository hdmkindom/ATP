/-
`temTH` 模板：`T7` 禁用模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import CandidateTheorems.T7.Support

open scoped BigOperators

namespace TemTH
namespace T7

open CandidateTheorems.T3
open CandidateTheorems.T7

variable {N : ℕ} [NeZero N]

theorem candidate_T7_disable (root : PrimitiveNthRoot (N := N)) (t x : Fin N) :
    deltaAt (N := N) t x =
      (1 / (N : ℂ)) * ∑ a : Fin N, cyclicChar root a (cyclicSub x t) := by
  simpa [deltaAt, cyclicSub] using
    (AddChar.expect_apply_eq_ite (α := Fin N) (R := ℂ) (a := cyclicSub x t)).symm

end T7
end TemTH
