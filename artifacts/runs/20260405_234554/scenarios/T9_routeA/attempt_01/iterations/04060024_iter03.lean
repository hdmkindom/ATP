/-
`temTH` 模板：`T9` 路线 A。
-/
import Mathlib.Algebra.Group.Hom.Defs
import Mathlib.Data.Complex.Basic

namespace TemTH
namespace T9

variable {G : Type*} [Group G]

theorem candidate_T9_routeA (χ : G →* ℂˣ) : χ 1 = 1 := by
  -- 由同态性质：保持单位元
  simpa using χ.map_one

end T9
end TemTH
