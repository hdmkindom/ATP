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

theorem candidate_T5_free (root : PrimitiveNthRoot (N := N)) (t : Fin N) :
    delta0 (N := N) t = (1 / (N : ℂ)) * ∑ a : Fin N, cyclicChar root a t := by
  sorry
