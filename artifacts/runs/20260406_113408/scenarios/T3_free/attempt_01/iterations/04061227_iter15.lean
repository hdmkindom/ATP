/-
`temTH` 模板：`T3` 自由模式。
-/
import CandidateTheorems.T3.PrimitiveRoot
import Mathlib.NumberTheory.RootsOfUnity.Basic

open scoped BigOperators

namespace TemTH
namespace T3

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T3_free (root : PrimitiveNthRoot (N := N)) {a : Fin N} (ha : a ≠ 0) :
    ∑ x : Fin N, cyclicChar root a x = 0 := by
  classical
  have hNgt1 : 1 < N := by
    by_contra h
    have hN1 : N = 1 := by omega
    subst hN1
    apply ha
    ext
    simp
  have hprim : IsPrimitiveRoot (root.1 : ℂ) N := by
    simpa [PrimitiveNthRoot] using root.2
  have hcop : Nat.Coprime a.1 N := by
    rw [Nat.coprime_iff_gcd_eq_one]
    by_contra hbad
    have hg : Nat.gcd a.1 N ≠ 1 := hbad
    have hdvd : Nat.gcd a.1 N ∣ a.1 := Nat.gcd_dvd_left a.1 N
    have hposg : 0 < Nat.gcd a.1 N := Nat.gcd_pos_of_pos_right a.1 (Nat.pos_of_ne_zero (NeZero.ne N))
    have hne1 : Nat.gcd a.1 N ≠ 1 := hg
    have hge2 : 2 ≤ Nat.gcd a.1 N := by omega
    have hage2 : 2 ≤ a.1 := Nat.le_of_dvd (Nat.succ_le_of_lt hposg) hdvd
    have halt : a.1 < N := a.2
    omega
  have hprimPow : IsPrimitiveRoot ((root.1 : ℂ) ^ a.1) N :=
    hprim.pow_of_coprime a.1 hcop
  have hsum_range : ∑ i ∈ Finset.range N, (((root.1 : ℂ) ^ a.1) ^ i) = 0 :=
    IsPrimitiveRoot.geom_sum_eq_zero hprimPow hNgt1
  simpa [cyclicChar] using hsum_range

end T3
end TemTH
