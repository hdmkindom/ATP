/-
`temTH` 模板：`T8` 自由模式。
-/
import CandidateTheorems.T8.Support

open scoped BigOperators

namespace TemTH
namespace T8

open CandidateTheorems.T8

variable {ι : Type*} [Fintype ι]

theorem candidate_T8_free
    (data : FourierTranslationData (ι := ι)) (f : ι → ℂ) (t a : ι) :
    fourierCoeff data (translate data t f) a =
      data.phase a t * fourierCoeff data f a := by
  classical
  unfold fourierCoeff translate
  rw [Fintype.sum_bijective (data.shift t) (data.shift_bijective t)]
  simp only
  calc
    ∑ x, f x * data.kernel a ((data.shift t) x)
        = ∑ x, f x * (data.phase a t * data.kernel a x) := by
            refine Fintype.sum_congr fun x => ?_
            rw [data.phase_mul (a := a) (x := t) (y := x)]
    _ = ∑ x, data.phase a t * (f x * data.kernel a x) := by
          refine Fintype.sum_congr fun x => ?_
          ring
    _ = data.phase a t * ∑ x, f x * data.kernel a x := by
          rw [Finset.mul_sum]

end T8
end TemTH
