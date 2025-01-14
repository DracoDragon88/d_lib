local function SetDisplay(bool, img)
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        type = "showImage",
        image = img,
        status = bool,
    })
end

function dlib.ShowImage(img)
    SetDisplay(true, img)
end

RegisterNUICallback("showItemImage-callback", function(data, cb)
    SetDisplay(false)
    cb('ok')
end)

exports("ShowImage", dlib.ShowImage)

return dlib.ShowImage