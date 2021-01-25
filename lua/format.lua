-- Buffer formatting tools.

-- apply_unified_diff applies unified diff output in lines to the current
-- buffer. See https://en.wikipedia.org/wiki/Diff#Unified_format for a
-- description of unified diff.
local function apply_unified_diff(lines)

    -- Collect diff hunks.

    local hunks = {}
    local hunk
    for _, line in ipairs(lines) do
        local lnum = line:match("^@@ %-(%d+)")
        if lnum then
            hunk = {lnum=lnum, del={}, repl={}}
            table.insert(hunks, hunk)
        elseif hunk then
            local prefix = line:sub(1, 1)
            local rest = line:sub(2)
            if prefix ~= "+" then
                table.insert(hunk.del, rest)
            end
            if prefix ~= "-" then
                table.insert(hunk.repl, rest)
            end
        end
    end

    -- Apply entire hunks in reverse order.

    for i = #hunks, 1, -1 do
        hunk = hunks[i]

        -- Trim common suffix.
        while #hunk.del > 0 and (hunk.del[#hunk.del] == hunk.repl[#hunk.repl]) do
            table.remove(hunk.del)
            table.remove(hunk.repl)
        end

        -- Trim common prefix.
        while #hunk.del > 0 and (hunk.del[1] == hunk.repl[1]) do
            hunk.lnum = hunk.lnum + 1
            table.remove(hunk.del, 1)
            table.remove(hunk.repl, 1)
        end

        vim.api.nvim_buf_set_lines(0, hunk.lnum - 1, hunk.lnum + #hunk.del - 1, 1, hunk.repl)
    end
end

-- show_error displays the error in lines through quick fix or the error buffer.
local function show_error(lines, qffn)
    local qfl = {}
    for _, line in ipairs(lines) do
        local qf = qffn(line)
        if qf then
            qfl[#qfl+1] = qf
        end
    end
    if #qfl == 0 then
        vim.api.nvim_err_writeln(table.concat(lines, "\n"))
        return
    end
    vim.fn.setqflist(qfl)
    vim.api.nvim_command("cc 1")
end

-- goimports formats the current buffer with goimports.
local function goimports()

    local bufnr = vim.api.nvim_get_current_buf()
    local cmd = {"goimports", "-d", "-srcdir", vim.api.nvim_buf_get_name(bufnr)}
    local lines = vim.fn.systemlist(cmd, vim.api.nvim_get_current_buf())

    if vim.v.shell_error ~= 0 then
        show_error(lines, function(line)
            local lnum, col, text = line:match("^.+:(%d+):(%d+):%s+(.*)")
            if lnum ~= "" then
                return {bufnr=bufnr, lnum=tonumber(lnum), col=col, text=text, type="E"}
            end
        end)
        return
    end

    apply_unified_diff(lines)
end

-- black formats the current buffer with black.
local function black()

    local bufnr = vim.api.nvim_get_current_buf()
    local cmd = {"black", "--diff", "--quiet", "-"}
    local lines = vim.fn.systemlist(cmd, vim.api.nvim_get_current_buf())

    if vim.v.shell_error ~= 0 then
        show_error(lines, function(line)
            local m1, lnum, col, m2 = line:match("^[^:]+:[^:]+:([^:]+:%s+)(%d+):(%d+):%s+(.*)")
            if lnum then
                return {bufnr=bufnr, lnum=tonumber(lnum), col=col, text=m1 .. m2, type="E"}
            end
        end)
        return
    end

    apply_unified_diff(lines)
end

return {
    goimports = goimports,
    black = black,
}
