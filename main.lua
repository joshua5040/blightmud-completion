local output_history = {first = 1; last = 0}
local output_history_length = 100

trigger.add("^(.+)$", {}, function(_, line)
    if output_history.last > output_history_length then
      output_history[output_history.first] = nil
      output_history.first = output_history.first + 1
    end
    output_history.last = output_history.last + 1
    output_history[output_history.last] = line:line()
end)

local function complete_filepath(partial_path, prefix)
  local prefix = prefix or ''
  local completions = {}
  local response = core.exec("compgen -f " .. partial_path)
  for line in response:stdout():gmatch("([^\n]+)") do
    if core.exec('file ' .. line):stdout():match('directory') then
      table.insert(completions, prefix .. line .. '/')
    else
      table.insert(completions, prefix .. line .. ' ')
    end
  end
  return completions
end

local function complete_on_mud_output(input)
  local partial_word = regex.new("(\\w+)$")
  local partial_word_match = partial_word:match(input)[1]
  local complete_word = regex.new("\\b(" .. partial_word_match .. "\\w+)")
  local input_start = string.sub(input,1, #input - #partial_word_match)
  local completions = {}
  for i = output_history.last, output_history.first, -1 do
    local complete_word_matches = complete_word:match(output_history[i])
    if complete_word_matches then
      for j = #complete_word_matches, 1, -1 do
        table.insert(completions, input_start .. complete_word_matches[j])
      end
    end
  end
  return completions
end

local function complete(input)
  local file_command_re = regex.new('(^/load |^/add_plugin )([^\n]+|)$')
  local file_command_matches = file_command_re:match(input)
  local completions = {}
  if file_command_re:test(input)  then
    local filepath = file_command_matches[3]
    local command = file_command_matches[2]
    completions = complete_filepath(filepath, command)
  else
    completions = complete_on_mud_output(input)
  end
  return completions, true
end

blight.on_complete(complete)
