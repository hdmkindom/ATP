
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Fintype.BigOperators

open scoped BigOperators

variable {N : ℕ} [NeZero N]

/-- `Fin N` 上位于 `0` 的 Dirac delta。 -/
def delta0 (t : Fin N) : ℂ :=
  if t = 0 then 1 else 0

/--
Fourier 反演。
-/
structure FourierInversionData where
  ψ : Fin N → Fin N → ℂ
  delta0_formula :
    ∀ t : Fin N, delta0 (N := N) t = (1 / (N : ℂ)) * ∑ a : Fin N, ψ a t

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


/-- `Fin N` 上的模 `N` 减法。 -/
def cyclicSub (x t : Fin N) : Fin N :=
  ⟨(x.1 + N - t.1) % N, by
    exact Nat.mod_lt _ (Nat.pos_of_ne_zero (NeZero.ne N))⟩

/-- 把 `δ_t` 定义为 `δ_0` 的平移。 -/
def deltaAt (t x : Fin N) : ℂ :=
  delta0 (N := N) (cyclicSub x t)

theorem candidate_T7_free (root : PrimitiveNthRoot (N := N)) (t x : Fin N) :
    deltaAt (N := N) t x =
      (1 / (N : ℂ)) * ∑ a : Fin N, cyclicChar root a (cyclicSub x t) := by
  sorry
