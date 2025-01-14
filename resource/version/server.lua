local function convertVersion(v)
    local vt = {}
    for w in string.gmatch(v, '([^.]+)') do
        table.insert(vt, tonumber(w))
    end
    return vt
end

local function addZeros(n)
    if n < 10 then return "00"..n
    elseif n < 100 then return "0"..n
    else return tostring(n)
    end
end

local function compareVersions(__cv, __v)
    local _cv, _v = convertVersion(__cv), convertVersion(__v)

    local curVersion, version = "", ""

    for i, cv in ipairs(_cv) do
        local vv = _v[i] or 0

        if i == 1 then
            curVersion = tostring(cv)
            version = tostring(vv)
        else
            curVersion = curVersion .. addZeros(cv)
            version = version .. addZeros(vv)
        end
    end

    return tonumber(curVersion) < tonumber(version)
end

function dlib.versionCheck(repository)
	local resource = GetInvokingResource() or GetCurrentResourceName()
	local currentVersion = GetResourceMetadata(resource, 'version', 0)

	if currentVersion then
		currentVersion = currentVersion:match('%d+%.%d+%.%d+')
	end

	if not currentVersion then return print(("^1Unable to determine current resource version for '%s' ^0"):format(resource)) end

	SetTimeout(1000, function()
		PerformHttpRequest(('https://api.github.com/repos/%s/releases/latest'):format(repository), function(status, response)
			if status ~= 200 then return end

			response = json.decode(response)
			if response.prerelease then return end

			local latestVersion = response.tag_name:match('%d+%.%d+%.%d+')
			if not latestVersion or latestVersion == currentVersion then return end

            local cv = { string.strsplit('.', currentVersion) }
            local lv = { string.strsplit('.', latestVersion) }

            for i = 1, #cv do
                local current, minimum = tonumber(cv[i]), tonumber(lv[i])

                if current ~= minimum then
                    if current < minimum then
                        return print(('^3An update is available for %s (current version: %s)\r\n%s^0'):format(resource, currentVersion, response.html_url))
                    else break end
                end
            end
		end, 'GET')
	end)
end

function dlib.DVersionCheck(resource, dname)
    SetTimeout(1000, function()
        PerformHttpRequest(('https://raw.githubusercontent.com/DracoDragon88/d-versions/main/%s.txt'):format(dname), function(err, version, headers)
            local curVersion = GetResourceMetadata(resource, 'version')
            if not version then print(('Could not complete version request for %s.'):format(dname)) return end
            if utf8.codepoint(version:sub(#version, #version)) == 10 then version = version:sub(1, #version - 1) end -- controls for data link escape character at the end of string from github, removes it if found

            if compareVersions(curVersion, version) then
                print(("^3An update is available for %s ^3(%s => %s)^0"):format(dname, curVersion, version))
            else
                print(("^2You are using the latest version of %s!^0"):format(resource))
            end
        end)
    end)
end

function dlib.CheckLibVersion(__v, resource, dname, resCheck)
    local theRes = resCheck or GetCurrentResourceName()
	local __cv = GetResourceMetadata(theRes, 'version', 0) or "1.0.0"

    if compareVersions(__cv, __v) then
        print(([[^2=^1-^2-^3-^4-^5-^6-^7-^8-^9-^1-^2-^3-^4-^5-^6-^7-^8-^2=
^3You need to update ^5%s^3 to Version: ^5%s^3, before you are able to use ^5%s
^3Current Version: ^5%s^3, Needed Version: ^5%s
^2=^1-^2-^3-^4-^5-^6-^7-^8-^9-^1-^2-^3-^4-^5-^6-^7-^8-^2=^7]]):format(theRes, __v, resource, __cv, __v))

        SetTimeout(1000, function() StopResource(resource) end)
    elseif type(dname) == "string" then
        dlib.DVersionCheck(resource, dname)
    end
end

CreateThread(function ()
    dlib.DVersionCheck(GetCurrentResourceName(), 'd-lib')
end)
