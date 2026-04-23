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
  · have hNprime : Nat.Prime N := root.prime_N
    have hNgt1 : 1 < N := hNprime.one_lt
    have hx_nat_ne_zero : (x : ℕ) ≠ 0 := by
      intro hx0
      apply hx
      exact Fin.ext hx0
    have hx_coprime : Nat.Coprime (x : ℕ) N := by
      exact hNprime.coprime_iff_not_dvd.mpr <| by
        intro hdiv
        have hx0 : (x : ℕ) = 0 := Nat.eq_zero_of_dvd_of_lt hdiv x.isLt
        exact hx_nat_ne_zero hx0
    have hprim : IsPrimitiveRoot (root.zeta ^ (x : ℕ)) N :=
      root.isPrimitiveRoot.pow_of_coprime (x : ℕ) hx_coprime
    have hsum_range : ∑ i in Finset.range N, (root.zeta ^ (x : ℕ)) ^ i = 0 := by
      exact hprim.geom_sum_eq_zero hNgt1
    have hsum_fin : ∑ a : Fin N, (root.zeta ^ (x : ℕ)) ^ (a : ℕ) = 0 := by
      rw [Fin.sum_univ_eq_sum_range]
      exact hsum_range
    have hrewrite :
        (∑ a : Fin N, cyclicChar root a x) = ∑ a : Fin N, (root.zeta ^ (x : ℕ)) ^ (a : ℕ) := by
      apply Finset.sum_congr rfl
      intro a ha
      simp [cyclicChar, pow_mul, Nat.mul_comm]
    rw [if_neg hx]
    rw [hrewrite]
    exact hsum_fin

end T4
end TemTH
