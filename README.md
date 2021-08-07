# SudokuSolver.jl

The algorithm for this is described in detail on my blog post: [Sudoku Solver in Python](https://liorsinai.github.io/coding/2020/07/27/sudoku-solver.html). That post was written in Python but the same strategy is followed here.


## Usage

Construct a 9×9 matrix `grid` of type  `Matrix{Int}`. Pass this to the solver as follows:

`solve_sudoku(grid, all_solutions=false)`

This will return the a tuple `(solution_set, info)`. If `solution_set` is empty no solution was found. 

## Input files

A Sudoku in grid form:  
```
 [
    8 9 0 0 7 0 0 1 0;  
    6 2 0 0 0 3 0 5 0;  
    0 0 4 0 0 0 0 0 0;  
    0 6 0 0 4 0 2 0 0;  
    0 0 0 0 8 5 4 3 0;  
    0 0 0 1 0 0 0 0 0;  
    0 0 2 7 0 0 5 0 0;  
    9 0 0 2 0 0 1 0 0;  
    5 0 0 4 0 0 0 0 0
]
```
It can be serialised by concatenating rows instead of stacking them:

> 890070010620003050004000000060040200000085430000100000002700500900200100500400000

This is more space efficient for storing multiple Sudokus.

The code has functionality to read in serialised Sudokus and convert them to a grid.

For example:
```
grid_str = "890070010620003050004000000060040200000085430000100000002700500900200100500400000"
grid = str2grid(grid_str)
9×9 Matrix{Int64}:
 8  9  0  0  7  0  0  1  0
 6  2  0  0  0  3  0  5  0
 0  0  4  0  0  0  0  0  0
 0  6  0  0  4  0  2  0  0
 0  0  0  0  8  5  4  3  0
 0  0  0  1  0  0  0  0  0
 0  0  2  7  0  0  5  0  0
 9  0  0  2  0  0  1  0  0
 5  0  0  4  0  0  0  0  0
```

## Algorithm

To solve even the most challenging of these puzzles, our Sudoku solver only needs to follow three strategies:

1. If a square has only one candidate, place that value there.
2. If a candidate is unique within a row, box or column, place that value there (hidden singles).
3. If neither 1 or 2 is true in the entire grid, make a guess. Backtrack if the Sudoku becomes unsolvable.

The code also implements a check to determine if the Sudoku is solvable. This is run at the start of each solving task.
