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
  rcases root with ⟨ζ, hζN, hprimitive⟩
  have hNpos : 0 < N := Nat.pos_of_ne_zero (NeZero.ne N)
  have hNgt1 : 1 < N := by
    by_contra hle
    have hNle1 : N ≤ 1 := Nat.le_of_not_gt hle
    have hNeq1 : N = 1 := le_antisymm hNle1 hNpos
    have : (a : Fin N) = 0 := by
      apply Fin.ext
      simp [hNeq1]
    exact ha this
  have hcop : Nat.Coprime a.1 N := by
    simpa [Fin.ne_iff_vne] using a.isCoprime_val
  have hprimζ : IsPrimitiveRoot ζ N := by
    rw [IsPrimitiveRoot.iff_def]
    refine ⟨hζN, ?_⟩
    intro l hl
    by_cases hzero : l = 0
    · simp [hzero]
    · by_cases hlt : l < N
      · by_contra hndvd
        have hone : ζ ^ l = 1 := hl
        exact (hprimitive l (Nat.pos_of_ne_zero hzero) hlt) hone
      · have hNL : N ≤ l := Nat.le_of_not_gt hlt
        exact Nat.dvd_of_modEq_zero <| by
          have := hl
          simpa [Nat.modEq_iff_dvd']
  have hpowprim : IsPrimitiveRoot (ζ ^ a.1) N := hprimζ.pow_of_coprime a.1 hcop
  have hsum : ∑ i ∈ Finset.range N, (ζ ^ a.1) ^ i = 0 := hpowprim.geom_sum_eq_zero hNgt1
  simpa [cyclicChar, Fin.sum_univ_eq_sum_range, pow_mul] using hsum

end T3
end TemTH
