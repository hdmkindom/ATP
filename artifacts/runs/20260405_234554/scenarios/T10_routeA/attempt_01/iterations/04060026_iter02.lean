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
      _ = χ 1 := by rw [mul_inv_self]
      _ = 1 := by rw [map_one]
  exact inv_eq_of_mul_inv_left hmul

end T10
end TemTH
