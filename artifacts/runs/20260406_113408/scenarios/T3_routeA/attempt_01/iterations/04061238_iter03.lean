/-
`temTH` 模板：`T3` 路线 A。
-/
import CandidateTheorems.T3.PrimitiveRoot

open scoped BigOperators

namespace TemTH
namespace T3

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T3_routeA (root : PrimitiveNthRoot (N := N)) {a : Fin N} (ha : a ≠ 0) :
    ∑ x : Fin N, cyclicChar root a x = 0 := by
  classical
  obtain ⟨ζ, hζ_prim, rfl⟩ := root
  have hN_gt_one : 1 < N := by
    by_contra h
    have hN_le_one : N ≤ 1 := le_of_not_gt h
    have hN_ne_one : N ≠ 1 := by
      intro hN1
      apply ha
      ext
      simp [hN1]
    omega
  have ha_coprime : Nat.Coprime a.1 N := by
    simpa [Fin.isCoprime_iff_gcd_eq_one] using a.isCoprime
  have hpow_prim : IsPrimitiveRoot (ζ ^ a.1) N :=
    hζ_prim.pow_of_coprime a.1 ha_coprime
  simpa [cyclicChar] using hpow_prim.geom_sum_eq_zero hN_gt_one

end T3
end TemTH
