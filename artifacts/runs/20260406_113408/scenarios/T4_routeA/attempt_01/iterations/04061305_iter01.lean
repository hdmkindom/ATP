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
  · simp [hx, cyclicChar, Fin.sum_univ_eq_sum_range]
  · have hx' : x ≠ 0 := hx
    have hprim : IsPrimitiveRoot (root.ζ ^ x.val) N := by
      exact root.isPrimitive.pow_of_coprime x.val x.isCoprime
    have hsum_range : ∑ k ∈ Finset.range N, (root.ζ ^ x.val) ^ k = 0 := by
      exact hprim.geom_sum_eq_zero (by
        have hN : 1 < N := by
          by_contra h
          have hle : N ≤ 1 := Nat.not_lt.mp h
          have hzero : x = 0 := by
            apply Fin.ext
            have hxv : x.val = 0 := by
              have : x.val < 1 := lt_of_lt_of_le x.is_lt hle
              exact Nat.eq_zero_of_lt_one this
            simpa using hxv
          exact hx' hzero
        exact hN)
    have hchar : (fun a : Fin N => cyclicChar root a x) = fun a : Fin N => (root.ζ ^ x.val) ^ a.val := by
      funext a
      simp [cyclicChar, mul_comm, mul_left_comm, mul_assoc, pow_mul]
    rw [if_neg hx']
    rw [hchar]
    rw [Fin.sum_univ_eq_sum_range]
    simpa using hsum_range

end T4
end TemTH
