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
  by_cases hN1 : N = 1
  · subst hN1
    exfalso
    apply ha
    ext
    simp
  · have hNlt : 1 < N := by
      omega
    have hcoprime : Nat.Coprime a.1 N := by
      simpa [Fin.isUnit_iff_coprime] using a.isUnit
    have hprimPow : IsPrimitiveRoot ((root.1 : ℂ) ^ a.1) N := by
      simpa using root.isPrimitiveRoot.pow_of_coprime hcoprime
    have hsum_range : ∑ i in Finset.range N, ((root.1 : ℂ) ^ a.1) ^ i = 0 := by
      exact IsPrimitiveRoot.geom_sum_eq_zero hprimPow hNlt
    simpa [cyclicChar] using hsum_range

end T3
end TemTH
