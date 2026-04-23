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
  · have hNpos : 0 < N := Nat.pos_of_ne_zero (NeZero.ne N)
    have hx_coprime : Nat.Coprime (x : ℕ) N := by
      rw [Nat.coprime_comm]
      apply Nat.prime.coprime_iff_not_dvd.mpr
      · exact root.prime_N
      · intro hdiv
        have hx0 : (x : ℕ) = 0 := by
          exact Nat.eq_zero_of_dvd_of_lt hdiv x.isLt
        exact hx (Fin.ext hx0)
    have hprim : IsPrimitiveRoot (root.zeta ^ (x : ℕ)) N :=
      root.isPrimitive.pow_of_coprime (x : ℕ) hx_coprime
    have hsum : ∑ a : Fin N, (root.zeta ^ (x : ℕ)) ^ (a : ℕ) = 0 := by
      rw [Fin.sum_univ_eq_sum_range]
      simpa using hprim.geom_sum_eq_zero (by omega)
    have hrewrite :
        (∑ a : Fin N, cyclicChar root a x) = ∑ a : Fin N, (root.zeta ^ (x : ℕ)) ^ (a : ℕ) := by
      simp_rw [cyclicChar, pow_mul]
    rw [if_neg hx]
    rw [hrewrite]
    exact hsum

end T4
end TemTH
