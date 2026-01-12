return require("telescope").register_extension({
  exports = {
    semantic_search = require("codanna.telescope").semantic_search,
    find_callers = require("codanna.telescope").find_callers,
    find_implementations = require("codanna.telescope").find_implementations,
    symbols = require("codanna.telescope").symbols,
    documents = require("codanna.telescope").documents,
  },
})
