/-
`temTH` 模板：`T4` 路线 A。
-/
import CandidateTheorems.T3.PrimitiveRoot
import Mathlib.NumberTheory.RootsOfUnity.Basic

open scoped BigOperators

namespace TemTH
namespace T4

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T4_routeA (root : PrimitiveNthRoot (N := N)) (x : Fin N) :
    ∑ a : Fin N, cyclicChar root a x = if x = 0 then (N : ℂ) else 0 := by
  simpa using AddChar.sum_mulShift (R := Fin N) (R' := ℂ) (ψ := cyclicChar root ·) x root.isPrimitive

end T4
end TemTH
