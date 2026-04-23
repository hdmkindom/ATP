/-
`temTH` 模板：`T3` 自由模式。
-/
import CandidateTheorems.T3.PrimitiveRoot

open scoped BigOperators

namespace TemTH
namespace T3

open CandidateTheorems.T3

variable {N : ℕ} [NeZero N]

theorem candidate_T3_free (root : PrimitiveNthRoot (N := N)) {a : Fin N} (ha : a ≠ 0) :
    ∑ x : Fin N, cyclicChar root a x = 0 := by
  classical
  let ζ : ℂ := root.zeta ^ (a : ℕ)
  have hNgt1 : 1 < N := by
    by_contra h
    have hN1 : N = 1 := by
      omega
    subst hN1
    have : a = 0 := by
      ext
      simp
    exact ha this
  have hcop : Nat.Coprime (a : ℕ) N := by
    rw [Nat.coprime_iff_gcd_eq_one]
    have ha_lt : (a : ℕ) < N := a.2
    omega
  have hprim_root : IsPrimitiveRoot root.zeta N := root.isPrimitiveRoot
  have hprim : IsPrimitiveRoot ζ N := by
    simpa [ζ] using hprim_root.pow_of_coprime (a : ℕ) hcop
  have hsum_range : (∑ i ∈ Finset.range N, ζ ^ i) = 0 := by
    simpa using hprim.geom_sum_eq_zero hNgt1
  have hrewrite :
      ∑ x : Fin N, cyclicChar root a x = ∑ i ∈ Finset.range N, ζ ^ i := by
    simp [cyclicChar, Fin.sum_univ_eq_sum_range, ζ, pow_mul]
  rw [hrewrite, hsum_range]

end T3
end TemTH
