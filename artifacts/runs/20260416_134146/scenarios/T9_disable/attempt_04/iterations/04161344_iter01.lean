/-
`temTH` 模板：`T9` 禁用模式。
-/
import Mathlib.Algebra.Group.Hom.Defs
import Mathlib.Data.Complex.Basic

namespace TemTH
namespace T9

variable {G : Type*} [Group G]

theorem candidate_T9_disable (χ : G →* ℂˣ) : χ 1 = 1 := by
  simpa using χ.map_one

end T9
end TemTH
