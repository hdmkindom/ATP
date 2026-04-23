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
  obtain ⟨g0, hg0⟩ :=
    not_forall.mp (by
      intro h1
      apply hχ
      ext g
      exact h1 g)
  have hmul :
      (χ g0 : ℂ) * (∑ g : G, (χ g : ℂ)) = ∑ g : G, (χ g : ℂ) := by
    calc
      (χ g0 : ℂ) * (∑ g : G, (χ g : ℂ))
          = ∑ g : G, ((χ g0 : ℂ) * (χ g : ℂ)) := by
              simp [Finset.mul_sum]
      _ = ∑ g : G, (χ (g0 * g) : ℂ) := by
            refine Finset.sum_congr rfl ?_
            intro g hg
            simp [map_mul]
      _ = ∑ g : G, (χ g : ℂ) := by
            refine Finset.sum_bijective (fun g => g0 * g) ?_
            exact Equiv.bijective (Equiv.mulLeft g0)
  have hfactor : ((χ g0 : ℂ) - 1) * (∑ g : G, (χ g : ℂ)) = 0 := by
    nlinarith [hmul]
  have hsum_ne : (∑ g : G, (χ g : ℂ)) ≠ 0 := hsum
  have hchi_ne_one : (χ g0 : ℂ) ≠ 1 := by
    intro h1
    apply hg0
    ext
    simpa using h1
  have : ((χ g0 : ℂ) - 1) = 0 := by
    exact mul_eq_zero.mp hfactor |> Or.resolve_right hsum_ne
  exact hchi_ne_one (sub_eq_zero.mp this)

end T1
end TemTH
