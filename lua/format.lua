-- apply_diff applies the unified diff output in lines to the current buffer.
function apply_diff(lines)

    -- Collect diff hunks.

    local hunks = {}
    local hunk
    for i, line in ipairs(lines) do
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
        local hunk = hunks[i]

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

function show_qfl(qfl)
    if #qfl == 0 then
        return
    end
    vim.fn.setqflist(qfl)
    vim.api.nvim_command("cc 1")
end

-- goimports formats the current buffer with goimports.
local function goimports()

    -- Get unified diff between buffer and formatted buffer.

    local bufnr = vim.api.nvim_get_current_buf()
    local cmd = {"goimports", "-d", "-srcdir", vim.api.nvim_buf_get_name(bufnr)}
    local lines = vim.fn.systemlist(cmd, vim.api.nvim_get_current_buf())

    -- Error?

    if vim.v.shell_error ~= 0 then
        local qfl = {}
        for i, line in ipairs(lines) do
            local lnum, col, text = line:match("^.+:(%d+):(%d+):%s+(.*)")
            if lnum ~= "" then
                qfl[#qfl+1] = {bufnr=bufnr, lnum=tonumber(lnum), col=col, text=text, type="E"}
            end
        end
        show_qfl(qfl)
        return
    end

    apply_diff(lines)
end

-- black formats the current buffer with black.
local function black()

    -- Get unified diff between buffer and formatted buffer.

    local bufnr = vim.api.nvim_get_current_buf()
    local cmd = {"black", "--diff", "--quiet", "-"}
    local lines = vim.fn.systemlist(cmd, vim.api.nvim_get_current_buf())


    if vim.v.shell_error ~= 0 then
        local qfl = {}
        for i, line in ipairs(lines) do
            local m1, lnum, col, m2 = line:match("^[^:]+:[^:]+:([^:]+:%s+)(%d+):(%d+):%s+(.*)")
            if lnum then
                qfl[#qfl+1] = {bufnr=bufnr, lnum=tonumber(lnum), col=col, text=m1 .. m2, type="E"}
            else
                vim.api.nvim_err_writeln(line)
            end
        end
        show_qfl(qfl)
        return
    end

    apply_diff(lines)
end

return {
    goimports = goimports,
    black = black,
}
