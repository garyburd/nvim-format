# nvim-format

Format the current buffer.

Suggested use:

    autocmd FileType ft command! -buffer -nargs=0 Fmt lua require"format".formatter()

### Go imports

Install: `go get golang.org/x/tools/cmd/goimports` 

Command: `:lua require"format".goimports()`

### Python Black

Install: [See the Black documentation](https://github.com/psf/black#installation-and-usage). 

Command: `:lua require"format".black()`

