package Statistics

import "core:math"
import "core:math/linalg"

sqrt :: math.sqrt
PI :: math.PI
exp :: math.exp
inv :: linalg.inverse
det :: linalg.determinant
pow :: math.pow
dot :: linalg.dot

Gaussian :: struct($T: typeid, $N: u8) {m: [N]T, S: matrix[N, N]T}
density_gaussian :: proc(gaussian: Gaussian($T, $N), x: [N]T) -> T {
    S_inv := inv(gaussian.S)
    det_S := det(gaussian.S)
    m := gaussian.m
    return exp(-1/2.0 * dot((x - m), S_inv * (x - m))) / sqrt(pow(2 * T(PI), 2) * det_S)
}

GaussianScalar :: struct($T: typeid) {m, s: T}
density_gaussian_scalar :: proc(gaussian: GaussianScalar($T), x: T) -> T {
    m := gaussian.m
    s := gaussian.s
    return 1 / sqrt(2 * PI * s * s) * exp(-(x - m) * (x - m) / (2 * s * s))
}

density :: proc{density_gaussian, density_gaussian_scalar}
