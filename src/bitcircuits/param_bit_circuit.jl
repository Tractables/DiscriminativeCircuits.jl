export ParamBitCircuit

import LogicCircuits: num_nodes, num_elements, num_features, num_leafs, 
    nodes, elements, num_examples, isbinarydata, iscomplete

@inline num_features(x::BitMatrix) = size(x)[2]
@inline num_examples(x::BitMatrix) = size(x)[1]
@inline isbinarydata(x::BitMatrix) = true
@inline iscomplete(x::BitMatrix) = true

@inline num_classes(pbc::ParamBitCircuit, ::Type{LogisticCircuit}) = size(pbc.params)[2]

function ParamBitCircuit(lc::LogisticCircuit, data)
    nc = num_classes(lc)
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


