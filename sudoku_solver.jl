#=
sudoku_solver.jl

Lior Sinai, 7 August 2021

Based off my previous Python solver.
See https://liorsinai.github.io/coding/2020/07/27/sudoku-solver.html
=#


"""
solve_sudoku(grid::Matrix{Int}; all_solution=false)

Algorithm:
1. If a square has only one candidate, place that value there.
2. If a candidate is unique within a row, box or column, place that value there (hidden singles).
3. If neither 1 or 2 is true in the entire grid, make a guess. Backtrack if the Sudoku becomes unsolvable.
"""
function solve_sudoku(grid::Matrix{Int}; all_solutions::Bool=false)
    function solve(s::Sudoku, depth=0)
        calls += 1
        depth_max = max(depth, depth_max)
        solved = false
        while !solved
            solved = true # assume solved, change if otherwise
            edited = false # if no edits, either done or stuck
            for i in 1:grid_size
                for j in 1:grid_size
                    if s.grid[i, j] == 0
                        solved = false
                        options = s.candidates[i, j]
                        if length(options) == 0  # step 1
                            return false  # this call is going nowhere
                        elseif length(options) == 1 # step 1
                            place_and_erase!(s, i, j, first(options)) # Step 2
                            edited = true
                        end
                    end 
                end # j
            end # i
            if !edited # changed nothing in this round -> either done or stuck 
                if solved
                    push!(solution_set, s.grid)
                    return true
                else
                    # Find the square with the least number of options
                    guess = argmin(map(x -> (isempty(x) ? grid_size + 10 : length(x)) , s.candidates))
                    for y in s.candidates[guess] # step 3. backtracking check point:
                        s_next = deepcopy(s)
                        place_and_erase!(s_next, guess[1], guess[2], y)
                        solved = solve(s_next, depth + 1)
                        if solved && !all_solutions
                            break # return 1 solution
                        end
                    end
                    return solved
                end 
            end # !edited 
        end # !solved
        solved
    end
    grid_size = size(grid, 1)
    calls = 0
    depth_max = 0
    solution_set = Matrix{Int}[]

    s = Sudoku(grid)
    flush_candidates!(s)
    err = check_possible(s)
    if !err.isError
        solve(s)
    end

    info = Dict(
        :calls => calls,
        :depth_max => depth_max,
        :error => err
    )
    
    solution_set, info
end


"""
place_and_erase!(s::Sudoku, r, c; constraint_prop=true)

remove x as a candidate in the grid in this row, column and box.
"""
function place_and_erase!(s::Sudoku, r::Int, c::Int, x::Int; constraint_prop::Bool=true)
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
erase!(s::Sudoku, numbers, indices, keep)

Erase numbers as candidates in indices but not in keep. 
Return indices where edited for constraint propogration.
"""
function erase!(s::Sudoku, numbers::Vector{Int}, indices::Vector{Tuple{Int, Int}}, keep::Vector{Tuple{Int, Int}})
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
erase!(s::Sudoku, numbers::Vector{Int}, indices::Vector{Tuple{Int, Int}}) = erase!(s, numbers, indices, [])

"""
candidates_map(s::Sudoku, indices)

map of candidates to indices where they are placeable in indices
"""
function candidates_map(s::Sudoku, indices::Vector{Tuple{Int, Int}})
    n = size(s.grid, 1)
    _map = [Tuple{Int, Int}[] for i in 1:n]
    for (i, j) in indices
        for number in s.candidates[i, j]
            push!(_map[number], (i, j))
        end
    end
    _map
end


function get_unique(s::Sudoku, indices::Vector{Tuple{Int, Int}})
    groups = candidates_map(s, indices)
    uniques = Dict{Tuple{Int, Int}, Set{Int}}()
    for (number, indices_group) in enumerate(groups)
        if length(indices_group) == 1
            uniques[indices_group[1]] = Set([number])
        end
    end
    uniques
end


function get_hidden_pairs(s::Sudoku, indices::Vector{Tuple{Int, Int}})
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


function flush_candidates!(s, box_size=3)
    n = size(s.grid, 1)
    rows = [[(i, j) for j in 1:n] for i in 1:n]
    cols = [[(i, j) for i in 1:n] for j in 1:n]
    boxes = Vector{Tuple{Int, Int}}[]
    for i0 in 1:box_size:n
        for j0 in 1:box_size:n
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
