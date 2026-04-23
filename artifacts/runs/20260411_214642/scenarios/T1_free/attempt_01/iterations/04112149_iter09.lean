/-
`temTH` 模板：`T1` 自由模式。
-/
import CandidateTheorems.T1.Support
import Mathlib.Data.Fintype.BigOperators

open scoped BigOperators

namespace TemTH
namespace T1

open CandidateTheorems.T1

variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_free (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  classical
  by_contra hsum
  have hsum' : ∑ g : G, (χ g : ℂ) ≠ 0 := hsum
  have hker : ∀ a : G, χ a = 1 := by
    intro a
    have hmul : (χ a : ℂ) * (∑ g : G, (χ g : ℂ)) = ∑ g : G, (χ g : ℂ) := by
      calc
        (χ a : ℂ) * (∑ g : G, (χ g : ℂ))
            = ∑ g : G, ((χ a : ℂ) * (χ g : ℂ)) := by
                simpa using Finset.mul_sum (s := (Fintype.elems G)) (a := (χ a : ℂ))
                  (f := fun g : G => (χ g : ℂ))
        _ = ∑ g : G, (χ (a * g) : ℂ) := by
              refine Finset.sum_congr rfl ?_
              intro g hg
              norm_cast
              simpa using map_mul χ a g
        _ = ∑ g : G, (χ g : ℂ) := by
              simpa using Fintype.sum_bijective
                (fun g : G => a * g)
                (show Function.Bijective (fun g : G => a * g) from
                  ⟨fun x y h => mul_left_cancel h, fun y => ⟨a⁻¹ * y, by simp⟩⟩)
                (fun g : G => (χ g : ℂ))
    have haC : (χ a : ℂ) = 1 := by
      have hEq : (χ a : ℂ) * (∑ g : G, (χ g : ℂ)) = 1 * (∑ g : G, (χ g : ℂ)) := by
        simpa [one_mul] using hmul
      exact mul_right_cancel₀ hsum' hEq
    exact Character.ext_iff.mp (by
      intro x
      have : (χ x : ℂ) = (1 : Character G) x := by
        simpa using (show (χ x : ℂ) = 1 from by simpa using haC)
      exact this) a
  have hχ1 : χ = 1 := by
    ext a
    exact congrArg (fun z : Character G => ((z a : Character.ValuedIn) : ℂ)) (by
      have := hker a
      exact by
        cases this
        rfl)
  exact hχ hχ1

end T1
end TemTH
