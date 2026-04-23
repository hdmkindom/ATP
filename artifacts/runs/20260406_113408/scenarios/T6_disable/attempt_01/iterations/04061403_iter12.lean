/-
`temTH` 模板：`T6` 禁用模式。
-/
import CandidateTheorems.T6.Support

namespace TemTH
namespace T6

open CandidateTheorems.T6

variable {α : Type*} [Fintype α]

theorem candidate_T6_disable (data : ChangeOfVariablesData (α := α)) :
    gaussSum data.χ data.ψₐ = data.scale * gaussSum data.χ data.ψ₁ := by
  simpa [ChangeOfVariablesData.scale, ChangeOfVariablesData.ψₐ, ChangeOfVariablesData.ψ₁]
    using (gaussSum_mulShift_of_isPrimitive data.hχ_primitive data.a)

end T6
end TemTH
