/-
`temTH` 模板：`T1` 自由模式。
-/
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Tactic.Ring
import Mathlib.Data.Fintype.BigOperators

open scoped BigOperators

namespace TemTH
namespace T1

abbrev Character (G : Type*) [Group G] := G →* ℂˣ

variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_free (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  sorry

end T1
end TemTH
