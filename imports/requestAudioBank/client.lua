---Loads an audio bank.
---@param audioBank string
---@param timeout number?
---@return string
function dlib.requestAudioBank(audioBank, timeout)
    return dlib.waitFor(function()
        if RequestScriptAudioBank(audioBank, false) then return audioBank end
    end, ("failed to load audiobank '%s'"):format(audioBank), timeout or 500)
end

return dlib.requestAudioBank
