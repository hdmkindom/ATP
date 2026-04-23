/-
`temTH` 模板：`T10` 自由模式。
-/
import Mathlib.Algebra.Group.Hom.Defs
import Mathlib.Data.Complex.Basic

namespace TemTH
namespace T10

variable {G : Type*} [Group G]

theorem candidate_T10_free (χ : G →* ℂˣ) (g : G) :
    χ g⁻¹ = (χ g)⁻¹ := by
  simpa using map_inv χ g

end T10
end TemTH
