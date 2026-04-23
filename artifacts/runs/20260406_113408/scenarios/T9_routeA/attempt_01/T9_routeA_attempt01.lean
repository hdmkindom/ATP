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
      χ 1 * χ 1 = χ (1 * 1) := by rw [χ.map_mul]
      _ = χ 1 := by simp
  have hleft : (χ 1)⁻¹ * (χ 1 * χ 1) = (χ 1)⁻¹ * χ 1 := by
    exact congrArg (fun z => (χ 1)⁻¹ * z) hmul
  calc
    χ 1 = 1 * χ 1 := by simp
    _ = ((χ 1)⁻¹ * χ 1) * χ 1 := by simp
    _ = (χ 1)⁻¹ * (χ 1 * χ 1) := by simp [mul_assoc]
    _ = (χ 1)⁻¹ * χ 1 := hleft
    _ = 1 := by simp

end T9
end TemTH
