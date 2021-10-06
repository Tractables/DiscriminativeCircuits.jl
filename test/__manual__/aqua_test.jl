using Aqua
using DiscriminativeCircuits
using Test

@testset "Aqua tests" begin
    Aqua.test_all(DiscriminativeCircuits, 
                    ambiguities = false)
end