module DiscriminativeCircuits


using Reexport

using LogicCircuits
# only reexport selectively from LogicCircuits
export pos_literals, neg_literals
# circuit queries
export issmooth, isdecomposable, isstruct_decomposable, 
       isdeterministic, iscanonical
# circuit status
export num_edges, num_parameters
# datasets
export twenty_datasets


using ProbabilisticCircuits


include("discriminative/logistic_nodes.jl")
include("discriminative/parameters.jl")

# TODO to fix later after adding regression circuits, right now only have logistic circuit
const DiscriminativeCircuit = LogisticCircuit

include("bitcircuits/param_bit_circuit.jl")
include("bitcircuits/param_bit_circuit_pair.jl")

include("queries/expectation_rec.jl")
include("queries/expectation_graph.jl")
include("queries/expectation_bit.jl")
include("queries/queries.jl")

# include("discriminative/parameters.jl")
include("io/io.jl")

end # module
