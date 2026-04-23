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
  · have hprim : IsPrimitiveRoot root.zeta N := root.isPrimitive
    have hx0 : 0 < N := Nat.pos_of_ne_zero (NeZero.ne N)
    have hxcoprime : Nat.Coprime x.val N := by
      simpa [Fin.coprime_iff_mem_units] using x.isUnit_iff_ne_zero.mpr hx
    have hpow_prim : IsPrimitiveRoot (root.zeta ^ x.val) N :=
      hprim.pow_of_coprime x.val hxcoprime
    have hsum_range : ∑ k in Finset.range N, (root.zeta ^ x.val) ^ k = 0 := by
      by_cases hN : N = 1
      · subst hN
        exfalso
        apply hx
        ext
        simp
      · have h1N : 1 < N := Nat.lt_of_le_of_ne (Nat.succ_le_of_lt hx0) hN.symm
        simpa using hpow_prim.geom_sum_eq_zero h1N
    have hrewrite :
        (∑ a : Fin N, cyclicChar root a x) = ∑ k in Finset.range N, (root.zeta ^ x.val) ^ k := by
      rw [Fin.sum_univ_eq_sum_range]
      refine Finset.sum_congr rfl ?_
      intro k hk
      simp [cyclicChar, pow_mul]
    rw [hrewrite, if_neg hx, hsum_range]

end T4
end TemTH
