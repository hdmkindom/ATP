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
  rw [← Fintype.sum_mul, mul_comm]
  refine congrArg (fun s => data.phase a t * s) ?_
  refine Fintype.sum_bijective (data.shift t) (data.shift_bijective t)
    (fun x => f x * data.kernel a x)
    (fun y => f ((data.shift t) y) * data.kernel a ((data.shift t) y)) ?_
  intro x
  rw [data.phase_mul (a := a) (x := t) (y := x), mul_assoc, ← mul_assoc]


end T8
end TemTH
