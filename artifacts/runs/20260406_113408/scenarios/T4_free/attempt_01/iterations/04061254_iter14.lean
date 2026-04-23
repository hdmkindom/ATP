/-
`temTH` 模板：`T4` 自由模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import Mathlib.NumberTheory.RootsOfUnity.Basic

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
  · have hprim : IsPrimitiveRoot root.zeta N := root.isPrimitiveRoot
    have hx0 : x.1 ≠ 0 := by
      intro hxv
      apply hx
      ext
      exact hxv
    have hcop : Nat.Coprime x.1 N := by
      rw [Nat.coprime_comm]
      exact Nat.coprime_of_lt_and_dvd x.is_lt (by simp [hx0])
    have hpow : IsPrimitiveRoot (root.zeta ^ x.1) N := hprim.pow_of_coprime x.1 hcop
    have hNgt1 : 1 < N := by
      have hpos : 0 < N := Nat.pos_of_ne_zero (NeZero.ne N)
      by_contra h
      have hNle1 : N ≤ 1 := le_of_not_gt h
      have hN1 : N = 1 := le_antisymm hNle1 (Nat.succ_le_of_lt hpos)
      have : x = 0 := by
        ext
        have : x.1 < 1 := by simpa [hN1] using x.2
        exact Nat.eq_zero_of_lt_succ_of_not_lt this (by simp)
      exact hx this
    have hsumRange : Finset.sum (Finset.range N) (fun k => (root.zeta ^ x.1) ^ k) = 0 := by
      simpa using IsPrimitiveRoot.geom_sum_eq_zero hpow hNgt1
    have hrewrite :
        (∑ a : Fin N, cyclicChar root a x) = Finset.sum (Finset.range N) (fun k => (root.zeta ^ x.1) ^ k) := by
      rw [Fin.sum_univ_eq_sum_range]
      refine Finset.sum_congr rfl ?_
      intro k hk
      simp [cyclicChar, pow_mul]
    rw [hrewrite, if_neg hx, hsumRange]

end T4
end TemTH
