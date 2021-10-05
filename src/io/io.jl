using LogicCircuits
using LogicCircuits: JuiceTransformer, dimacs_comments, zoo_version

using Pkg.Artifacts
using Lerche: Lerche, Lark, Transformer, @rule, @inline_rule

include("circuit_io.jl")

# if no logic circuit file format is given on read, infer file format from extension
function file2pcformat(file) 
    if endswith(file,".circuit")
        DiscriminativeFormat()
    else
        # try a logic circuit format
        LogicCircuits.file2logicformat(file)
    end
end


"""
    Base.read(file::AbstractString, ::Type{C}) where C <: LogisticCircuit

Reads circuit from file; uses extension to detect format type.
"""
Base.read(file::AbstractString, ::Type{C}) where C <: LogisticCircuit =
    read(file, C, file2pcformat(file))

Base.read(files::Tuple{AbstractString,AbstractString}, ::Type{C}) where C <: LogisticCircuit =
    read(files, C, (file2pcformat(files[1]), VtreeFormat()))

"""
    Base.write(file::AbstractString, circuit::LogisticCircuit)

Writes circuit to file; uses file name extention to detect file format.
"""
Base.write(file::AbstractString, circuit::LogisticCircuit) =
    write(file, circuit, file2pcformat(file))

"""
    Base.write(files::Tuple{AbstractString,AbstractString}, circuit::LogisticCircuit)

Saves circuit and vtree to file.
"""
Base.write(files::Tuple{AbstractString,AbstractString}, 
           circuit::LogisticCircuit) =
    write(files, circuit, (file2pcformat(files[1]), VtreeFormat()))


# # copy read/write API for tuples of files
function Base.read(files::Tuple{AbstractString, AbstractString}, ::Type{C}, args...) where C <: LogisticCircuit
    open(files[1]) do io1 
        open(files[2]) do io2 
            read((io1, io2), C, args...)
        end
    end
end

function Base.write(files::Tuple{AbstractString,AbstractString},
                    circuit::LogisticCircuit, args...) 
    open(files[1], "w") do io1
        open(files[2], "w") do io2
            write((io1, io2), circuit, args...)
        end
    end
end 