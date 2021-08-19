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
    function solve(s::SudokuGrid, depth=0)
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

    s = SudokuGrid(grid)
    flush_candidates!(s)
    err = check_possible(s)
    if !err.isError
        solve(SudokuGrid(grid))
    end

    info = Dict(
        :calls => calls,
        :depth_max => depth_max,
        :error => err
    )
    
    solution_set, info
end