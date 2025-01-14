---@async
---@generic T : string | number
---@param request function
---@param hasLoaded function
---@param assetType string
---@param asset T
---@param timeout? number
---@param ... any
---Used internally.
function dlib.streamingRequest(request, hasLoaded, assetType, asset, timeout, ...)
    if hasLoaded(asset) then return asset end

    request(asset, ...)

    dlib.print.verbose(("Loading %s '%s' - remember to release it when done."):format(assetType, asset))

    return dlib.waitFor(function()
        if hasLoaded(asset) then return asset end
    end, ("failed to load %s '%s' - this is likely caused by unreleased assets"):format(assetType, asset), timeout or 10000)
end

return dlib.streamingRequest
