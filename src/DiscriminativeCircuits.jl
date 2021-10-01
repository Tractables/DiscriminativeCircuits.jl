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
@reexport using ProbabilisticCircuits.Utils


include("logistic_nodes.jl")
include("param_bit_circuit_pair.jl")

include("queries/expectation_rec.jl")
include("queries/expectation_graph.jl")
include("queries/expectation_bit.jl")

include("Logistic/queries.jl")
include("Logistic/parameters.jl")

include("io/io.jl")

# TODO structure learning

end # module
