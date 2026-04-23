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
  · have hxCoprime : Nat.Coprime x.1 N := x.isCoprime
    have hprim : IsPrimitiveRoot (root.zeta ^ x.1) N := by
      simpa using root.zeta_spec.pow_of_coprime x.1 hxCoprime
    have hsum : ∑ k in Finset.range N, (root.zeta ^ x.1) ^ k = 0 := by
      apply hprim.geom_sum_eq_zero
      have hN1 : 1 < N := by
        by_contra hlt
        have hle : N ≤ 1 := Nat.le_of_not_gt hlt
        have hx0 : x = 0 := by
          apply Fin.ext
          have hxval0 : x.1 = 0 := by
            have hxlt1 : x.1 < 1 := lt_of_lt_of_le x.2 hle
            exact Nat.eq_zero_of_lt_one hxlt1
          simpa using hxval0
        exact hx hx0
      exact hN1
    rw [if_neg hx]
    rw [Fin.sum_univ_eq_sum_range]
    have hchar : ∀ k : ℕ, cyclicChar root ⟨k, by simpa using k.2⟩ x = (root.zeta ^ x.1) ^ k := by
      intro k
      simp [cyclicChar, pow_mul]
    simp_rw [hchar]
    exact hsum

end T4
end TemTH
