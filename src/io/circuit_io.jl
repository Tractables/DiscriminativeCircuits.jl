export zoo_dc_file, zoo_discriminative, zoo_dc

struct  DiscriminativeFormat <: FileFormat end

const DiscriminativeVtreeFormat = Tuple{DiscriminativeFormat, VtreeFormat}
Tuple{DiscriminativeVtreeFormat,VtreeFormat}() = (DiscriminativeFormat(), VtreeFormat())

zoo_dc_file(name) = 
    artifact"circuit_model_zoo" * zoo_version * "/lcs/$name"


"""
    zoo_dc(name)

Loads a discriminative circuit (logistic circuit or regression circuit) from the model zoo.
See https://github.com/UCLA-StarAI/Circuit-Model-Zoo.    
"""
zoo_dc(name) = 
    read(zoo_dc_file(name), DiscriminativeCircuit, DiscriminativeFormat())

const zoo_discriminative = zoo_dc

const discriminative_grammer = raw"""
    start: _header (_NL node)+ _NL?

    _header : "Logisitic" _WS "Circuit" | "Logistic" _WS "Circuit" | "Regression" _WS "Circuit" 

    node: "T" _WS INT _WS INT _WS INT _WS params -> true_node
      | "F" _WS INT _WS INT _WS INT _WS params -> false_node
      | "D" _WS INT _WS INT _WS INT _WS elems -> or_node
      | "B" _WS params -> bias_node

      
    elem: "(" INT _WS INT _WS params ")"

    elems: elem (_WS elem)*

    params: LOGPROB (_WS LOGPROB)* 

    %import common.INT
    %import common.SIGNED_INT
    %import common.SIGNED_NUMBER -> LOGPROB
    %import common.WS_INLINE -> _WS
    %import common.NEWLINE -> _NL
    """ * dimacs_comments


const discriminative_parser = Lark(discriminative_grammer)

abstract type DiscriminativeParse <: JuiceTransformer end

mutable struct DiscriminativeParsePlain <: DiscriminativeParse
    nodes::Dict{String, LogisticCircuit}
    root::LogisticCircuit
    DiscriminativeParsePlain() = new(Dict{String, LogisticCircuit}(), LogisticLiteralNode(0))
end

@rule start(t::DiscriminativeParsePlain, x) = begin
    x[end]
end

@rule elem(t::DiscriminativeParsePlain, x) = begin
    [t.nodes[x[1]], t.nodes[x[2]], x[3]]
end

@rule elems(t::DiscriminativeParsePlain, x) = begin
   Array(x) 
end

@rule params(t::DiscriminativeParsePlain, x) = begin
    map(p -> Base.parse(Float32, p), Array(x))
end

@rule true_node(t::DiscriminativeParsePlain, x) = begin
    lit = Base.parse(Lit, x[3])
    # In Juice, LogisticCircuit leaves are an Or node with one child
    node = Logistic⋁Node([LogisticLiteralNode(lit)], length(x[4]))
    node.thetas[1,:] .= x[4]
    t.nodes[x[1]] = node
end

@rule false_node(t::DiscriminativeParsePlain, x) = begin
    lit = -Base.parse(Lit, x[3])
    # In Juice, LogisticCircuit leaves are an Or node with one child
    node = Logistic⋁Node([LogisticLiteralNode(lit)], length(x[4]))
    node.thetas[1,:] .= x[4]
    t.nodes[x[1]] = node
    t.root = node
end


@rule or_node(t::DiscriminativeParsePlain, x) = begin
    @assert length(x[4]) == Base.parse(Int, x[3])
    children = map(x[4]) do elem
        Logistic⋀Node(elem[1:2])
    end

    node = Logistic⋁Node(children, length(x[4][1][3]))
    for i = 1:length(children)
        node.thetas[i, :] .= x[4][i][3]
    end
    t.nodes[x[1]] = node
    t.root = node
end

@rule bias_node(t::DiscriminativeParsePlain, x) = begin
    node = Logistic⋁Node([t.root], length(x[1]))
    node.thetas[1, :] .= x[1]
    t.root = node
end

function Base.parse(::Type{DiscriminativeCircuit}, str::AbstractString, ::DiscriminativeFormat)
    ast = Lerche.parse(discriminative_parser, str)
    Lerche.transform(DiscriminativeParsePlain(), ast)
end

Base.read(io::IO, ::Type{LogisticCircuit}, ::DiscriminativeFormat) = 
    parse(LogisticCircuit, read(io, String), DiscriminativeFormat())

# function Base


###########################################################
#  Write DiscriminativeCircuits
###########################################################

const DISCRIM_FORMAT = """c This file was saved by DiscriminativeCircuits.jl
c variables (from inputs) start from 1
c ids of logistic circuit nodes start from 0
c nodes appear bottom-up, children before parents
c the last line of the file records the bias parameter
c three types of nodes:
c	T (terminal nodes that correspond to true literals)
c	F (terminal nodes that correspond to false literals)
c	D (OR gates)
c
c file syntax:
c
c Logistic Circuit | Regression Circuit
c T id-of-true-literal-node id-of-vtree variable parameters
c F id-of-false-literal-node id-of-vtree variable parameters
c D id-of-or-gate id-of-vtree number-of-elements (id-of-prime id-of-sub parameters)s
c B bias-parameters
c
Logistic Circuit"""


function Base.write(io::IO, pc::DiscriminativeCircuit, ::DiscriminativeFormat, vtree2id::Function = (x -> 0))
    
    labeling = label_nodes(pc)
    map!(x -> x-1, values(labeling)) # vtree nodes are 0-based indexed

    println(io, DISCRIM_FORMAT)
    foreach(pc) do node
        if isliteralgate(node)
            # do nothing
        elseif isconstantgate(node)
            @assert false "Cannot have constant gates $(node)"
        elseif is⋁gate(node) && length(node.children) == 1 && isliteralgate(node.children[1])
            cc = node.children[1]
            t = ispositive(cc) ? "T" : "F"
            plit = ispositive(cc) ? literal(node.children[1]) : -literal(node.children[1])
    
            print(io, "$(t) $(labeling[node]) $(vtree2id(node)) $(plit) ")
            for p in node.thetas[1, :]
                print(io, " $p")
            end
            println(io)
        elseif is⋀gate(node)
            # do nothing
        else
            @assert is⋁gate(node)
            # Bias node
            if length(node.children) == 1 && is⋁gate(node.children[1])
                print(io, "B")
                for p in node.thetas[1,:]
                    print(io, " $p")
                end
                println(io)
            else
                print(io, "D $(labeling[node]) $(vtree2id(node)) $(length(node.children))") 
                for (id, child) in enumerate(node.children)
                    print(io, " ($(labeling[child.children[1]]) $(labeling[child.children[2]])")
                    for p in node.thetas[id, :]
                        print(io, " $p")
                    end
                    print(io, ")")
                end
                println(io)
            end
        end
    end

end

# function Base.write(ios::Tuple{IO,IO}, pc::DiscriminativeCircuit, format::VtreeFormat)
#     vtree2id = write(ios[2], vtree(pc), format[2])
#     write(ios[1], pc, format[1], i -> vtree2id[vtree(i)])
# endl