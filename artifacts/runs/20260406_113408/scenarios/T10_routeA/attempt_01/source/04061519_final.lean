/-
`temTH` 模板：`T10` 路线 A。
-/
import Mathlib.Algebra.Group.Hom.Defs
import Mathlib.Data.Complex.Basic

namespace TemTH
namespace T10

variable {G : Type*} [Group G]

theorem candidate_T10_routeA (χ : G →* ℂˣ) (g : G) :
    χ g⁻¹ = (χ g)⁻¹ := by
  have hmul : χ g * χ g⁻¹ = 1 := by
    calc
      χ g * χ g⁻¹ = χ (g * g⁻¹) := by rw [map_mul]
      _ = χ 1 := by simp
      _ = 1 := by rw [map_one]
  have hmul' : (χ g)⁻¹ * (χ g * χ g⁻¹) = (χ g)⁻¹ * 1 := by
    exact congrArg (fun z => (χ g)⁻¹ * z) hmul
  simpa [mul_assoc] using hmul'

end T10
end TemTH
