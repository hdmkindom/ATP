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
  · have hzeta_prim := root.isPrimitiveRoot
    have hpow_ne_one : root.zeta ^ (x : ℕ) ≠ (1 : ℂ) := by
      intro h1
      have hdiv : N ∣ (x : ℕ) := (hzeta_prim.pow_eq_one_iff_dvd (x : ℕ)).mp h1
      have hx0 : (x : Fin N) = 0 := by
        apply Fin.ext
        exact Nat.modEq_zero_of_dvd hdiv
      exact hx hx0
    have hgeom : ∑ a : Fin N, cyclicChar root a x = ∑ k in Finset.range N, (root.zeta ^ (x : ℕ)) ^ k := by
      rw [Fin.sum_univ_eq_sum_range]
      refine Finset.sum_congr rfl ?_
      intro k hk
      simp [cyclicChar, pow_mul]
    rw [if_neg hx]
    rw [hgeom]
    have hgeom_formula := geom_sum_mul (root.zeta ^ (x : ℕ)) N
    rw [mul_eq_zero] at hgeom_formula
    have hpowN : (root.zeta ^ (x : ℕ)) ^ N = 1 := by
      rw [← pow_mul]
      rw [Nat.mul_comm]
      simpa using congrArg (fun z : ℂ => z ^ (x : ℕ)) root.pow_eq_one
    have hsum_zero : ∑ k in Finset.range N, (root.zeta ^ (x : ℕ)) ^ k = 0 := by
      apply (mul_right_injective₀ hpow_ne_one).mp
      rw [hgeom_formula, hpowN, sub_self, zero_mul]
    exact hsum_zero

end T4
end TemTH
