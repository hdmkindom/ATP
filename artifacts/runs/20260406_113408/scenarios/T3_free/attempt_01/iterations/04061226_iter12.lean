/-
`temTH` 模板：`T3` 自由模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import Mathlib.Data.ZMod.Basic
import Mathlib.NumberTheory.RootsOfUnity

open scoped BigOperators

namespace TemTH
namespace T3

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T3_free (root : PrimitiveNthRoot (N := N)) {a : Fin N} (ha : a ≠ 0) :
    ∑ x : Fin N, cyclicChar root a x = 0 := by
  classical
  have hN1 : 1 < N := by
    by_contra h
    have hle : N ≤ 1 := by omega
    have hEq : N = 1 := by omega
    subst hEq
    apply ha
    ext
    simp
  have hcop : Nat.Coprime a.1 N := by
    simpa [Fin.isUnit_iff_coprime] using a.isUnit
  have hprim : IsPrimitiveRoot ((root.1 : ℂ) ^ a.1) N := by
    exact root.isPrimitiveRoot.pow_of_coprime a.1 hcop
  calc
    ∑ x : Fin N, cyclicChar root a x
        = ∑ i ∈ Finset.range N, (((root.1 : ℂ) ^ a.1) ^ i) := by
            simp [cyclicChar, Fin.sum_univ_eq_sum_range]
    _ = 0 := by
          simpa [pow_mul] using hprim.geom_sum_eq_zero hN1

end T3
end TemTH
