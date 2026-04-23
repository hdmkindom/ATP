/-
`temTH` 模板：`T9` 路线 A。
-/
import Mathlib.Algebra.Group.Hom.Defs
import Mathlib.Data.Complex.Basic

namespace TemTH
namespace T9

variable {G : Type*} [Group G]

theorem candidate_T9_routeA (χ : G →* ℂˣ) : χ 1 = 1 := by
  have hmul : χ 1 * χ 1 = χ 1 := by
    calc
      χ 1 * χ 1 = χ (1 * 1) := by rw [map_mul]
      _ = χ 1 := by simp
  have hcancel : χ 1 = 1 := by
    exact mul_left_cancel₀ (χ 1) hmul
  exact hcancel

end T9
end TemTH
