/-
`temTH` 模板：`T9` 自由模式。
-/
import Mathlib.Algebra.Group.Hom.Defs
import Mathlib.Data.Complex.Basic

namespace TemTH
namespace T9

variable {G : Type*} [Group G]

theorem candidate_T9_free (χ : G →* ℂˣ) : χ 1 = 1 := by
  simpa using map_one χ

end T9
end TemTH
