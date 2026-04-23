/-
`temTH` 模板：`T4` 路线 A。
-/
import CandidateTheorems.T3.PrimitiveRoot

open scoped BigOperators

namespace TemTH
namespace T4

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T4_routeA (root : PrimitiveNthRoot (N := N)) (x : Fin N) :
    ∑ a : Fin N, cyclicChar root a x = if x = 0 then (N : ℂ) else 0 := by
  by_cases hx : x = 0
  · subst hx
    simp [cyclicChar]
  · have hprim : IsPrimitiveRoot root.zeta N := root.isPrimitive
    have hpow_prim : IsPrimitiveRoot (root.zeta ^ (x : ℕ)) N := by
      apply hprim.pow_of_coprime
      simpa [Fin.coprime_iff_gcd_eq_one, Nat.gcd_comm] using x.isCoprime
    have hN1 : 1 < N := by
      have hx0 : (x : ℕ) ≠ 0 := by
        simpa using hx
      have hxpos : 0 < (x : ℕ) := Nat.pos_of_ne_zero hx0
      exact lt_of_lt_of_le hxpos x.isLt
    have hsum_range : ∑ i ∈ Finset.range N, (root.zeta ^ (x : ℕ)) ^ i = 0 :=
      hpow_prim.geom_sum_eq_zero hN1
    have hrewrite :
        (∑ a : Fin N, cyclicChar root a x) = ∑ i ∈ Finset.range N, (root.zeta ^ (x : ℕ)) ^ i := by
      rw [Fin.sum_univ_eq_sum_range]
      refine Finset.sum_congr rfl ?_
      intro i hi
      simp [cyclicChar, pow_mul]
    rw [if_neg hx]
    rw [hrewrite]
    exact hsum_range

end T4
end TemTH
