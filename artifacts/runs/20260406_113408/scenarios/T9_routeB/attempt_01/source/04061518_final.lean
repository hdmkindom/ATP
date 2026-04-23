/-
`temTH` 模板：`T9` 路线 B。
-/
import Mathlib.Algebra.Group.Hom.Defs

namespace TemTH
namespace T9

variable {G H : Type*} [Group G] [Group H]

theorem candidate_T9_routeB (φ : G →* H) : φ 1 = 1 := by
  exact map_one φ

end T9
end TemTH
