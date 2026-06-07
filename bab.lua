-- ==========================================
-- SOL'S RNG TRACKER V10.3 (FIXED & REVERTED)
-- ==========================================
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

if getgenv().SolsTrackerLoop then task.cancel(getgenv().SolsTrackerLoop) end
if getgenv().BiomeConnections then
    for _, conn in ipairs(getgenv().BiomeConnections) do conn:Disconnect() end
end
getgenv().BiomeConnections = {}

-- STEALTH ANTI-AFK (VIM)
local antiAfkConn = player.Idled:Connect(function()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F24, false, game)
    task.wait(0.1)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F24, false, game)
end)
table.insert(getgenv().BiomeConnections, antiAfkConn)

-- CLEAN UP OLD UI
local oldGui = CoreGui:FindFirstChild("SolsTrackerNotification") or player:WaitForChild("PlayerGui"):FindFirstChild("SolsTrackerNotification")
if oldGui then oldGui:Destroy() end

local BIOME_KEYWORDS = {"NORMAL", "NULL", "WINDY", "RAINY", "SNOWY", "SANDSTORM", "HELL", "STARFALL", "CORRUPTION", "DREAMSPACE", "CYBERSPACE", "SINGULARITY", "HEAVEN"}
local MERCHANT_NAMES = {"Mari", "Rin", "Jester"}

local currentBiome = "" 
local activeMerchants = {}

local BIOME_VISUALS = {
    ["NORMAL"] = {Color = 0xA8D3A3, Image = ""},
    ["NULL"] = {Color = 0x838383, Image = "https://images-ext-1.discordapp.net/external/oTkVOEht5ZuvDIhpG8mgxnTKee9JAYq_Yd-4LSXPT6I/https/static.wikia.nocookie.net/sol-rng/images/f/fc/NULLLL.png?format=webp&quality=lossless&width=1872&height=842"},
    ["WINDY"] = {Color = 0x88C9F9, Image = "https://images-ext-1.discordapp.net/external/WEAlyXm_APt92sRubdYHMmTP52jAOla-kPWmkwEpH10/https/i.postimg.cc/6qPH4wy6/image.png?format=webp&quality=lossless"},
    ["RAINY"] = {Color = 0x2596BE, Image = "https://images-ext-1.discordapp.net/external/X9QljSlTuTTLr2_lEpOTFQsoIfmGZA115RvliUbHmn0/https/static.wikia.nocookie.net/sol-rng/images/e/ec/Rainy.png?format=webp&quality=lossless"},
    ["SNOWY"] = {Color = 0xDCEFF9, Image = "https://images-ext-1.discordapp.net/external/-o6c9pxCh-K5SeEK9uD8gn23NCNWiM3vNNsbgn6R7xk/https/static.wikia.nocookie.net/sol-rng/images/d/d7/Snowy_img.png?format=webp&quality=lossless"},
    ["SANDSTORM"] = {Color = 0x8F7057, Image = "https://images-ext-1.discordapp.net/external/YTaZjJxr0EBmyOrrUBS5wzVmM6QTvqKbe840RZbwDM4/https/i.postimg.cc/3JyL25Kz/image.png?format=webp&quality=lossless"},
    ["HELL"] = {Color = 0xF64419, Image = "https://images-ext-1.discordapp.net/external/qKU_vjWUkYcSeetnZOS309VpG1QtQkrtdYNdZYnIVYw/https/i.postimg.cc/hGC5xNyY/image.png?format=webp&quality=lossless"},
    ["STARFALL"] = {Color = 0x0119B7, Image = "https://images-ext-1.discordapp.net/external/O8bkaQy5NX1zWplzfk6ws-hRtBR7pOcOgxxlqKmmUkA/https/i.postimg.cc/1t0dY4J8/image.png?format=webp&quality=lossless"},
    ["CORRUPTION"] = {Color = 0x6D32A8, Image = "https://images-ext-1.discordapp.net/external/mJ_Zmf9mcBfvIdtdEjxkcDrGtYNECZ5hreL2GODQAJc/https/i.postimg.cc/ncZQ84Dh/image.png?format=webp&quality=lossless"},
    ["DREAMSPACE"] = {Color = 0xEA9DDB, Image = "https://images-ext-1.discordapp.net/external/KNr7Wgy0JCoNKi6Qsb0c6846rztwwhZCi7wmrCb9SoE/https/i.postimg.cc/rFjCcW3w/image.png?format=webp&quality=lossless"},
    ["CYBERSPACE"] = {Color = 0x0119B7, Image = "https://images-ext-1.discordapp.net/external/RuhdClHLMhSgZUXhR6ib3FmwIwXQ8RR2ClscG061wZU/https/at-cdn-s01.audiotool.com/2013/06/13/documents/zW2OHriFzthb06Ty5h9tUxEGgEw/0/cover256x256-f161eb9cd16c4786bbb3c78292e7131f.jpg?format=webp"},
    ["SINGULARITY"] = {Color = 0x0119B3, Image = "https://images-ext-1.discordapp.net/external/xJYbC3JAqtET_zeAqF8FFdRnSEAHerGlV2XflFT2W8s/https/images.stockcake.com/public/1/5/a/15a57388-244b-4e36-ade9-871b031bb041_medium/cosmic-anime-vortex-stockcake.jpg?format=webp"},
    ["HEAVEN"] = {Color = 0xFFDF5E, Image = "https://images-ext-1.discordapp.net/external/iuq2Tu5Gfm70tPYAT9FMOqkHeM1bvMMUJW2L0IG9OaQ/%3Fsize%3D240%26quality%3Dlossless/https/media.discordapp.net/stickers/1447481739240018010.webp?format=webp"},
    ["GLITCHED"] = {Color = 0xBFFF00, Image = "https://images-ext-1.discordapp.net/external/y4yKovwiS0dYo0PYSCREZVNUr6uKJbQUEeTmKhPv8Hc/https/i.postimg.cc/W3Lhtn5g/image.png?format=webp&quality=lossless"}
}

-- IN-GAME NOTIFICATION UI (SAFE V9.9 REVERT WITH BETTER PADDING)
local SolsTrackerGUI = Instance.new("ScreenGui")
SolsTrackerGUI.Name = "SolsTrackerNotification"
SolsTrackerGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local success = pcall(function() SolsTrackerGUI.Parent = CoreGui end)
if not success then SolsTrackerGUI.Parent = player:WaitForChild("PlayerGui") end

local posHidden = UDim2.new(0, -350, 0, 55)
local posVisible = UDim2.new(0, 15, 0, 55)  

local NotifFrame = Instance.new("Frame")
NotifFrame.Name = "NotifFrame"
NotifFrame.Parent = SolsTrackerGUI
NotifFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
NotifFrame.BackgroundTransparency = 0.05
NotifFrame.Position = posHidden 
NotifFrame.Size = UDim2.new(0, 250, 0, 65) 
NotifFrame.BorderSizePixel = 0
NotifFrame.Visible = false

local UIStroke = Instance.new("UIStroke")
UIStroke.Parent = NotifFrame
UIStroke.Color = Color3.fromRGB(60, 60, 75)
UIStroke.Thickness = 1.2
UIStroke.LineJoinMode = Enum.LineJoinMode.Miter 

local AccentLine = Instance.new("Frame")
AccentLine.Name = "AccentLine"
AccentLine.Size = UDim2.new(0, 4, 1, 0)
AccentLine.Position = UDim2.new(0, 0, 0, 0)
AccentLine.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
AccentLine.BorderSizePixel = 0
AccentLine.Parent = NotifFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent = NotifFrame
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 22, 0, 12) 
TitleLabel.Size = UDim2.new(1, -30, 0, 14)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "SYSTEM UPDATE"
TitleLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
TitleLabel.TextSize = 11
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Parent = NotifFrame
InfoLabel.BackgroundTransparency = 1
InfoLabel.Position = UDim2.new(0, 22, 0, 32) 
InfoLabel.Size = UDim2.new(1, -30, 0, 18)
InfoLabel.Font = Enum.Font.GothamSemibold
InfoLabel.Text = "Awaiting data..."
InfoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
InfoLabel.TextSize = 15
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left

local hideTask = nil

local function checkWebhookValid()
    local wh = getgenv().Webhook or ""
    if string.find(wh, "discord.com/api/webhooks") or string.find(wh, "discordapp.com/api/webhooks") then
        return true
    end
    return false
end

local tweenInfoSlideIn = TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local tweenInfoSlideOut = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

local function showNotification(biomeText)
    local isWhValid = checkWebhookValid()
    
    if biomeText then
        TitleLabel.Text = "BIOME DETECTED"
        InfoLabel.Text = biomeText
        
        if BIOME_VISUALS[biomeText] then
            AccentLine.BackgroundColor3 = Color3.fromRGB(
                math.floor(BIOME_VISUALS[biomeText].Color / 65536),
                math.floor((BIOME_VISUALS[biomeText].Color % 65536) / 256),
                BIOME_VISUALS[biomeText].Color % 256
            )
        else
            AccentLine.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        end
    else
        TitleLabel.Text = "WEBHOOK STATUS"
        if isWhValid then
            InfoLabel.Text = "Active & Connected"
            AccentLine.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        else
            InfoLabel.Text = "Invalid / Empty Link"
            AccentLine.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
        end
    end
    
    NotifFrame.Visible = true
    
    local slideIn = TweenService:Create(NotifFrame, tweenInfoSlideIn, {Position = posVisible})
    slideIn:Play()
    
    if hideTask then task.cancel(hideTask) end
    
    hideTask = task.delay(4.5, function()
        local slideOut = TweenService:Create(NotifFrame, tweenInfoSlideOut, {Position = posHidden})
        slideOut:Play()
        slideOut.Completed:Wait()
        NotifFrame.Visible = false
    end)
end

-- DISCORD WEBHOOK HANDLER
local function sendDiscordEmbed(eventType, name, isEnd)
    local webhookUrl = getgenv().Webhook
    if not webhookUrl or webhookUrl == "" then return false end

    local playerName = player.Name
    local jobId = game.JobId ~= "" and game.JobId or "Private/Studio"
    local psLink = getgenv().PSLink or ""
    
    local serverId = ""
    if game.VIPServerOwnerId and game.VIPServerOwnerId ~= 0 then
        serverId = tostring(game.VIPServerOwnerId) 
    else
        serverId = tostring(player.UserId) 
    end

    local defaultServerDisplay = (psLink ~= "") and ("[Private Server Link](" .. psLink .. ")") or ("`" .. jobId .. "`")
    local unixTime = os.time()
    local timeFormat = "<t:" .. unixTime .. ":D> • <t:" .. unixTime .. ":T> ( <t:" .. unixTime .. ":R> )"

    local titleText, descriptionText = "", ""
    local colorHex = 0
    local pingContent = ""
    local thumbnailUrl = nil

    if eventType == "Merchant" then
        local icon = "🛒"
        if name == "Mari" then icon = "🛍️"; colorHex = 0xE91E63; pingContent = getgenv().PingMari or ""
        elseif name == "Rin" then icon = "🦊"; colorHex = 0xE67E22; pingContent = getgenv().PingRin or ""
        elseif name == "Jester" then icon = "🃏"; colorHex = 0x9B59B6; pingContent = getgenv().PingJester or "" end
        
        titleText = icon .. " " .. name .. " Has Arrived!"
        descriptionText = "**Owner:** `" .. playerName .. "`\n**Detected by:** `" .. playerName .. "`\n**Detected At:** " .. timeFormat .. "\n**Private Server:** " .. defaultServerDisplay

    elseif eventType == "Biome" then
        local state = isEnd and "Ended" or "Started"
        titleText = "🌍 " .. name .. " Biome " .. state
        
        if BIOME_VISUALS[name] then
            colorHex = BIOME_VISUALS[name].Color
            thumbnailUrl = (BIOME_VISUALS[name].Image ~= "") and BIOME_VISUALS[name].Image or nil
        else
            colorHex = 0x3498DB
        end
        
        if name == "GLITCHED" then
            titleText = "👾 🙽 GLITCHED BIOME " .. state .. " 🙽"
        end

        local finalServerDisplay = defaultServerDisplay
        if isEnd then
            finalServerDisplay = "`" .. serverId .. "`"
        end

        descriptionText = "**Owner:** `" .. playerName .. "`\n**Detected by:** `" .. playerName .. "`\n**Time:** " .. timeFormat .. "\n**Private Server:** " .. finalServerDisplay
    end

    local embed = {
        ["title"] = titleText,
        ["description"] = descriptionText,
        ["color"] = colorHex,
        ["footer"] = { ["text"] = "J.JARAM JX 2x60 • " .. serverId },
        ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ") 
    }

    if thumbnailUrl then
        embed["thumbnail"] = { ["url"] = thumbnailUrl }
    end

    local payload = {
        ["content"] = (pingContent ~= "") and pingContent or nil,
        ["embeds"] = {embed}
    }
    
    local jsonData = HttpService:JSONEncode(payload)
    local httprequest = (syn and syn.request) or (http and http.request) or http_request or fluxus.request or request
    
    if httprequest then 
        pcall(function() httprequest({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = jsonData}) end)
    end
end

-- BIOME DETECTOR & PARSER
local function parseBiome(rawText, isStrict)
    if not rawText or rawText == "" then return nil end
    
    local cleanText = string.upper(rawText)
    local compactText = string.gsub(cleanText, "%s+", "") 
    
    if string.find(cleanText, "GLITCHED") 
       or string.find(compactText, "ERRORWHILERETRIEVINGTIMEDATA") 
       or string.find(cleanText, "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x") then
        return "GLITCHED"
    end
    
    local content = cleanText
    local inBrackets = string.match(cleanText, "%[%s*(.-)%s*%]")
    if inBrackets then content = inBrackets end
    
    local contentNoSpace = string.gsub(content, "%s+", "")

    for _, biome in ipairs(BIOME_KEYWORDS) do
        local biomeNoSpace = string.gsub(biome, "%s+", "")
        if contentNoSpace == biomeNoSpace then 
            return biome 
        end
    end
    
    if not isStrict then
        for _, biome in ipairs(BIOME_KEYWORDS) do
            local biomeNoSpace = string.gsub(biome, "%s+", "")
            if string.find(contentNoSpace, biomeNoSpace) then
                return biome
            end
        end
    end
    
    return nil
end

local function triggerBiomeChange(newBiome)
    if not newBiome or newBiome == currentBiome then return end
    
    local oldBiome = currentBiome
    currentBiome = newBiome
    
    showNotification(currentBiome)
    
    -- ALLOW ALL BIOMES (INCLUDING NULL AND NORMAL) TO SEND WEBHOOK
    if oldBiome ~= "" then 
        sendDiscordEmbed("Biome", oldBiome, true) 
    end
    
    sendDiscordEmbed("Biome", currentBiome, false)
end

local function scanUIForBiome()
    if player and player:FindFirstChild("PlayerGui") then
        local mainInterface = player.PlayerGui:FindFirstChild("MainInterface")
        if mainInterface then
            for _, v in ipairs(mainInterface:GetDescendants()) do
                if v:IsA("TextLabel") and v.Visible then
                    local txt = v.Text
                    if txt and #txt > 0 and #txt < 75 then
                        if string.find(txt, "%[") and string.find(txt, "%]") then
                            local detected = parseBiome(txt, true)
                            if detected then return detected end
                        end
                        if string.gsub(string.upper(txt), "%s+", "") == "ERRORWHILERETRIEVINGTIMEDATA" then
                            return "GLITCHED"
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function performBiomeCheck()
    local wsBiomeValue = nil
    local workspaceBiome = Workspace:FindFirstChild("Biome")
    
    if workspaceBiome and workspaceBiome:IsA("StringValue") then
        wsBiomeValue = parseBiome(workspaceBiome.Value, false)
    end

    local uiBiomeValue = scanUIForBiome()

    local finalBiome = nil
    if uiBiomeValue == "GLITCHED" then
        finalBiome = "GLITCHED"
    elseif wsBiomeValue then
        finalBiome = wsBiomeValue
    elseif uiBiomeValue then
        finalBiome = uiBiomeValue
    end

    if finalBiome then
        triggerBiomeChange(finalBiome)
    end
end

-- INITIALIZATION
showNotification(nil) 

local wsBiome = Workspace:FindFirstChild("Biome")
if wsBiome and wsBiome:IsA("StringValue") then
    local conn1 = wsBiome:GetPropertyChangedSignal("Value"):Connect(function()
        performBiomeCheck()
    end)
    table.insert(getgenv().BiomeConnections, conn1)
end

getgenv().SolsTrackerLoop = task.spawn(function()
    while true do
        performBiomeCheck()

        local foundMerchants = {}
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("Model") then
                if not Players:GetPlayerFromCharacter(v) then
                    local prompt = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                    
                    if prompt then
                        local textToCheck = (prompt.ObjectText or "") .. " " .. (prompt.ActionText or "")
                        for _, name in ipairs(MERCHANT_NAMES) do
                            local matchName = string.find(v.Name, "%f[%a]" .. name .. "%f[%A]")
                            local matchPrompt = string.find(textToCheck, "%f[%a]" .. name .. "%f[%A]")
                            
                            if matchName or matchPrompt then 
                                foundMerchants[name] = true 
                            end
                        end
                    end
                end
            end
        end
        
        for merchantName, _ in pairs(foundMerchants) do
            if not activeMerchants[merchantName] then
                activeMerchants[merchantName] = true
                sendDiscordEmbed("Merchant", merchantName, false)
            end
        end
        
        for merchantName, _ in pairs(activeMerchants) do
            if not foundMerchants[merchantName] then
                activeMerchants[merchantName] = nil
            end
        end

        task.wait(2.5)
    end
end)
