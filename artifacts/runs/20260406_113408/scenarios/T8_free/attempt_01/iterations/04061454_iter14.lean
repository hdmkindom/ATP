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
  rw [Finset.mul_sum]
  refine Finset.sum_congr rfl ?_
  intro x hx
  rw [mul_assoc, data.phase_mul (a := a) (x := t) (y := x)]

end T8
end TemTH
