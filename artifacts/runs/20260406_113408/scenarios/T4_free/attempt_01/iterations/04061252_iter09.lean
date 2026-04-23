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
  ·
    let ζ : ℂ := root.val ^ x.val
    have hζ_prim : IsPrimitiveRoot ζ N := by
      simpa [ζ] using root.isPrimitive.pow_of_coprime x.val x.isCoprime
    have hN_gt_one : 1 < N := by
      by_contra hle
      have hle' : N ≤ 1 := Nat.not_lt.mp hle
      have hN_ne_1 : N ≠ 1 := by
        intro h1
        have : x = 0 := by
          apply Fin.ext
          exact Nat.eq_of_lt_succ_of_not_lt x.is_lt (by simpa [h1] using hx)
        exact hx this
      omega
    have hsum : ∑ i ∈ Finset.range N, ζ ^ i = 0 :=
      IsPrimitiveRoot.geom_sum_eq_zero hζ_prim hN_gt_one
    have hchar : (∑ a : Fin N, cyclicChar root a x) = ∑ i ∈ Finset.range N, ζ ^ i := by
      simp [cyclicChar, ζ, Fin.sum_univ_eq_sum_range]
    rw [hchar, hsum]
    simp [hx]

end T4
end TemTH
