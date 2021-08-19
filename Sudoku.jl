#=
Sudoku.jl

Lior Sinai, 6 August 2021

Based off my previous Python solver.
See https://liorsinai.github.io/coding/2020/07/27/sudoku-solver.html
=#

module Sudoku

export SudokuGrid,
    get_box, get_box_inds, 
    find_options, place_and_erase!,
    get_unique, get_hidden_pairs,
    flush_candidates!,
    check_done, check_possible


BOX_SIZE = 3
GRID_SIZE = 9


struct SudokuGrid
    grid::Matrix{Int}
    candidates::Matrix{Set{Int}}
end


function SudokuGrid(grid::Matrix{Int})
    if size(grid, 1) === size(grid, 2)
        n = size(grid, 1)
        candidates = [find_options(grid, i, j) for i in 1:n, j in 1:n]
        return SudokuGrid(copy(grid), candidates)
    else
        n = size(grid, 1)
        m = size(grid, 2)
        throw(DimensionMismatch("$n != $m. Require grid to be square",))
    end
end

#Base.copy(s::SudokuGrid) = SudokuGrid(copy(s.grid), copy(s.candidates))


function get_box_inds(grid::Matrix{Int}, r::Int, c::Int; box_size=BOX_SIZE)
    n = size(grid, 1)
    inds = [(-1, 1) for i in 1:n]
    i0 = floor(Int, (r - 1) / box_size) * box_size + 1
    j0 = floor(Int, (c - 1) / box_size) * box_size + 1
    num = 0
    for i in i0:(i0 + box_size - 1)
        for j in j0:(j0 + box_size - 1)
            num += 1
            inds[num] = (i, j)
        end
    end
    inds
end
get_box_inds(s::SudokuGrid, r::Int, c::Int) = get_box_inds(s.grid, r, c)
get_box(grid::Matrix{Int}, r::Int, c::Int) = [grid[i, j] for (i, j) in get_box_inds(grid, r, c)]
get_box(s::SudokuGrid, r::Int, c::Int) = get_box(s.grid, r, c)


##### ----------------------------  candidate functions ---------------------------- ##### 
function find_options(grid::Matrix{Int}, r::Int, c::Int)
    if grid[r, c] != 0
        return Set{Int}()
    end
    valid = Set(1:GRID_SIZE)
    set_row = Set(grid[r, :])
    set_col = Set(grid[:, c])
    set_box = Set(get_box(grid, r, c))
    setdiff!(valid, set_row, set_col, set_box)
    valid
end
find_options(s::SudokuGrid, r::Int, c::Int) = find_options(s.grid, r, c)


"""
place_and_erase!(s::SudokuGrid, r, c; constraint_prop=true)

remove x as a candidate in the grid in this row, column and box.
"""
function place_and_erase!(s::SudokuGrid, r::Int, c::Int, x::Int; constraint_prop::Bool=true)
    n = size(s.grid, 1)
    # place candidate x
    s.grid[r, c] = x
    s.candidates[r, c] = Set{Int}()
    # remove candidate x in neighbours
    inds_row = [(r, j) for j in 1:n] 
    inds_col = [(i, c) for i in 1:n]
    inds_box = get_box_inds(s, r, c)
    erased = [(r, c)] # set of indices for constraint propogration
    new_erased = erase!(s, [x], vcat(inds_row, inds_col, inds_box), Tuple{Int, Int}[])
    push!(erased, new_erased...)
    while constraint_prop && !isempty(erased)
        i, j = pop!(erased)
        inds_row = [(i, j_) for j_ in 1:n] 
        inds_col = [(i_, j) for i_ in 1:n]
        inds_box = get_box_inds(s, i, j)
        for inds in [inds_row, inds_col, inds_box]
            # apply strategies
            # 1. hidden singles
            uniques = get_unique(s, inds)
            for (idx, unique_set) in uniques
                s.candidates[idx[1], idx[2]] = copy(unique_set)
                new_erased = erase!(s, collect(unique_set), inds, [idx])
                push!(erased, new_erased...)
            end
            hidden_pairs = get_hidden_pairs(s, inds)
            for (pair_inds, pair) in hidden_pairs
                for idx in pair_inds
                    s.candidates[idx[1], idx[2]] = copy(pair)
                    new_erased = erase!(s, collect(pair), inds, pair_inds)
                    push!(erased, new_erased...)
                end
            end
        end
    end
    nothing
end


""" 
erase!(s::SudokuGrid, numbers, indices, keep)

Erase numbers as candidates in indices but not in keep. 
Return indices where edited for constraint propogration.
"""
function erase!(s::SudokuGrid, numbers::Vector{Int}, indices::Vector{Tuple{Int, Int}}, keep::Vector{Tuple{Int, Int}})
    erased = Tuple{Int, Int}[]
    for (i, j) in indices
        if (i ,j) in keep
            continue
        end
        edited = false 
        for x in numbers
            if x in s.candidates[i, j]
                delete!(s.candidates[i, j], x)
                edited = true
            end
        end
        if edited
            push!(erased, (i, j))
        end
    end
    erased
end
erase!(s::SudokuGrid, numbers::Vector{Int}, indices::Vector{Tuple{Int, Int}}) = erase!(s, numbers, indices, [])

"""
candidates_map(s::SudokuGrid, indices)

map of candidates to indices where they are placeable in indices
"""
function candidates_map(s::SudokuGrid, indices::Vector{Tuple{Int, Int}})
    n = size(s.grid, 1)
    _map = [Tuple{Int, Int}[] for i in 1:n]
    for (i, j) in indices
        for number in s.candidates[i, j]
            push!(_map[number], (i, j))
        end
    end
    _map
end


function get_unique(s::SudokuGrid, indices::Vector{Tuple{Int, Int}})
    groups = candidates_map(s, indices)
    uniques = Dict{Tuple{Int, Int}, Set{Int}}()
    for (number, indices_group) in enumerate(groups)
        if length(indices_group) == 1
            uniques[indices_group[1]] = Set([number])
        end
    end
    uniques
end


function get_hidden_pairs(s::SudokuGrid, indices::Vector{Tuple{Int, Int}})
    groups = candidates_map(s, indices)
    hidden_pairs = Dict{Vector{Tuple{Int, Int}}, Set{Int}}()
    hideable = Dict(idx => (length(s.candidates[idx[1], idx[2]]) > 2) for idx in indices)
    for num1 in 1:length(groups)
        if length(groups[num1]) == 2
            for num2 in (num1 + 1):length(groups)
                g = groups[num1]
                if g == groups[num2] && (hideable[g[1]] || hideable[g[2]]) 
                    ## this is a pair and it is hidden
                    hidden_pairs[g] = Set([num1, num2])
                end
            end
        end
    end
    hidden_pairs
end


function flush_candidates!(s)
    n = size(s.grid, 1)
    rows = [[(i, j) for j in 1:n] for i in 1:n]
    cols = [[(i, j) for i in 1:n] for j in 1:n]
    boxes = Vector{Tuple{Int, Int}}[]
    for i0 in 1:BOX_SIZE:n
        for j0 in 1:BOX_SIZE:n
            push!(boxes, get_box_inds(s, i0, j0))
        end
    end
    for inds in vcat(rows, cols, boxes)
        uniques = get_unique(s, inds)
        for (idx, unique_set) in uniques
            s.candidates[idx[1], idx[2]] = copy(unique_set)
            erase!(s, collect(unique_set), inds, [idx])
        end
        hidden_pairs = get_hidden_pairs(s, inds)
        for (pair_inds, pair) in hidden_pairs
            for idx in pair_inds
                s.candidates[idx[1], idx[2]] = copy(pair)
                erase!(s, collect(pair), inds, pair_inds)
            end
        end
    end
end



##### ----------------------------  end game functions ---------------------------- ##### 
function get_counts(v::Vector{Int}; n=GRID_SIZE)
    counts = zeros(Int, n)
    for x in v
        if x == 0
            continue
        end
        counts[x] +=1
    end
    counts
end

function all_placed_and_unique(v::Vector{Int})
    counts = get_counts(v)
    for c in counts
        if c != 1
            return false
        end
    end
    true
end


function check_done(grid::Matrix{Int}; box_size=BOX_SIZE)
    grid_size = size(grid, 1)
    # check rows
    for i in 1:grid_size
        if !all_placed_and_unique(grid[i, :])
            return false
        end
    end
    # check columns
    for j in 1:grid_size
        if !all_placed_and_unique(grid[:, j])
            return false
        end
    end
    # check boxes
    for i0 in 1:box_size:grid_size
        for j0 in 1:box_size:grid_size
            if !all_placed_and_unique(get_box(grid, i0, j0))
                return false
            end
        end
    end
    true
end


##### ----------------------------  check possible ---------------------------- ##### 

struct SudokuError
    isError::Bool
    message::String
    inds::Vector{Tuple{Int, Int}}
end


function check_possible(s::SudokuGrid; box_size=BOX_SIZE)
    grid_size = size(s.grid, 1)
    # check rows
    for i in 1:grid_size
        counts = get_counts(s.grid[i, :])
        if any(counts .> 1) # there's a duplicate
            number = findfirst(counts .> 1)
            msg = "$number found multiple times in row $i"
            inds = [(i, j) for j in findall(s.grid[i, :] .== number)]
            return SudokuError(true, msg, inds)
        end
        nums = Int[]
        for j in  1:grid_size
            push!(nums, s.grid[i, j], collect(s.candidates[i, j])...)
        end
        counts = get_counts(nums)
        if any(counts .== 0) # no way to place this value in this row
            number = findfirst(counts .== 0)
            msg = "$number cannot be placed in row $i"
            inds = [(i, j) for j in 1:grid_size]
            return  SudokuError(true, msg, inds)
        end
    end
    # check columns
    for j in 1:grid_size
        counts = get_counts(s.grid[:, j])
        if any(counts .> 1) # there's a duplicate
            number = findfirst(counts .> 1)
            msg = "$number found multiple times in column $j"
            inds = [(i, j) for i in findall(s.grid[:, j] .== number)]
            return SudokuError(true, msg, inds)
        end
        nums = Int[]
        for i in 1:grid_size
            push!(nums, s.grid[i, j], collect(s.candidates[i, j])...)
        end
        counts = get_counts(nums)
        if any(counts .== 0) # no way to place this value in this row
            number = findfirst(counts .== 0)
            msg = "$number cannot be placed in column $j"
            inds = [(i, j) for i in 1:grid_size]
            return SudokuError(true, msg, inds)
        end
    end
    # check boxes
    for i0 in 1:box_size:grid_size
        for j0 in 1:box_size:grid_size
            counts = get_counts(get_box(s, i0, j0))
            if any(counts .> 1) # there's a duplicate
                number = findfirst(counts .> 1)
                msg = "$number found multiple times in box ($i0, $j0)"
                inds = [(i, j) for (i, j) in get_box_inds(s, i0, j0) if s.grid[i, j] == number]
                return SudokuError(true, msg, inds)
            end
            nums = Int[]
            for i in i0:(i0 + box_size - 1)
                for j in j0:(j0 + box_size - 1)
                    push!(nums, s.grid[i, j], collect(s.candidates[i, j])...)
                end
            end
            counts = get_counts(nums)
            if any(counts .== 0) # no way to place this value in this row
                number = findfirst(counts .== 0)
                msg = "$number cannot be placed in box ($i0, $j0)"
                inds =  get_box_inds(s, i0, j0)
                return SudokuError(true, msg, inds)
            end
        end
    end
    return SudokuError(false, "", [])
end


end #module Sudoku
