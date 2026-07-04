-- ==========================================
-- SOL'S RNG TRACKER V10.17 (THE LIMBO DEEP SCAN BYPASS)
-- ==========================================
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

-- HỆ THỐNG UPTIME CHO MULTISCOPE
getgenv().ScriptStartTime = getgenv().ScriptStartTime or os.time()
local function getUptime()
    local diff = os.time() - getgenv().ScriptStartTime
    local h = math.floor(diff / 3600)
    local m = math.floor((diff % 3600) / 60)
    local s = diff % 60
    if h > 0 then return string.format("%dhr %dm %ds", h, m, s)
    elseif m > 0 then return string.format("%dm %ds", m, s)
    else return string.format("%ds", s) end
end

if getgenv().SolsTrackerLoop then task.cancel(getgenv().SolsTrackerLoop) end
if getgenv().AntiAfkLoop then task.cancel(getgenv().AntiAfkLoop) end
if getgenv().BiomeConnections then
    for _, conn in ipairs(getgenv().BiomeConnections) do conn:Disconnect() end
end
getgenv().BiomeConnections = {}

-- ==========================================
-- ACTIVE STEALTH ANTI-AFK (RIGHT-CLICK)
-- ==========================================
getgenv().AntiAfkLoop = task.spawn(function()
    while true do
        task.wait(60) 
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(0, 50, 1, true, game, 0)
            task.wait(0.1)
            VirtualInputManager:SendMouseButtonEvent(0, 50, 1, false, game, 0)
        end)
    end
end)

local antiAfkConn = player.Idled:Connect(function()
    VirtualInputManager:SendMouseButtonEvent(0, 50, 1, true, game, 0)
    task.wait(0.1)
    VirtualInputManager:SendMouseButtonEvent(0, 50, 1, false, game, 0)
end)
table.insert(getgenv().BiomeConnections, antiAfkConn)

-- ==========================================
-- DANH SÁCH ẢNH: J.JARAM (Image) & MULTISCOPE (MacroIcon)
-- ==========================================
local BIOME_KEYWORDS = {"NORMAL", "NULL", "WINDY", "RAINY", "SNOWY", "SANDSTORM", "HELL", "STARFALL", "CORRUPTION", "DREAMSPACE", "CYBERSPACE", "SINGULARITY", "HEAVEN"}
local MERCHANT_NAMES = {"Mari", "Rin", "Jester"}

local currentBiome = "" 
local activeMerchants = {}

local MERCHANT_VISUALS = {
    ["Mari"] = {Color = 0xFF66A3, Icon = "https://cresqnt.com/api/images/MARI.png"},
    ["Rin"] = {Color = 0xE67E22, Icon = "https://github.com/Thecodeisrereall/MacScopeAPI/blob/main/NPCS/RIN.png?raw=true"},
    ["Jester"] = {Color = 0x9B59B6, Icon = "https://cresqnt.com/api/images/JESTER.png"}
}

local BIOME_VISUALS = {
    ["NORMAL"] = {Color = 0xA8D3A3, Image = "", MacroIcon = "https://images-ext-1.discordapp.net/external/emSugvuHrXET3e0cye62aV2Z5wEgTIXR4oOnwDlFs5c/https/cresqnt.com/api/images/NORMAL.png?format=webp&quality=lossless"},
    ["NULL"] = {Color = 0x838383, Image = "https://images-ext-1.discordapp.net/external/oTkVOEht5ZuvDIhpG8mgxnTKee9JAYq_Yd-4LSXPT6I/https/static.wikia.nocookie.net/sol-rng/images/f/fc/NULLLL.png?format=webp&quality=lossless&width=1872&height=842", MacroIcon = "https://cresqnt.com/api/images/NULL.png"},
    ["WINDY"] = {Color = 0x88C9F9, Image = "https://images-ext-1.discordapp.net/external/WEAlyXm_APt92sRubdYHMmTP52jAOla-kPWmkwEpH10/https/i.postimg.cc/6qPH4wy6/image.png?format=webp&quality=lossless", MacroIcon = "https://cresqnt.com/api/images/WINDY.png"},
    ["RAINY"] = {Color = 0x2596BE, Image = "https://images-ext-1.discordapp.net/external/X9QljSlTuTTLr2_lEpOTFQsoIfmGZA115RvliUbHmn0/https/static.wikia.nocookie.net/sol-rng/images/e/ec/Rainy.png?format=webp&quality=lossless", MacroIcon = "https://cresqnt.com/api/images/RAINY.png"},
    ["SNOWY"] = {Color = 0xDCEFF9, Image = "https://images-ext-1.discordapp.net/external/-o6c9pxCh-K5SeEK9uD8gn23NCNWiM3vNNsbgn6R7xk/https/static.wikia.nocookie.net/sol-rng/images/d/d7/Snowy_img.png?format=webp&quality=lossless", MacroIcon = "https://images-ext-1.discordapp.net/external/itAKykZtumfEeKSheP7RCifp-4NRkoD4f4d_Kzya1EI/https/cresqnt.com/api/images/SNOWY.png?format=webp&quality=lossless"},
    ["SANDSTORM"] = {Color = 0x8F7057, Image = "https://images-ext-1.discordapp.net/external/YTaZjJxr0EBmyOrrUBS5wzVmM6QTvqKbe840RZbwDM4/https/i.postimg.cc/3JyL25Kz/image.png?format=webp&quality=lossless", MacroIcon = "https://images-ext-1.discordapp.net/external/XcWpCiDsdDk9vNYkqSy9u2oLaSuU5CFq0guPvqeVuZY/https/cresqnt.com/api/images/SAND_STORM.png?format=webp&quality=lossless"},
    ["HELL"] = {Color = 0xF64419, Image = "https://images-ext-1.discordapp.net/external/qKU_vjWUkYcSeetnZOS309VpG1QtQkrtdYNdZYnIVYw/https/i.postimg.cc/hGC5xNyY/image.png?format=webp&quality=lossless", MacroIcon = "https://cresqnt.com/api/images/HELL.png"},
    ["STARFALL"] = {Color = 0x0119B7, Image = "https://images-ext-1.discordapp.net/external/O8bkaQy5NX1zWplzfk6ws-hRtBR7pOcOgxxlqKmmUkA/https/i.postimg.cc/1t0dY4J8/image.png?format=webp&quality=lossless", MacroIcon = "https://cresqnt.com/api/images/STARFALL.png"},
    ["CORRUPTION"] = {Color = 0x6D32A8, Image = "https://images-ext-1.discordapp.net/external/mJ_Zmf9mcBfvIdtdEjxkcDrGtYNECZ5hreL2GODQAJc/https/i.postimg.cc/ncZQ84Dh/image.png?format=webp&quality=lossless", MacroIcon = "https://cresqnt.com/api/images/CORRUPTION.png"},
    ["DREAMSPACE"] = {Color = 0xEA9DDB, Image = "https://images-ext-1.discordapp.net/external/KNr7Wgy0JCoNKi6Qsb0c6846rztwwhZCi7wmrCb9SoE/https/i.postimg.cc/rFjCcW3w/image.png?format=webp&quality=lossless", MacroIcon = "https://cresqnt.com/api/images/DREAMSPACE.png"},
    ["CYBERSPACE"] = {Color = 0x0119B7, Image = "https://images-ext-1.discordapp.net/external/RuhdClHLMhSgZUXhR6ib3FmwIwXQ8RR2ClscG061wZU/https/at-cdn-s01.audiotool.com/2013/06/13/documents/zW2OHriFzthb06Ty5h9tUxEGgEw/0/cover256x256-f161eb9cd16c4786bbb3c78292e7131f.jpg?format=webp", MacroIcon = "https://maxstellar.github.io/biome_thumb/CYBERSPACE.png"},
    ["SINGULARITY"] = {Color = 0x0119B3, Image = "https://images-ext-1.discordapp.net/external/xJYbC3JAqtET_zeAqF8FFdRnSEAHerGlV2XflFT2W8s/https/images.stockcake.com/public/1/5/a/15a57388-244b-4e36-ade9-871b031bb041_medium/cosmic-anime-vortex-stockcake.jpg?format=webp", MacroIcon = "https://sleepytil.github.io/biome_thumb/SINGULARITY.png"},
    ["HEAVEN"] = {Color = 0xFFDF5E, Image = "https://images-ext-1.discordapp.net/external/iuq2Tu5Gfm70tPYAT9FMOqkHeM1bvMMUJW2L0IG9OaQ/%3Fsize%3D240%26quality%3Dlossless/https/media.discordapp.net/stickers/1447481739240018010.webp?format=webp", MacroIcon = "https://images-ext-1.discordapp.net/external/6StQXg3XKRnazQ1IYfZWdgYrMldnLf1FQSSVUUl_gug/https/maxstellar.github.io/biome_thumb/HEAVEN.png?format=webp&quality=lossless"},
    ["GLITCHED"] = {Color = 0xBFFF00, Image = "https://images-ext-1.discordapp.net/external/y4yKovwiS0dYo0PYSCREZVNUr6uKJbQUEeTmKhPv8Hc/https/i.postimg.cc/W3Lhtn5g/image.png?format=webp&quality=lossless", MacroIcon = "https://maxstellar.github.io/biome_thumb/GLITCHED.png"}
}

-- ==========================================
-- IN-GAME NOTIFICATION UI
-- ==========================================
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
    if string.find(wh, "discord.com/api/webhooks") or string.find(wh, "discordapp.com/api/webhooks") then return true end
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

-- ==========================================
-- DISCORD WEBHOOK HANDLER
-- ==========================================
local function sendDiscordEmbed(eventType, name, isEnd)
    local webhookUrl = getgenv().Webhook
    if not webhookUrl or webhookUrl == "" then return false end

    local style = getgenv().MacroStyle or "J.JARAM"
    local playerName = player.Name
    local jobId = game.JobId ~= "" and game.JobId or "Private/Studio"
    local psLink = getgenv().PSLink or ""
    
    local serverId = ""
    if game.VIPServerOwnerId and game.VIPServerOwnerId ~= 0 then serverId = tostring(game.VIPServerOwnerId) 
    else serverId = tostring(player.UserId) end

    local unixTime = os.time()
    local colorHex = 0
    local pingContent = ""
    local embed = {}
    local components = nil

    -- 1. STYLE: MULTISCOPE
    if style == "MultiScope" then
        local macroIconUrl = "https://static.wikia.nocookie.net/sol-rng/images/8/87/Icon.png"
        local desc = "**Account:** " .. playerName .. "\n**Uptime:** " .. getUptime()
        
        if eventType == "Merchant" then
            if MERCHANT_VISUALS[name] then
                colorHex = MERCHANT_VISUALS[name].Color
                macroIconUrl = MERCHANT_VISUALS[name].Icon
            end
            if name == "Mari" then pingContent = getgenv().PingMari or ""
            elseif name == "Rin" then pingContent = getgenv().PingRin or ""
            elseif name == "Jester" then pingContent = getgenv().PingJester or "" end
            
            embed.title = "Merchant Detected - " .. name
            embed.description = desc .. "\n**Spawned:** <t:" .. unixTime .. ":R>"
            embed.thumbnail = { ["url"] = macroIconUrl }
            
        elseif eventType == "Biome" then
            if BIOME_VISUALS[name] then 
                colorHex = BIOME_VISUALS[name].Color 
                macroIconUrl = (BIOME_VISUALS[name].MacroIcon ~= "") and BIOME_VISUALS[name].MacroIcon or macroIconUrl
            end
            if not isEnd and (name == "GLITCHED" or name == "DREAMSPACE" or name == "CYBERSPACE") then pingContent = "@everyone" end
            
            local stateText = isEnd and "Ended" or "Started"
            embed.title = "Biome " .. stateText .. " - " .. name
            
            if isEnd then
                embed.description = desc .. "\n[Support](https://discord.gg/solrng)"
            else
                embed.description = desc .. "\n**Started:** <t:" .. unixTime .. ":R>"
            end
            embed.thumbnail = { ["url"] = macroIconUrl }
        end
        
        embed.color = colorHex
        embed.footer = { ["text"] = "MultiScope v2.0.5 • " .. os.date("!%m/%d/%Y %I:%M %p") }
        
        -- NÚT BẤM JOIN SERVER (Components)
        if psLink ~= "" and (eventType == "Merchant" or not isEnd) then
            components = {
                {
                    ["type"] = 1,
                    ["components"] = {
                        {
                            ["type"] = 2,
                            ["style"] = 5,
                            ["label"] = "Join Server",
                            ["url"] = psLink
                        }
                    }
                }
            }
        end

    -- 2. STYLE: J.JARAM (MẶC ĐỊNH)
    else
        local timeFormat = "<t:" .. unixTime .. ":D> • <t:" .. unixTime .. ":T> ( <t:" .. unixTime .. ":R> )"
        local defaultServerDisplay = (psLink ~= "") and ("[Private Server Link](" .. psLink .. ")") or ("`" .. jobId .. "`")
        local titleText, descriptionText = "", ""
        local thumbnailUrl = nil
        
        if eventType == "Merchant" then
            local icon = "🛒"
            if name == "Mari" then icon = "🛍️"; colorHex = 0xFF66A3; pingContent = getgenv().PingMari or ""
            elseif name == "Rin" then icon = "🦊"; colorHex = 0xE67E22; pingContent = getgenv().PingRin or ""
            elseif name == "Jester" then icon = "🃏"; colorHex = 0x9B59B6; pingContent = getgenv().PingJester or "" end
            
            titleText = icon .. " " .. name .. " Has Arrived!"
            descriptionText = "**Owner:** `" .. playerName .. "`\n**Detected by:** `" .. playerName .. "`\n**Detected At:** " .. timeFormat .. "\n**Private Server:** " .. defaultServerDisplay
        else
            local state = isEnd and "Ended" or "Started"
            titleText = "🌍 " .. name .. " Biome " .. state
            
            if not isEnd and (name == "GLITCHED" or name == "DREAMSPACE" or name == "CYBERSPACE") then pingContent = "@everyone" end
            
            if BIOME_VISUALS[name] then
                colorHex = BIOME_VISUALS[name].Color
                thumbnailUrl = (BIOME_VISUALS[name].Image ~= "") and BIOME_VISUALS[name].Image or nil
            else
                colorHex = 0x3498DB
            end

            if name == "GLITCHED" then titleText = "🌍 GLITCHED Biome " .. state end

            local finalServerDisplay = defaultServerDisplay
            if isEnd then finalServerDisplay = "`" .. serverId .. "`" end

            descriptionText = "**Owner:** `" .. playerName .. "`\n**Detected by:** `" .. playerName .. "`\n**Time:** " .. timeFormat .. "\n**Private Server:** " .. finalServerDisplay
        end

        embed.title = titleText
        embed.description = descriptionText
        embed.color = colorHex
        embed.footer = { ["text"] = "J.JARAM JX 2x60 • " .. serverId }
        embed.timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        if thumbnailUrl then embed.thumbnail = { ["url"] = thumbnailUrl } end
    end

    local payload = {
        ["content"] = (pingContent ~= "") and pingContent or nil,
        ["embeds"] = {embed},
        ["components"] = components 
    }
    
    local jsonData = HttpService:JSONEncode(payload)
    local httprequest = (syn and syn.request) or (http and http.request) or http_request or fluxus.request or request
    
    if httprequest then 
        pcall(function() httprequest({Url = webhookUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = jsonData}) end)
    end
end

-- ==========================================
-- STRICT BIOME DETECTOR & PARSER (BACKEND SCAN)
-- ==========================================
local function parseBiome(rawText, isStrict)
    if not rawText or rawText == "" then return nil end
    local cleanText = string.upper(rawText)
    local compactText = string.gsub(cleanText, "%s+", "") 
    if string.find(cleanText, "GLITCHED") or string.find(compactText, "ERRORWHILERETRIEVINGTIMEDATA") or string.find(cleanText, "%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x") then
        return "GLITCHED"
    end
    local content = cleanText
    local inBrackets = string.match(cleanText, "%[%s*(.-)%s*%]")
    if inBrackets then content = inBrackets end
    local contentNoSpace = string.gsub(content, "%s+", "")

    for _, biome in ipairs(BIOME_KEYWORDS) do
        local biomeNoSpace = string.gsub(biome, "%s+", "")
        if contentNoSpace == biomeNoSpace then return biome end
    end
    if not isStrict then
        for _, biome in ipairs(BIOME_KEYWORDS) do
            local biomeNoSpace = string.gsub(biome, "%s+", "")
            if string.find(contentNoSpace, biomeNoSpace) then return biome end
        end
    end
    return nil
end

local function triggerBiomeChange(newBiome)
    if not newBiome or newBiome == currentBiome then return end
    local oldBiome = currentBiome
    currentBiome = newBiome
    
    showNotification(currentBiome)
    
    local style = getgenv().MacroStyle or "J.JARAM"
    local hideNormal = (style == "J.JARAM")
    
    if oldBiome ~= "" then 
        if not hideNormal or oldBiome ~= "NORMAL" then sendDiscordEmbed("Biome", oldBiome, true) end
    end
    if currentBiome ~= "" then
        if not hideNormal or currentBiome ~= "NORMAL" then sendDiscordEmbed("Biome", currentBiome, false) end
    end
end

local function scanUIForBiome()
    if player and player:FindFirstChild("PlayerGui") then
        local mainInterface = player.PlayerGui:FindFirstChild("MainInterface")
        if mainInterface then
            for _, v in ipairs(mainInterface:GetDescendants()) do
                if v:IsA("TextLabel") and v.Visible then
                    local txt = v.Text
                    if txt and #txt > 0 and #txt < 75 then
                        if string.gsub(string.upper(txt), "%s+", "") == "ERRORWHILERETRIEVINGTIMEDATA" then return "GLITCHED" end
                        if string.find(txt, "%[") and string.find(txt, "%]") then
                            local detected = parseBiome(txt, true)
                            if detected then return detected end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function performBiomeCheck()
    -- CƠ CHẾ DEEP SCAN: XUYÊN QUA THE LIMBO BẰNG CÁCH ĐỌC DỮ LIỆU GỐC TỪ SERVER
    local backendBiomeValue = nil
    
    -- 1. Ưu tiên chọc vào Workspace (Môi trường máy chủ thực tế)
    local workspaceBiome = Workspace:FindFirstChild("Biome")
    if workspaceBiome and workspaceBiome:IsA("StringValue") then
        backendBiomeValue = parseBiome(workspaceBiome.Value, true)
    end
    
    -- 2. Quét dự phòng ở ReplicatedStorage (Đề phòng Workspace bị ghi đè)
    if not backendBiomeValue then
        local rsBiome = ReplicatedStorage:FindFirstChild("Biome")
        if rsBiome and rsBiome:IsA("StringValue") then
            backendBiomeValue = parseBiome(rsBiome.Value, true)
        end
    end

    -- 3. Frontend Scan (Giao diện UI thông thường)
    local uiBiomeValue = scanUIForBiome()
    
    -- TỔNG HỢP (Luôn ưu tiên Backend nếu bị kẹt ở The Limbo)
    local finalBiome = nil
    if uiBiomeValue == "GLITCHED" then finalBiome = "GLITCHED"
    elseif backendBiomeValue then finalBiome = backendBiomeValue
    elseif uiBiomeValue then finalBiome = uiBiomeValue end

    if finalBiome then triggerBiomeChange(finalBiome) end
end

-- ==========================================
-- INITIALIZATION
-- ==========================================
showNotification(nil) 

-- Lắng nghe sự thay đổi biến Biome ở CẢ Workspace LẪN ReplicatedStorage
local wsBiome = Workspace:FindFirstChild("Biome")
if wsBiome and wsBiome:IsA("StringValue") then
    local conn1 = wsBiome:GetPropertyChangedSignal("Value"):Connect(function() performBiomeCheck() end)
    table.insert(getgenv().BiomeConnections, conn1)
end

local rsBiome = ReplicatedStorage:FindFirstChild("Biome")
if rsBiome and rsBiome:IsA("StringValue") then
    local conn2 = rsBiome:GetPropertyChangedSignal("Value"):Connect(function() performBiomeCheck() end)
    table.insert(getgenv().BiomeConnections, conn2)
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
                            if matchName or matchPrompt then foundMerchants[name] = true end
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
            if not foundMerchants[merchantName] then activeMerchants[merchantName] = nil end
        end
        task.wait(2.5)
    end
end)
