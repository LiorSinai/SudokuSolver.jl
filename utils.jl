#=
utils.jl

Lior Sinai, 7 August 2021

Based off my previous Python solver.
See https://liorsinai.github.io/coding/2020/07/27/sudoku-solver.html
=#


function str2vec(s::String)
    vec = Int[]
    last = findfirst('-', s)
    last = isnothing(last) ? length(s) : last - 1
    for c in s[1:last]
        if c == '.'
            push!(vec, 0)
        else
            push!(vec, parse(Int, c))
        end
    end
    vec
end

unflatten(vec::Vector, n=9) = permutedims(reshape(vec, (n, n)))
str2grid(s::String, n=9) = unflatten(str2vec(s), n)