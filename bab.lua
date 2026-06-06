-- ==========================================
-- SOL'S RNG TRACKER V8.9 (MERCHANT FALSE-POSITIVE FIX)
-- ==========================================
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

if getgenv().SolsTrackerLoop then task.cancel(getgenv().SolsTrackerLoop) end
if getgenv().BiomeConnections then
    for _, conn in ipairs(getgenv().BiomeConnections) do conn:Disconnect() end
end
getgenv().BiomeConnections = {}

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

local function sendDiscordEmbed(eventType, name, isEnd)
    local webhookUrl = getgenv().Webhook
    if not webhookUrl or webhookUrl == "" then return false end

    local playerName = player.Name
    local jobId = game.JobId ~= "" and game.JobId or "Private/Studio"
    local psLink = getgenv().PSLink or ""
    local serverDisplay = (psLink ~= "") and ("[Private Server Link](" .. psLink .. ")") or ("`" .. jobId .. "`")
    
    local serverId = "Unknown"
    if psLink ~= "" then
        serverId = string.sub(string.gsub(psLink, "%D", ""), 1, 10)
        if serverId == "" then serverId = "Unknown" end
    else
        local digits = string.gsub(jobId, "%D", "")
        serverId = string.sub(digits, 1, 10)
        if serverId == "" then serverId = string.sub(jobId, 1, 10) end
    end

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
        elseif name == "Jester" then icon = "🃏"; colorHex = 0xF1C40F; pingContent = getgenv().PingJester or "" end
        
        titleText = icon .. " " .. name .. " Has Arrived!"
        descriptionText = "**Owner:** `" .. playerName .. "`\n**Detected by:** `" .. playerName .. "`\n**Detected At:** " .. timeFormat .. "\n**Private Server:** " .. serverDisplay

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

        descriptionText = "**Owner:** `" .. playerName .. "`\n**Detected by:** `" .. playerName .. "`\n**Time:** " .. timeFormat .. "\n**Private Server:** " .. serverDisplay
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
    
    content = string.match(content, "^%s*(.-)%s*$") or ""

    for _, biome in ipairs(BIOME_KEYWORDS) do
        if content == biome then 
            return biome 
        end
    end
    
    if not isStrict then
        for _, biome in ipairs(BIOME_KEYWORDS) do
            if string.find(content, biome) then
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
    
    if oldBiome ~= "" and oldBiome ~= "NORMAL" and oldBiome ~= "NULL" then 
        sendDiscordEmbed("Biome", oldBiome, true) 
    end
    
    if currentBiome ~= "NORMAL" and currentBiome ~= "NULL" then
        sendDiscordEmbed("Biome", currentBiome, false)
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

print("[Sol's Tracker] Đang khởi động hệ thống V8.9 (Public Server Merchant Safe)...")

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

        -- BỘ QUÉT MERCHANT SIÊU BẢO MẬT (LỌC NGƯỜI CHƠI)
        local foundMerchants = {}
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("Model") then
                -- ĐIỀU KIỆN 1: Bỏ qua toàn bộ người chơi trong server
                if not Players:GetPlayerFromCharacter(v) then
                    
                    -- ĐIỀU KIỆN 2: Bắt buộc phải có ProximityPrompt (Nút bấm E của NPC)
                    local prompt = v:FindFirstChildWhichIsA("ProximityPrompt", true)
                    
                    if prompt then
                        local textToCheck = (prompt.ObjectText or "") .. " " .. (prompt.ActionText or "")
                        for _, name in ipairs(MERCHANT_NAMES) do
                            
                            -- ĐIỀU KIỆN 3: Thuật toán %f[%a] bắt từ khóa ĐỘC LẬP (Bắt "Mari", đá "Marine")
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
