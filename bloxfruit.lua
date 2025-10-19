--[[ 
 🌐 AUTO SERVER HOP + DISCORD NOTIFY + AUTO RE-RUN
 📜 Made by caywzz (starevxz)
 🔁 Hop jika 3 menit AFK, kirim notifikasi ke Discord, lalu auto-run lagi setelah teleport
]]

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- === CONFIG ===
local AFK_TIME = 180 -- 3 menit
local WEBHOOK_URL = "https://discord.com/api/webhooks/1429045686489452596/lq3EZEmqRwNq_lMkEZcx--sL2fRM9SXsf_hf1eLpaOuCJoSklVpMkAq7xFjHbmGD36bY"
local AVATAR = "https://files.catbox.moe/qeu0yq.jpeg"

-- === WEBHOOK FUNCTION ===
local function sendWebhook(message)
	local requestFunc = (syn and syn.request) or request
	if not requestFunc then
		warn("[Webhook] Executor tidak support HTTP.")
		return
	end
	local payload = {
		username = "Blox Fruits AutoHop - Caywzz",
		avatar_url = AVATAR,
		embeds = {{
			title = "🌐 Auto Hop Notification",
			description = message,
			color = 0x00BFFF,
			footer = { text = "Server ID: " .. game.JobId .. " | " .. os.date("%c") }
		}}
	}
	requestFunc({
		Url = WEBHOOK_URL,
		Method = "POST",
		Headers = {["Content-Type"] = "application/json"},
		Body = HttpService:JSONEncode(payload)
	})
end

-- === ACTIVITY CHECK ===
local lastActivity = tick()
local lastPos = nil

LocalPlayer.Idled:Connect(function()
	lastActivity = tick() - AFK_TIME
end)

task.spawn(function()
	while task.wait(5) do
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			if lastPos and (hrp.Position - lastPos).magnitude > 1 then
				lastActivity = tick()
			end
			lastPos = hrp.Position
		end
	end
end)

-- === MAIN FUNCTION (AUTO-HOP) ===
local function hopServer()
	sendWebhook("⚠️ Player **" .. LocalPlayer.Name .. "** AFK 3 menit!\n🔁 Auto-hop ke server baru...")

	local servers = {}
	local success, response = pcall(function()
		return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100")
	end)

	if success then
		local data = HttpService:JSONDecode(response)
		for _, v in pairs(data.data) do
			if v.playing < v.maxPlayers and v.id ~= game.JobId then
				table.insert(servers, v.id)
			end
		end
	end

	if #servers > 0 then
		local target = servers[math.random(1, #servers)]
		sendWebhook("🚀 Pindah ke server baru dengan ID: `" .. target .. "`")
		task.wait(2)
		TeleportService:TeleportToPlaceInstance(game.PlaceId, target, LocalPlayer)
	else
		sendWebhook("⚠️ Tidak ada server kosong ditemukan. Akan coba lagi nanti.")
	end
end

-- === AUTO RE-RUN ===
game:GetService("Players").LocalPlayer.OnTeleport:Connect(function(state)
	if state == Enum.TeleportState.Started then
		-- Auto re-run script di server baru
		queue_on_teleport([[
			loadstring(game:HttpGet("https://pastebin.com/raw/XXXXXXXX"))()
		]])
	end
end)

-- === LOOP CEK AFK ===
task.spawn(function()
	while task.wait(10) do
		if tick() - lastActivity >= AFK_TIME then
			hopServer()
			task.wait(5)
		end
	end
end)

print("[✅] Auto Hop aktif — akan pindah server jika AFK 3 menit.")
