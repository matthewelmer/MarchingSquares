package MarchingSquares

import "core:fmt"
import "core:math"
import "core:math/linalg"
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

V0 = 0b0001
V1 = 0b0010
V2 = 0b0100
V3 = 0b1000
*/

INITIAL_SCREEN_WIDTH :: 1024
INITIAL_SCREEN_HEIGHT :: 1024

BACKGROUND_COLOR :: rl.DARKGRAY
LINE_COLOR :: rl.RAYWHITE
POINT_INTERIOR_COLOR :: rl.RAYWHITE
POINT_EXTERIOR_COLOR :: rl.BLACK
POINT_RADIUS :: 5

FONT_SMALL :: 32
FONT_MEDIUM :: 64
FONT_LARGE :: 96

GRID_ROWS :: 16
GRID_COLS :: 16

line_table : [16][4]i32 = {
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

Point :: struct {x, y : f32, interior : bool}

// MarchingSquare :: struct {vertex_indices : [4]i32}

screen_width := f32(INITIAL_SCREEN_WIDTH)
screen_height := f32(INITIAL_SCREEN_HEIGHT)

frame_time : f32
paused := false
message : cstring

grid : [GRID_ROWS][GRID_COLS]Point
// lines : [dynamic]f32  // Not a leak; cleaned up on program exit.

implicit_fn : proc(x, y : f32) -> f32
threshold : f32

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
    // message = "Howdy, World!"

    // Let's do an ellipse
    implicit_fn = proc(x, y : f32) -> f32 {
        height : f32 = 500.0
        width : f32 = 920.0
        center : rl.Vector2 = {screen_width / 2.0, screen_height / 2.0}

        x2 := (x - center[0]) * (x - center[0])
        y2 := (y - center[1]) * (y - center[1])
        a2 := width / 2.0 * width / 2.0
        b2 := height / 2.0 * height / 2.0

        return x2 / a2 + y2 / b2
    }
    threshold = 1

    x_offset := screen_width / f32(GRID_COLS) / 2.0
    y_offset := screen_height / f32(GRID_ROWS) / 2.0
    for ii in 0..<GRID_ROWS {
        for jj in 0..<GRID_COLS {
            grid[ii][jj].x = f32(jj) / f32(GRID_COLS) * screen_width + x_offset
            grid[ii][jj].y = f32(ii) / f32(GRID_ROWS) * screen_height + y_offset
        }
    }
}

update_sim :: proc() {
    // Update points
    for ii in 0..<GRID_ROWS {
        for jj in 0..<GRID_COLS {
            if implicit_fn(grid[ii][jj].x, grid[ii][jj].y) < threshold {
                grid[ii][jj].interior = true
            } else {
                grid[ii][jj].interior = false
            }
        }
    }
}

draw_sim :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(BACKGROUND_COLOR)

    // Draw points
    for row in grid {
        for point in row {
            if point.interior {
                rl.DrawCircle(i32(point.x), i32(point.y), POINT_RADIUS, POINT_INTERIOR_COLOR)
            } else {
                rl.DrawCircle(i32(point.x), i32(point.y), POINT_RADIUS, POINT_EXTERIOR_COLOR)
            }
        }
    }

    // March the square
    for ii in 0..<(GRID_ROWS - 1) {
        for jj in 0..<(GRID_COLS - 1) {
            // List of vertices to draw between
            vert_list : [4][2]f32

            // Determine index
            square_index : i32
            if grid[ii    ][jj    ].interior do square_index |= 0b0001
            if grid[ii    ][jj + 1].interior do square_index |= 0b0010
            if grid[ii + 1][jj + 1].interior do square_index |= 0b0100
            if grid[ii + 1][jj    ].interior do square_index |= 0b1000

            // Determine vertices
            // TODO(melmer): Interpolation
            // TODO(melmer): Only determine those that are part of a line
            vert_list[0] = {
                (grid[ii][jj].x + grid[ii][jj + 1].x) / 2.0, grid[ii][jj].y
            }
            vert_list[1] = {
                grid[ii][jj + 1].x, (grid[ii][jj + 1].y + grid[ii + 1][jj + 1].y) / 2.0
            }
            vert_list[2] = {
                (grid[ii + 1][jj + 1].x + grid[ii + 1][jj].x) / 2.0, grid[ii + 1][jj + 1].y
            }
            vert_list[3] = {
                grid[ii + 1][jj].x, (grid[ii + 1][jj].y + grid[ii][jj].y) / 2.0
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
