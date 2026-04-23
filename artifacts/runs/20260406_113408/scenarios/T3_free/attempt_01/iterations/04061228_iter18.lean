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
    have hN1 : N = 1 := by
      omega
    subst hN1
    have : a = 0 := by
      ext
      simp
    exact ha this
  have hcop : Nat.Coprime (a : ℕ) N := by
    simpa using a.isCoprime
  have hprim : IsPrimitiveRoot (root.zeta ^ (a : ℕ)) N :=
    root.isPrimitiveRoot.pow_of_coprime (a : ℕ) hcop
  have hsum_range : ∑ i in Finset.range N, (root.zeta ^ (a : ℕ)) ^ i = 0 :=
    hprim.geom_sum_eq_zero hNgt1
  have hrewrite :
      ∑ x : Fin N, cyclicChar root a x = ∑ i in Finset.range N, (root.zeta ^ (a : ℕ)) ^ i := by
    simp [cyclicChar, Fin.sum_univ_eq_sum_range]
  rw [hrewrite, hsum_range]

end T3
end TemTH
