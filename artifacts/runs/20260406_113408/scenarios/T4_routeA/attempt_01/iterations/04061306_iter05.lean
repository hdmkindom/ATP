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
  · rw [if_neg hx]
    let ζ : ℂ := root.zeta ^ (x : ℕ)
    have hx_coprime : Nat.Coprime (x : ℕ) N := by
      simpa using x.2
    have hprim_root : IsPrimitiveRoot root.zeta N := by
      simpa [PrimitiveNthRoot] using root.property
    have hprim : IsPrimitiveRoot ζ N := by
      dsimp [ζ]
      exact hprim_root.pow_of_coprime (x : ℕ) hx_coprime
    have hNgt1 : 1 < N := by
      by_contra h
      have hle : N ≤ 1 := Nat.le_of_not_gt h
      have hxval0 : (x : ℕ) = 0 := by
        have hxlt1 : (x : ℕ) < 1 := lt_of_lt_of_le x.is_lt hle
        exact Nat.eq_zero_of_lt_one hxlt1
      apply hx
      exact Fin.ext hxval0
    have hsum : ∑ a : Fin N, cyclicChar root a x = ∑ k in Finset.range N, ζ ^ k := by
      rw [Fin.sum_univ_eq_sum_range]
      refine Finset.sum_congr rfl ?_
      intro k hk
      simp [cyclicChar, ζ, pow_mul]
    rw [hsum]
    exact IsPrimitiveRoot.geom_sum_eq_zero hprim hNgt1

end T4
end TemTH
