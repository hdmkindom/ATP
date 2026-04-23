/-
`temTH` 模板：`T8` 路线 A。
-/
import CandidateTheorems.T8.Support

open scoped BigOperators

namespace TemTH
namespace T8

open CandidateTheorems.T8

variable {ι : Type*} [Fintype ι]

theorem candidate_T8_routeA
    (data : FourierTranslationData (ι := ι)) (f : ι → ℂ) (t a : ι) :
    fourierCoeff data (translate data t f) a =
      data.phase a t * fourierCoeff data f a := by
  classical
  unfold fourierCoeff translate
  rw [← Finset.sum_mul]
  refine Finset.sum_bij (fun x _ => data.sub x t) ?_ ?_ ?_ ?_
  · intro x hx
    simp
  · intro x hx
    rw [data.kernel_sub_right]
    ring
  · intro x₁ _ x₂ _ h
    exact data.sub_right_cancel h
  · intro y hy
    refine ⟨data.add y t, by simp, ?_⟩
    simp [data.sub_add_cancel]

end T8
end TemTH
