package MarchingSquares

import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

INITIAL_SCREEN_WIDTH :: 1024
INITIAL_SCREEN_HEIGHT :: 1024

BACKGROUND_COLOR :: rl.DARKGRAY
POINT_COLOR :: rl.RAYWHITE
POINT_RADIUS :: 5

FONT_SMALL :: 32
FONT_MEDIUM :: 64
FONT_LARGE :: 96

GRID_ROWS :: 16
GRID_COLS :: 16

Point :: struct {x, y : f32, interior : bool}

screen_width := f32(INITIAL_SCREEN_WIDTH)
screen_height := f32(INITIAL_SCREEN_HEIGHT)

frame_time : f32
paused := false
message : cstring

grid : [GRID_ROWS][GRID_COLS]Point

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

    x_offset := screen_width / f32(GRID_COLS) / 2
    y_offset := screen_height / f32(GRID_ROWS) / 2
    for ii in 0..<GRID_ROWS {
        for jj in 0..<GRID_COLS {
            grid[ii][jj].x = f32(jj) / f32(GRID_COLS) * screen_width + x_offset
            grid[ii][jj].y = f32(ii) / f32(GRID_ROWS) * screen_height + y_offset
        }
    }
}

update_sim :: proc() {
    
}

draw_sim :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(BACKGROUND_COLOR)

    for row in grid {
        for point in row {
            rl.DrawCircle(i32(point.x), i32(point.y), POINT_RADIUS, POINT_COLOR)
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
