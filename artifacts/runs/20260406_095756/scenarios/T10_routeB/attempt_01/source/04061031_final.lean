/-
`temTH` 模板：`T10` 路线 B。
-/
import Mathlib.Algebra.Group.Hom.Defs

namespace TemTH
namespace T10

variable {G H : Type*} [Group G] [Group H]

theorem candidate_T10_routeB (φ : G →* H) (g : G) :
    φ g⁻¹ = (φ g)⁻¹ := by
  exact map_inv φ g

end T10
end TemTH
