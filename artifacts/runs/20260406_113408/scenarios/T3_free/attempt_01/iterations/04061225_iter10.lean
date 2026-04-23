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
  have hNgt1 : 1 < N := by
    by_contra h
    have hle : N ≤ 1 := Nat.le_of_not_gt h
    have hEq : N = 1 := by omega
    subst hEq
    have : a = 0 := by
      ext
      simp
    exact ha this
  simpa [cyclicChar] using
    IsPrimitiveRoot.geom_sum_eq_zero
      (hζ := root.isPrimitiveRoot.pow_of_coprime a.val (by
        simpa [Nat.Coprime, Fin.eq_zero_iff] using root.isUnit_iff_ne_zero a ha))
      (hk := hNgt1)

end T3
end TemTH
