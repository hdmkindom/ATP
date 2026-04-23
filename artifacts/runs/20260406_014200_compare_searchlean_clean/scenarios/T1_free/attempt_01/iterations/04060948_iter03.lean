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
  let S : ℂ := ∑ g : G, (χ g : ℂ)
  have hS0 : S ≠ 0 := by
    simpa [S] using hsum
  have hmul : ∀ a : G, (χ a : ℂ) * S = S := by
    intro a
    have hperm :
        ∑ g : G, (χ (a * g) : ℂ) = ∑ g : G, (χ g : ℂ) := by
      simpa using
        (Fintype.sum_bijective (f := fun g : G => a * g) (by
          exact Function.LeftInverse.bijective (fun g => a⁻¹ * g) (by intro g; simp [mul_assoc])))
    calc
      (χ a : ℂ) * S = (χ a : ℂ) * ∑ g : G, (χ g : ℂ) := by rfl
      _ = ∑ g : G, ((χ a : ℂ) * (χ g : ℂ)) := by simp [mul_sum]
      _ = ∑ g : G, (χ (a * g) : ℂ) := by
            congr with g
            simpa using (map_mul χ a g)
      _ = ∑ g : G, (χ g : ℂ) := hperm
      _ = S := by rfl
  have hone_at_all : ∀ a : G, χ a = 1 := by
    intro a
    have hEq : (χ a : ℂ) * S = S := hmul a
    have hEq' : ((χ a : ℂ) - 1) * S = 0 := by
      linarith
    have hchiC : (χ a : ℂ) = 1 := by
      apply sub_eq_zero.mp
      apply mul_eq_zero.mp hEq' |>.resolve_right hS0
    exact Character.ext_val hchiC
  have hχ1 : χ = 1 := by
    ext a
    exact hone_at_all a
  exact hχ hχ1

end T1
end TemTH
