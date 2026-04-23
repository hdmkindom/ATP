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
  have hsum' : ∑ g : G, (χ g : ℂ) ≠ 0 := by simpa using hsum
  have hχ1 : χ 1 ≠ 1 := by
    intro h1
    apply hχ
    ext g
    have hmul : χ g = χ (1 * g) := by simpa using (congrArg χ (one_mul g))
    rw [map_mul, h1, one_mul] at hmul
    exact hmul
  let a : G := Classical.choose (not_forall.mp hχ1)
  have ha : χ a ≠ 1 := Classical.choose_spec (not_forall.mp hχ1)
  have hperm :
      (∑ g : G, (χ g : ℂ)) = ∑ g : G, (χ (a * g) : ℂ) := by
    simpa using (Finset.sum_bij (fun g _ => a * g)
      (by intro g hg; simp)
      (by intro g hg; simp)
      (by intro g1 g2 hg1 hg2 hEq; exact mul_left_cancel hEq)
      (by
        intro y hy
        refine ⟨a⁻¹ * y, by simp, ?_⟩
        simp [mul_assoc]))
  have hfac : (∑ g : G, (χ (a * g) : ℂ)) = (χ a : ℂ) * ∑ g : G, (χ g : ℂ) := by
    calc
      (∑ g : G, (χ (a * g) : ℂ))
          = ∑ g : G, ((χ a : ℂ) * (χ g : ℂ)) := by
              apply Finset.sum_congr rfl
              intro g hg
              simp [map_mul]
      _ = (χ a : ℂ) * ∑ g : G, (χ g : ℂ) := by
            simp [Finset.mul_sum]
  have hmain : (∑ g : G, (χ g : ℂ)) = (χ a : ℂ) * ∑ g : G, (χ g : ℂ) := by
    calc
      (∑ g : G, (χ g : ℂ)) = ∑ g : G, (χ (a * g) : ℂ) := hperm
      _ = (χ a : ℂ) * ∑ g : G, (χ g : ℂ) := hfac
  have hone : (χ a : ℂ) = 1 := by
    have := congrArg (fun z : ℂ => z / (∑ g : G, (χ g : ℂ))) hmain
    field_simp [hsum'] at this
    simpa using this
  exact ha (by exact_mod_cast hone)

end T1
end TemTH
