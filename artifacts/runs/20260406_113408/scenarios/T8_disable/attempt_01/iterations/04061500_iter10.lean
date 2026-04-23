/-
`temTH` 模板：`T8` 禁用模式。
-/
import CandidateTheorems.T8.Support

open scoped BigOperators

namespace TemTH
namespace T8

open CandidateTheorems.T8

variable {ι : Type*} [Fintype ι]

theorem candidate_T8_disable
    (data : FourierTranslationData (ι := ι)) (f : ι → ℂ) (t a : ι) :
    fourierCoeff data (translate data t f) a =
      data.phase a t * fourierCoeff data f a := by
  simpa [translate] using
    fourierCoeff_convolution_delta (data := data) (f := f) (t := t) (a := a)

end T8
end TemTH
