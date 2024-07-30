package MarchingSquares

import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

INITIAL_SCREEN_WIDTH :: 1024
INITIAL_SCREEN_HEIGHT :: 1024

BACKGROUND_COLOR :: rl.DARKGRAY
POINT_INTERIOR_COLOR :: rl.RAYWHITE
POINT_EXTERIOR_COLOR :: rl.BLACK
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

        return -(x2 / a2 + y2 / b2)
    }
    threshold = -1

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
    for ii in 0..<len(grid) {
        for jj in 0..<len(grid[ii]) {
            if implicit_fn(grid[ii][jj].x, grid[ii][jj].y) > threshold {
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

    for row in grid {
        for point in row {
            if point.interior {
                rl.DrawCircle(i32(point.x), i32(point.y), POINT_RADIUS, POINT_INTERIOR_COLOR)
            } else {
                rl.DrawCircle(i32(point.x), i32(point.y), POINT_RADIUS, POINT_EXTERIOR_COLOR)
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
