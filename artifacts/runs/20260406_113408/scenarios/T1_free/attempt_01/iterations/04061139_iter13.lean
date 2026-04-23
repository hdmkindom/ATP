/-
`temTH` 模板：`T1` 自由模式。
-/
import CandidateTheorems.T1.Support
import Mathlib.Data.Fintype.BigOperators
import Mathlib.NumberTheory.LegendreSymbol.GaussSum

open scoped BigOperators

namespace TemTH
namespace T1

open CandidateTheorems.T1

variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_free (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  let χ' : MulChar G ℂ :=
    MulChar.ofUnitHom
      { toFun := fun u => χ u
        map_one' := by simpa using map_one χ
        map_mul' := by
          intro u v
          simpa using map_mul χ u v }
  have hχ' : χ' ≠ 1 := by
    intro h1
    apply hχ
    ext g
    have hcoeeq : (χ' g : ℂ) = ((1 : MulChar G ℂ) g : ℂ) := by
      simpa [h1]
    simpa [χ', MulChar.ofUnitHom_coe] using hcoeeq
  simpa [χ', MulChar.ofUnitHom_coe] using (MulChar.sum_eq_zero_of_ne_one (χ := χ') hχ')

end T1
end TemTH
