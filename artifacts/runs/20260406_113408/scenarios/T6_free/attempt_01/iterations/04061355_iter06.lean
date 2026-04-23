/-
`temTH` 模板：`T6` 自由模式。
-/
import CandidateTheorems.T6.Support

namespace TemTH
namespace T6

open CandidateTheorems.T6

variable {α : Type*} [Fintype α]

theorem candidate_T6_free (data : ChangeOfVariablesData (α := α)) :
    gaussSum data.χ data.ψₐ = data.scale * gaussSum data.χ data.ψ₁ := by
  simpa [data.ψₐ, data.scale] using
    (gaussSum_mulShift data.χ data.ψ₁ data.aUnit).symm

end T6
end TemTH
