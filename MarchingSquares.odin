package MarchingSquares

import "core:fmt"
import "core:math"
import "core:math/linalg"
import st "Statistics"
import rl "vendor:raylib"

/* Vertex and Edge Table
V0 ---- E0 ---- V1
 |               |
 |               |
 |               |
E3              E1
 |               |
 |               |
 |               |
V3 ---- E2 ---- V2

V0, E0 = 0b0001
V1, E1 = 0b0010
V2, E2 = 0b0100
V3, E3 = 0b1000
*/

INITIAL_SCREEN_WIDTH :: 1024
INITIAL_SCREEN_HEIGHT :: 1024

BACKGROUND_COLOR :: rl.DARKGRAY
LINE_COLOR :: rl.RAYWHITE
POINT_INTERIOR_COLOR :: rl.RAYWHITE
POINT_EXTERIOR_COLOR :: rl.BLACK
POINT_RADIUS :: 3

FONT_SMALL :: 32
FONT_MEDIUM :: 64
FONT_LARGE :: 96

GRID_ROWS :: 64
GRID_COLS :: 64

log :: proc(x: $T) -> T {return math.log(x, math.e)}

// Contains all possible active edge configurations
edge_table : [16]u8 = {
    0b0000,
    0b1001,
    0b0011,
    0b1010,
    0b0110,
    0b1111,
    0b0101,
    0b1100,
    0b1100,
    0b0101,
    0b1111,
    0b0110,
    0b1010,
    0b0011,
    0b1001,
    0b0000,
}

// Contains all possible vertex pairs
line_table : [16][4]i8 = {
    {-1, -1, -1, -1},
    { 0,  3, -1, -1},
    { 0,  1, -1, -1},
    { 1,  3, -1, -1},
    { 1,  2, -1, -1},
    { 0,  1,  2,  3},
    { 0,  2, -1, -1},
    { 2,  3, -1, -1},
    { 2,  3, -1, -1},
    { 0,  2, -1, -1},
    { 0,  3,  1,  2},
    { 1,  2, -1, -1},
    { 1,  3, -1, -1},
    { 0,  1, -1, -1},
    { 0,  3, -1, -1},
    {-1, -1, -1, -1},
}

Point :: struct {pos : [2]f32, value : f32}

screen_width := f32(INITIAL_SCREEN_WIDTH)
screen_height := f32(INITIAL_SCREEN_HEIGHT)

frame_time : f32
paused := false
pre_pause_message : cstring
message : cstring
draw_points : bool

grid : [GRID_ROWS][GRID_COLS]Point

implicit_fn : proc(pos : [2]f32) -> f32
isovalue : f32

main :: proc() {
    rl.SetTraceLogLevel(.ERROR)
    rl.SetConfigFlags({.VSYNC_HINT, .MSAA_4X_HINT})
    rl.InitWindow(INITIAL_SCREEN_WIDTH, INITIAL_SCREEN_HEIGHT, "Marching Squares")
    defer rl.CloseWindow()

    init_sim()
    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        screen_height = f32(rl.GetScreenHeight())
        screen_width = f32(rl.GetScreenWidth())
        frame_time = rl.GetFrameTime()
        update_sim()
        draw_sim()
    }
}

init_sim :: proc() {
    implicit_fn = proc(pos: [2]f32) -> f32 {
        sigma_x : f32 = 100000.0
        sigma_y : f32 = 50000.0
        d := st.Gaussian(f32, 2){
            {screen_width / 2.0, screen_height / 2.0},
            {sigma_x, 0.0, 0.0, sigma_y},
        }

        return -st.density(d, pos)
    }
    isovalue = -1e-6

    x_offset := screen_width / f32(GRID_COLS) / 2.0
    y_offset := screen_height / f32(GRID_ROWS) / 2.0
    for ii in 0..<GRID_ROWS {
        for jj in 0..<GRID_COLS {
            grid[ii][jj].pos[0] = f32(jj) / f32(GRID_COLS) * screen_width + x_offset
            grid[ii][jj].pos[1] = f32(ii) / f32(GRID_ROWS) * screen_height + y_offset
            grid[ii][jj].value = implicit_fn(grid[ii][jj].pos)
        }
    }
}

update_sim :: proc() {
    if rl.IsKeyPressed(.P) {
        paused = !paused
        if paused {
            pre_pause_message = message
            message = "Paused."
        } else {
            message = pre_pause_message
        }
    }

    if paused do return

    if rl.IsKeyPressed(.SPACE) {
        draw_points = !draw_points
    }
}

draw_sim :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(BACKGROUND_COLOR)

    // Draw points
    if draw_points do for row in grid {
        for point in row {
            if point.value < isovalue {
                rl.DrawCircle(i32(point.pos[0]), i32(point.pos[1]), POINT_RADIUS, POINT_INTERIOR_COLOR)
            } else {
                rl.DrawCircle(i32(point.pos[0]), i32(point.pos[1]), POINT_RADIUS, POINT_EXTERIOR_COLOR)
            }
        }
    }

    // March the square
    for ii in 0..<(GRID_ROWS - 1) {
        for jj in 0..<(GRID_COLS - 1) {
            // Determine index
            square_index : i32
            if grid[ii    ][jj    ].value < isovalue do square_index |= 0b0001
            if grid[ii    ][jj + 1].value < isovalue do square_index |= 0b0010
            if grid[ii + 1][jj + 1].value < isovalue do square_index |= 0b0100
            if grid[ii + 1][jj    ].value < isovalue do square_index |= 0b1000

            // Determine vertices
            vert_list : [4][2]f32
            if bool(edge_table[square_index] & 0b0001) do vert_list[0] = {
                linear_interp(
                    grid[ii][jj].value,
                    grid[ii][jj + 1].value,
                    grid[ii][jj].pos[0],
                    grid[ii][jj + 1].pos[0],
                    isovalue
                ),
                grid[ii][jj].pos[1],
            }
            if bool(edge_table[square_index] & 0b0010) do vert_list[1] = {
                grid[ii][jj + 1].pos[0],
                linear_interp(
                grid[ii][jj + 1].value,
                grid[ii + 1][jj + 1].value,
                grid[ii][jj + 1].pos[1],
                grid[ii + 1][jj + 1].pos[1],
                isovalue
            ),
            }
            if bool(edge_table[square_index] & 0b0100) do vert_list[2] = {
                linear_interp(
                    grid[ii + 1][jj + 1].value,
                    grid[ii + 1][jj].value,
                    grid[ii + 1][jj + 1].pos[0],
                    grid[ii + 1][jj].pos[0],
                    isovalue
                ),
                grid[ii + 1][jj + 1].pos[1],
            }
            if bool(edge_table[square_index] & 0b1000) do vert_list[3] = {
                grid[ii + 1][jj].pos[0],
                linear_interp(
                    grid[ii + 1][jj].value,
                    grid[ii][jj].value,
                    grid[ii + 1][jj].pos[1],
                    grid[ii][jj].pos[1],
                    isovalue
                ),
            }

            // Draw lines between the vertices
            for kk := 0; kk < 4 && line_table[square_index][kk] != -1; kk += 2 {
                start := vert_list[line_table[square_index][kk]]
                end := vert_list[line_table[square_index][kk + 1]]
                rl.DrawLineV(start, end, LINE_COLOR)
            }
        }
    }

    message_width := rl.MeasureText(message, FONT_MEDIUM)
    rl.DrawText(
        message,
        i32(0.5 * (screen_width - f32(message_width))),
        i32(0.75 * screen_height - FONT_MEDIUM),
        FONT_MEDIUM,
        rl.LIGHTGRAY,
    )

    rl.DrawFPS(0, 0)
}

linear_interp :: proc(x1, x2, y1, y2, x : f32) -> f32 {
    return y1 + (x - x1) * (y2 - y1) / (x2 - x1)
}

timeout :: proc(duration: f32) {
    timeout_remaining := duration
    for timeout_remaining > 0 {
        draw_sim()
        if rl.WindowShouldClose() {
            rl.CloseWindow()
        }
        timeout_remaining -= rl.GetFrameTime()
    }
}

wait_for_key :: proc(key: rl.KeyboardKey) {
    waiting_for_key := true
    for waiting_for_key {
        if rl.IsKeyPressed(key) {
            waiting_for_key = false
        }
        if rl.WindowShouldClose() {
            rl.CloseWindow()
        }
        draw_sim()
    }
}
