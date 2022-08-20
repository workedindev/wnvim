if exists('g:loaded_life') | finish | endif " prevent loading file twice

command! Life lua require'life'.life()

let g:loaded_life = 1

