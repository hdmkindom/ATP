import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Complex.Basic
import Mathlib.Tactic.Ring

open scoped BigOperators

variable {N : ℕ} [NeZero N]

/--
原始 `N` 次单位根的代数封装。
-/
structure PrimitiveNthRoot where
  zeta : ℂ
  pow_eq_one : zeta ^ N = 1
  pow_ne_one : ∀ m : ℕ, 0 < m → m < N → zeta ^ m ≠ 1

/--
在代表元类型 `Fin N` 上写出的循环字符核：
`(a, x) ↦ ζ^(a x)`。
-/
def cyclicChar (root : PrimitiveNthRoot (N := N)) (a x : Fin N) : ℂ :=
  root.zeta ^ (a.1 * x.1)

theorem candidate_T3_routeB (root : PrimitiveNthRoot (N := N)) {a : Fin N} (ha : a ≠ 0) :
    ∑ x : Fin N, cyclicChar root a x = 0 := by
  sorry
