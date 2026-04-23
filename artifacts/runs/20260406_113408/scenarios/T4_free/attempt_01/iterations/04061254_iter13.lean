/-
`temTH` 模板：`T4` 自由模式。
-/
import CandidateTheorems.T3.PrimitiveRoot

open scoped BigOperators

namespace TemTH
namespace T4

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T4_free (root : PrimitiveNthRoot (N := N)) (x : Fin N) :
    ∑ a : Fin N, cyclicChar root a x = if x = 0 then (N : ℂ) else 0 := by
  classical
  by_cases hx : x = 0
  · subst hx
    simp [cyclicChar]
  · have hprim : IsPrimitiveRoot root.zeta N := root.property
    have hxval_ne_zero : x.val ≠ 0 := by
      intro hx0
      apply hx
      exact Fin.ext hx0
    have hcop : Nat.Coprime x.val N := by
      exact Fin.coprime x
    have hpow_prim : IsPrimitiveRoot (root.zeta ^ x.val) N := hprim.pow_of_coprime x.val hcop
    have hNgt1 : 1 < N := by
      by_contra hle
      have hle' : N ≤ 1 := Nat.not_lt.mp hle
      have hN1 : N = 1 := Nat.succ_le_iff.mp (Nat.succ_le_of_lt (Nat.pos_of_ne_zero (NeZero.ne N))) |> fun h => le_antisymm hle' h
      have : x = 0 := by
        apply Fin.ext
        have : x.val < 1 := by simpa [hN1] using x.is_lt
        exact Nat.eq_zero_of_lt_one this
      exact hx this
    have hsum_range : ∑ k in Finset.range N, (root.zeta ^ x.val) ^ k = 0 := by
      simpa using IsPrimitiveRoot.geom_sum_eq_zero hpow_prim hNgt1
    have hrewrite : (∑ a : Fin N, cyclicChar root a x) = ∑ k in Finset.range N, (root.zeta ^ x.val) ^ k := by
      rw [Fin.sum_univ_eq_sum_range]
      refine Finset.sum_congr rfl ?_
      intro k hk
      simp [cyclicChar, pow_mul]
    rw [hrewrite, if_neg hx, hsum_range]

end T4
end TemTH
