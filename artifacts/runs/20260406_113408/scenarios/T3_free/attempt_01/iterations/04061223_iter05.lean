/-
`temTH` 模板：`T3` 自由模式。
-/
import CandidateTheorems.T3.PrimitiveRoot

open scoped BigOperators

namespace TemTH
namespace T3

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T3_free (root : PrimitiveNthRoot (N := N)) {a : Fin N} (ha : a ≠ 0) :
    ∑ x : Fin N, cyclicChar root a x = 0 := by
  classical
  let ζ := root.ζ ^ (a : ℕ)
  have hN1 : 1 < N := by
    by_contra h
    have hle : N ≤ 1 := Nat.le_of_not_gt h
    have : a = 0 := by
      apply Fin.ext
      have ha0 : a.1 = 0 := by omega
      simpa using ha0
    exact ha this
  have hprim : IsPrimitiveRoot ζ N := by
    simpa [ζ] using root.isPrimitiveRoot.pow_of_coprime (a : ℕ) a.isCoprime
  have hsum : ∑ i in Finset.range N, ζ ^ i = 0 :=
    IsPrimitiveRoot.geom_sum_eq_zero hprim hN1
  simpa [cyclicChar, ζ, Finset.sum_range] using hsum

end T3
end TemTH
