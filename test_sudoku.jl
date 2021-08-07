
using Test 

using Revise
Revise.includet("sudoku_solver.jl")


grid_17 = [
    0 0 0  7 0 0  0 0 0;
    1 0 0  0 0 0  0 0 0;
    0 0 0  4 3 0  2 0 0;

    0 0 0  0 0 0  0 0 6;
    0 0 0  5 0 9  0 0 0;
    0 0 0  0 0 0  4 1 8;

    0 0 0  0 8 1  0 0 0;
    0 0 2  0 0 0  0 5 0;
    0 4 0  0 0 0  3 0 0
]


grid_easy1 = [
    0 0 0  2 7 3  9 0 5;
    5 0 0  0 0 9  0 3 7;
    7 9 0  4 0 0  0 0 2;

    0 8 0  5 2 6  4 0 0;
    1 6 5  8 0 0  0 0 0;
    0 0 2  0 9 0  5 0 6;

    0 0 1  0 0 5  3 6 0;
    9 3 8  0 6 2  0 0 0;
    0 0 0  9 3 0  0 2 8
]


grid_easy1_solution = [
    8  1  6  2  7  3  9  4  5;
    5  2  4  6  1  9  8  3  7;
    7  9  3  4  5  8  6  1  2;
    3  8  9  5  2  6  4  7  1;
    1  6  5  8  4  7  2  9  3;
    4  7  2  3  9  1  5  8  6;
    2  4  1  7  8  5  3  6  9;
    9  3  8  1  6  2  7  5  4;
    6  5  7  9  3  4  1  2  8
]


grid_easy2 = [
    5 3 0  0 7 0  0 0 0;
    6 0 0  1 9 5  0 0 0;
    0 9 8  0 0 0  0 6 0;

    8 0 0  0 6 0  0 0 3;
    4 0 0  8 0 3  0 0 1;
    7 0 0  0 2 0  0 0 6;
    
    0 6 0  0 0 0  2 8 0;
    0 0 0  4 1 9  0 0 5;
    0 0 0  0 8 0  0 7 9
]


@testset "find_options" begin
    @test find_options(grid_easy1, 1, 2) == Set([4, 1])
    @test find_options(grid_easy1, 2, 1) == Set{Int}()
    @test find_options(grid_easy2, 1, 3) == Set([1, 2, 4])
    @test find_options(grid_easy2, 5, 5) == Set([5])
    @test find_options(grid_easy2, 6, 2) == Set([1, 5])
    @test find_options(grid_easy2, 9, 7) == Set([1, 3, 4, 6])
end


@testset "check_done" begin
    @test check_done(grid_easy1_solution) 
end


@testset "check_possible" begin
    # impossible
    puzzles = [
        # From https://norvig.com/sudoku.html  -> column 4, no (1, 5, 6) possible because of triple 5-6 doubles and triple 1s
        # ".....5.8....6.1.43..........1.5........1.6...3.......553.....61........4.........",   # need to flush candidates first
        # obvious doubles
        "12.......34...............5...........5..........................................",  
        "11.......34...............5......................................................",
    ]
    for puzzle_str in puzzles
        puzzle = str2grid(puzzle_str)
        result, message = check_possible(SudokuGrid(puzzle))
        @test !result
    end 
end


@testset "check solver easy" begin
    # check sovler using manually solved puzzles
    # easy Sudokus (no backtracking required). From New York Times, 31 May 2020 - 2 June 2020
    puzzles = [
        (
            "280070309600104007745080006064830100102009800000201930006050701508090020070402050",
            "281576349693124587745983216964835172132749865857261934426358791518697423379412658"
        ),
        (
            "910780200027001894684000300000846001740059080009000050106093008000500706002070130",
            "913784265527361894684925317235846971741259683869137452176493528398512746452678139"
        ) 
    ]
    for (puzzle, solution) in puzzles
        puzzle, solution = map(str2grid, [puzzle, solution])
        solution_set, info = solve_sudoku(puzzle, all_solutions=false)
        @test solution_set[1] == solution
    end
end


@testset "check solver medium" begin
    # check sovler using manually solved puzzles
    # medium to hard Sudoku (some backtracking). From New York Times, 31 May 2020 - 2 June 2020
    puzzles = [
        (
            "100020400035040900704000001800000000091032080000100097070900600000000000000450000",
            "189327465235641978764895321827569143491732586653184297372918654546273819918456732"
        ),
        (
            "000832067000600200800700010010020000509004700000008000007000940000005000402000500",
            "195832467743651298826749315318927654569314782274568139657283941931475826482196573"
        ),
        (
            "000010030009005008804006025000000600008004000120087000300900200065008000900000000",
            "752819436639245718814736925473592681598164372126387549387951264265478193941623857"
        )
    ]
    for (puzzle, solution) in puzzles
        puzzle, solution = map(str2grid, [puzzle, solution])
        solution_set, info = solve_sudoku(puzzle, all_solutions=false)
        @test solution_set[1] == solution
    end
end


@testset "check solved pzzule" begin
     # these puzzles were sovled with the solver. This is to check solutions still hold.
     puzzles = [
            # from https://dev.to/aspittel/how-i-finally-wrote-a-sudoku-solver-177g
            (   
                # very easy puzzle
                "530070000600195000098000060800060003400803001700020006060000280000419005000080079", 
                "534678912672195348198342567859761423426853791713924856961537284287419635345286179"
             ),
            # https://www.nytimes.com/puzzles/sudoku/
            (
                "106000050070030004090005200002060007000108000047020000000000803003200006000000002" , 
                "186742359275839164394615278812564937639178425547923681721456893953281746468397512"
            ),
            # Arto Inkala Puzzles from  https://norvig.com/sudoku.html
            (   
                # not that hard actually
                "85...24..72......9..4.........1.7..23.5...9...4...........8..7..17..........36.4.", 
                "859612437723854169164379528986147352375268914241593786432981675617425893598736241"
            ),
            (   
                # have to make at least 3 guesses
                "..53.....8......2..7..1.5..4....53...1..7...6..32...8..6.5....9..4....3......97..", 
                "145327698839654127672918543496185372218473956753296481367542819984761235521839764"
            ),
            (   
                # have to make at least 3 guesses
                "800000000003600000070090200050007000000045700000100030001000068008500010090000400", 
                "812753649943682175675491283154237896369845721287169534521974368438526917796318452"
            ),
            # 17 clue puzzle from https://theconversation.com/good-at-sudoku-heres-some-youll-never-complete-5234
            (
                #  1 unique solution. Very fun to do
                "000700000100000000000430200000000006000509000000000418000081000002000050040000300", 
                "264715839137892645598436271423178596816549723759623418375281964982364157641957382"
            ),
            # 17 clue puzzle from  https://cracking-the-cryptic.web.app/sudoku/PMhgbbQRRb
            (
                "029000400000500100040000000000042000600000070500000000700300005010090000000000060", 
                "329816457867534192145279638931742586684153279572968314796321845418695723253487961"
            ), 
             # https://www.sudokuwiki.org/Weekly_Sudoku.asp
            (   # May 24 2020 Extreme -> requires multiple diabolical+extreme strategies
                "003100720700000500050240030000720000006000800000014000060095080005000009049002600", 
                "693158724724963518851247936538726491416539872972814365267495183385671249149382657"
            ),
            (   
                #403 "unsolvable" - no known logical solution
                "100200000065074800070006900004000000050008704000030000000000600080000057006007089",
                "138259476965374821472186935824761593653928714791435268517893642389642157246517389"
            ),
            (   
                #404 "unsolvable" - no known logical solution
                "400009200000010080005400006004200001050030060700005300500007600090060000002800007",
                "468579213279613485135428796384296571951734862726185349513947628897362154642851937"
            ),
            (
                # June 7 2020 Extreme
                "080001206000020000020305040060010900002050400008000010030704050000030000406100080",
                "785941236143628795629375841564213978912857463378469512231784659897536124456192387"
            )
        ]
        for (puzzle, solution) in puzzles
            puzzle, solution = map(str2grid, [puzzle, solution])
            solution_set, info = solve_sudoku(puzzle, all_solutions=false)
            @test solution_set[1] == solution
        end
end