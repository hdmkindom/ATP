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
  -- View the summand as powers of a nontrivial primitive root and use the geometric-sum vanishing lemma.
  have hNpos : 0 < N := Nat.pos_of_ne_zero (NeZero.ne N)
  have hNgt1 : 1 < N := by
    by_contra h
    have hle : N ≤ 1 := Nat.le_of_not_gt h
    have hEq : N = 1 := by omega
    subst hEq
    have : a = 0 := by
      ext
      simp
    exact ha this
  simpa [cyclicChar] using IsPrimitiveRoot.geom_sum_eq_zero (R := ℂ) (ζ := root.1 ^ (a : ℕ)) (k := N) (root.isPrimitiveRoot.pow a.2) hNgt1

end T3
end TemTH
