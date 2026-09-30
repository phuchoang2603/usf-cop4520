// Source: lectures/Lecture-tiled-matrix-multiplication.pdf
// PDF page(s): 23 (1-based).
// Index expressions and boundary predicate as shown; statements are illustrative excerpts.

M[Row][p*TILE_WIDTH+tx]
M[Row*Width + p*TILE_WIDTH+tx]
// Need to test
(Row < Width) && (p*TILE_WIDTH+tx < Width)
// If true, load M element
// Else, load 0
