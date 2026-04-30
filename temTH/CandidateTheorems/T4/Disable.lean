import Mathlib.Data.Complex.Basic
import Mathlib.Data.Fintype.BigOperators

open scoped BigOperators

variable {N : ℕ} [NeZero N]

/-- `Fin N` 上位于 `0` 的 Dirac delta。 -/
def delta0 (t : Fin N) : ℂ :=
  if t = 0 then 1 else 0

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

theorem candidate_T4_disable (root : PrimitiveNthRoot (N := N)) (x : Fin N) :
    ∑ a : Fin N, cyclicChar root a x = if x = 0 then (N : ℂ) else 0 := by
  sorry
