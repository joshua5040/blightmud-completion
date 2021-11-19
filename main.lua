mod = {}
mod.lines = {first = 1; last = 0}
mod.buffer_size = 100

trigger.add("^(.+)$", {}, function(_, line)
    if mod.lines.last > mod.buffer_size then
      mod.lines[mod.lines.first] = nil
      mod.lines.first = mod.lines.first + 1
    end
    mod.lines.last = mod.lines.last + 1
    mod.lines[mod.lines.last] = line:line()
end)

function complete(input)
  local partial_word = regex.new("(\\w+)$")
  local partial_word_match = partial_word:match(input)[1]
  local complete_word = regex.new("\\b(" .. partial_word_match .. "\\w+)")
  local input_start = string.sub(input,1, #input - #partial_word_match)
  local completions = {}
  for i = mod.lines.last, mod.lines.first, -1 do
    local complete_word_matches = complete_word:match(mod.lines[i])
    if complete_word_matches then
      for j = #complete_word_matches, 1, -1 do
        table.insert(completions, input_start .. complete_word_matches[j])
      end
    end
  end
  return completions
end

blight.on_complete(complete)
