/-
`temTH` 模板：`T3` 自由模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import Mathlib.NumberTheory.RootsOfUnity.Basic

open scoped BigOperators

namespace TemTH
namespace T3

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T3_free (root : PrimitiveNthRoot (N := N)) {a : Fin N} (ha : a ≠ 0) :
    ∑ x : Fin N, cyclicChar root a x = 0 := by
  classical
  let ζ : ℂ := root.ζ ^ (a : ℕ)
  have hsum : ∑ x : Fin N, cyclicChar root a x = ∑ i in Finset.range N, ζ ^ i := by
    simp [ζ, cyclicChar]
  have hζ_prim : IsPrimitiveRoot ζ N := by
    simpa [ζ] using root.isPrimitiveRoot.pow (show Nat.Coprime (a : ℕ) N from a.isCoprime)
  have hN_gt_one : 1 < N := by
    by_contra hle
    have hN_eq_one : N = 1 := by omega
    subst hN_eq_one
    have : a = 0 := by
      exact Fin.eq_zero _
    exact ha this
  rw [hsum]
  simpa using hζ_prim.geom_sum_eq_zero hN_gt_one

end T3
end TemTH
