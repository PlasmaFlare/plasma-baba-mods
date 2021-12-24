plasma_utils = {
    debug_assert = function(expr, err_msg)
        if not expr then
            if not err_msg then
                err_msg = ""
            end
            error("Assertion failed: "..err_msg.."\n"..debug.traceback(), 2)
        end
    end
}