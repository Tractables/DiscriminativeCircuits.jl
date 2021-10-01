export ParamBitCircuit

import LogicCircuits: num_nodes, num_elements, num_features, num_leafs, nodes, elements
import ProbabilisticCircuits: ParamBitCircuit, to_gpu, to_cpu, isgpu #extend

function ParamBitCircuit(lc::LogisticCircuit, nc, data)
    thetas::Vector{Vector{Float32}} = Vector{Vector{Float32}}()
    on_decision(n, cs, layer_id, decision_id, first_element, last_element) = begin
        if isnothing(n)
            # @assert first_element == last_element
            push!(thetas, zeros(Float32, nc))
            # println("here, some node is not part of the logistic circuit")
        else
            # @assert last_element - first_element + 1 == size(n.thetas, 1)
            # @assert size(n.thetas, 2) == nc
            for theta in eachrow(n.thetas)
                push!(thetas, theta)
            end
        end
    end
    bc = BitCircuit(lc, data; on_decision)
    ParamBitCircuit(bc, permutedims(hcat(thetas...), (2, 1)))
end


