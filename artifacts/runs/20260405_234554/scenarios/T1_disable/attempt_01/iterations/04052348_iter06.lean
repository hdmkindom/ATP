/-
`temTH` 模板：`T1` 禁用模式。
-/
import CandidateTheorems.T1.Support
import Mathlib.Data.Fintype.BigOperators

open scoped BigOperators

namespace TemTH
namespace T1

open CandidateTheorems.T1

variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_disable (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  classical
  by_contra hsum
  have hinner : ⟪χ, (1 : Character G)⟫ = 0 := by
    simpa [Character.inner_apply] using Character.inner_eq_zero_of_ne (χ := χ) (ψ := (1 : Character G)) hχ
  have hsum_eq : ∑ g : G, (χ g : ℂ) = Fintype.card G * ⟪χ, (1 : Character G)⟫ := by
    simpa [Character.inner_apply] using (Character.sum_eq_card_mul_inner_right (χ := χ) (ψ := (1 : Character G)))
  have hcard_ne_zero : (Fintype.card G : ℂ) ≠ 0 := by
    exact_mod_cast (Nat.cast_ne_zero.mpr (Fintype.card_ne_zero))
  have hcontr : ∑ g : G, (χ g : ℂ) = 0 := by
    rw [hsum_eq, hinner]
    simp
  exact hsum hcontr

end T1
end TemTH
