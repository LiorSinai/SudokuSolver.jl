#=
Sudoku.jl

Lior Sinai, 6 August 2021

Based off my previous Python solver.
See https://liorsinai.github.io/coding/2020/07/27/sudoku-solver.html
=#

module Sudokus

export Sudoku,
    get_box, get_box_inds, 
    find_options, 
    check_done, check_possible


BOX_SIZE = 3
GRID_SIZE = 9


struct Sudoku
    grid::Matrix{Int}
    candidates::Matrix{Set{Int}}
end


function Sudoku(grid::Matrix{Int})
    if size(grid, 1) === size(grid, 2)
        n = size(grid, 1)
        candidates = [find_options(grid, i, j) for i in 1:n, j in 1:n]
        return Sudoku(copy(grid), candidates)
    else
        n = size(grid, 1)
        m = size(grid, 2)
        throw(DimensionMismatch("$n != $m. Require grid to be square",))
    end
end


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
get_box_inds(s::Sudoku, r::Int, c::Int) = get_box_inds(s.grid, r, c)
get_box(grid::Matrix{Int}, r::Int, c::Int) = [grid[i, j] for (i, j) in get_box_inds(grid, r, c)]
get_box(s::Sudoku, r::Int, c::Int) = get_box(s.grid, r, c)


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
find_options(s::Sudoku, r::Int, c::Int) = find_options(s.grid, r, c)


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


function check_possible(s::Sudoku; box_size=BOX_SIZE)
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
