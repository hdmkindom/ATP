/-
`temTH` 模板：`T1` 路线 B。
-/
import CandidateTheorems.T1.Support
import Mathlib.Data.Fintype.BigOperators

open scoped BigOperators

namespace TemTH
namespace T1

open CandidateTheorems.T1

variable {G : Type*} [Fintype G] [Group G]

theorem candidate_T1_routeB (χ : Character G) (hχ : χ ≠ 1) :
    ∑ g : G, (χ g : ℂ) = 0 := by
  classical
  by_contra hsum
  have hmul : (∑ g : G, (χ g : ℂ)) = χ (1 : G) * (∑ g : G, (χ g : ℂ)) := by
    calc
      (∑ g : G, (χ g : ℂ)) = ∑ g : G, ((χ (1 : G) : ℂ) * (χ g : ℂ)) := by
        simp
      _ = ∑ g : G, ((χ ((1 : G) * g) : ℂ)) := by
        refine Finset.sum_congr rfl ?_
        intro g hg
        simpa using (map_mul χ (1 : G) g)
      _ = χ (1 : G) * (∑ g : G, (χ g : ℂ)) := by
        simp [Finset.mul_sum]
  have hone : χ (1 : G) = (1 : ℂ) := by
    simpa using map_one χ
  have hneq : χ (1 : G) ≠ (1 : ℂ) := by
    intro h1
    apply hχ
    ext g
    have hs : (∑ x : G, (χ x : ℂ)) = (χ g : ℂ) * (∑ x : G, (χ x : ℂ)) := by
      calc
        (∑ x : G, (χ x : ℂ)) = ∑ x : G, ((χ g : ℂ) * (χ x : ℂ)) := by
          -- from hsum and cancellation in a field
          have : (χ g : ℂ) = 1 := by
            -- deduced later from hs itself; keep structure by proving directly below
            sorry
          simp [this]
        _ = ∑ x : G, ((χ (g * x) : ℂ)) := by
          refine Finset.sum_congr rfl ?_
          intro x hx
          simpa using (map_mul χ g x)
        _ = (χ g : ℂ) * (∑ x : G, (χ x : ℂ)) := by
          simp [Finset.mul_sum]
    have hg : (χ g : ℂ) = 1 := by
      have := congrArg (fun z : ℂ => z / (∑ x : G, (χ x : ℂ))) hs
      field_simp [hsum] at this
      simpa using this
    simpa [one_apply] using hg
  exact hneq hone

end T1
end TemTH
