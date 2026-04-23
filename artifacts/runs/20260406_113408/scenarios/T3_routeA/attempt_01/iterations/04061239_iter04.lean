/-
`temTH` 模板：`T3` 路线 A。
-/
import CandidateTheorems.T3.PrimitiveRoot
import Mathlib.NumberTheory.RootsOfUnity.Basic

open scoped BigOperators

namespace TemTH
namespace T3

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T3_routeA (root : PrimitiveNthRoot (N := N)) {a : Fin N} (ha : a ≠ 0) :
    ∑ x : Fin N, cyclicChar root a x = 0 := by
  classical
  rcases root with ⟨ζ, hζN, hζ_ne_one⟩
  have hN_gt_one : 1 < N := by
    by_contra h
    have hN_le_one : N ≤ 1 := le_of_not_gt h
    have hN_ne_one : N ≠ 1 := by
      intro hN1
      apply ha
      ext
      simp [hN1]
    omega
  have hN_pos : 0 < N := lt_trans Nat.zero_lt_one hN_gt_one
  have hζ_prim : IsPrimitiveRoot ζ N := by
    rw [IsPrimitiveRoot.iff_def]
    constructor
    · exact hζN
    · intro m hm hmN
      exact hζ_ne_one m hm hmN
  have ha_coprime : Nat.Coprime a.1 N := by
    simpa [Fin.isCoprime_iff_gcd_eq_one] using a.isCoprime
  have hpow_prim : IsPrimitiveRoot (ζ ^ a.1) N :=
    hζ_prim.pow_of_coprime a.1 ha_coprime
  calc
    ∑ x : Fin N, cyclicChar ⟨ζ, hζN, hζ_ne_one⟩ a x
        = ∑ i in Finset.range N, (ζ ^ a.1) ^ i := by
            simp [cyclicChar, Fin.sum_univ_eq_sum_range, pow_mul]
    _ = 0 := by
      simpa [pow_mul] using hpow_prim.geom_sum_eq_zero hN_gt_one

end T3
end TemTH
