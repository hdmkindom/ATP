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
  rcases root with ⟨ζ, hζN, hprimitive⟩
  have hNpos : 0 < N := Nat.pos_of_ne_zero (NeZero.ne N)
  have hNgt1 : 1 < N := by
    by_contra h
    have hNle1 : N ≤ 1 := Nat.le_of_not_gt h
    have hNge1 : 1 ≤ N := Nat.succ_le_of_lt hNpos
    have hN1 : N = 1 := le_antisymm hNle1 hNge1
    have hsub : Subsingleton (Fin N) := by
      subst hN1
      infer_instance
    exact ha (Subsingleton.elim _ _)
  have hprim : IsPrimitiveRoot ζ N := by
    rw [IsPrimitiveRoot.iff hNpos]
    exact ⟨hζN, hprimitive⟩
  have hcop : Nat.Coprime a.1 N := by
    rw [Nat.coprime_iff_gcd_eq_one]
    have hlt : a.1 < N := a.2
    exact Nat.gcd_eq_one_of_lt_prime ha hlt
  have hprimPow : IsPrimitiveRoot (ζ ^ a.1) N := hprim.pow_of_coprime a.1 hcop
  have hsum : Finset.sum (Finset.range N) (fun i => (ζ ^ a.1) ^ i) = 0 := by
    simpa using hprimPow.geom_sum_eq_zero hNgt1
  simpa [cyclicChar, Fin.sum_univ_eq_sum_range, pow_mul] using hsum

end T3
end TemTH
