// Source: lectures/Lecture-tiled-matrix-multiplication.pdf
// PDF page(s): 24 (1-based).
// Index expressions and boundary predicate as shown; statements are illustrative excerpts.

N[p*TILE_WIDTH+ty][Col]
N[(p*TILE_WIDTH+ty)*Width+ Col]
// Need to test
(p*TILE_WIDTH+ty < Width) && (Col< Width)
// If true, load N element
// Else, load 0
