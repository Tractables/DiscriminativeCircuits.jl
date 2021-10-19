
using Test
using LogicCircuits
using ProbabilisticCircuits
using DiscriminativeCircuits
using DataFrames: DataFrame

# This tests are supposed to test queries on the circuits
@testset "Logistic Circuit Class Conditional" begin
    # Uses a Logistic Circuit with 4 variables, and tests 3 of the configurations to 
    # match with python version.

    EPS = 1e-5; # TODO; Cannot do more with Float32
    logistic_circuit = zoo_dc("little_4var.circuit");
    @test logistic_circuit isa LogisticCircuit;

    # Step 1. Check Probabilities for 3 samples
    data = DataFrame(Bool.([0 0 0 0; 0 1 1 0; 0 0 1 1]), :auto);
    
    # Testing values before taking sigmoid, so will compare with output of `class_weights_per_instance`
    true_prob = [3.43147972 4.66740416; 
                4.27595352 2.83503504;
                3.67415087 4.93793472]
    true_prob 
            
    CLASSES = 2
    calc_prob = class_weights_per_instance(logistic_circuit, data)
    
    for i = 1:3
        for j = 1:2
            @test true_prob[i,j] ≈ calc_prob[i,j] atol= EPS;
        end
    end
end