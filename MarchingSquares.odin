package MarchingSquares

import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

INITIAL_SCREEN_WIDTH :: 1024
INITIAL_SCREEN_HEIGHT :: 720

BACKGROUND_COLOR :: rl.DARKGRAY
PARTICLE_COLOR :: rl.RAYWHITE

FONT_SMALL :: 32
FONT_MEDIUM :: 64
FONT_LARGE :: 96

screen_width := f32(INITIAL_SCREEN_WIDTH)
screen_height := f32(INITIAL_SCREEN_HEIGHT)

frame_time : f32
paused := false

main :: proc() {
    rl.SetTraceLogLevel(.ERROR)
    rl.SetConfigFlags({.VSYNC_HINT, .MSAA_4X_HINT})
    rl.InitWindow(INITIAL_SCREEN_WIDTH, INITIAL_SCREEN_WIDTH, "Marching Squares")
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
    
}

update_sim :: proc() {
    
}

draw_sim :: proc() {
    rl.BeginDrawing()
    defer rl.EndDrawing()

    rl.ClearBackground(BACKGROUND_COLOR)

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
