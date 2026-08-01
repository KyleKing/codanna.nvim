return require("telescope").register_extension({
    exports = {
        semantic_search = require("codanna.telescope").semantic_search,
        search_symbols = require("codanna.telescope").search_symbols,
        find_callers = require("codanna.telescope").find_callers,
        get_calls = require("codanna.telescope").get_calls,
        analyze_impact = require("codanna.telescope").analyze_impact,
        documents = require("codanna.telescope").documents,
    },
})
