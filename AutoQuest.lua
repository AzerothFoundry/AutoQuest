AutoQuest = {}

AutoQuest.enabled = true
AutoQuest.acceptEnabled = true
AutoQuest.turnInEnabled = true

local frame = CreateFrame("Frame", "AutoQuestFrame")
frame:RegisterEvent("QUEST_GREETING")
frame:RegisterEvent("QUEST_PROGRESS")
frame:RegisterEvent("QUEST_COMPLETE")
frame:RegisterEvent("QUEST_DETAIL")

local function AutoAcceptQuest()
	if AutoQuest.acceptEnabled and not IsShiftKeyDown() then
		AcceptQuest()
		print("AutoQuest: Quest accepted automatically")
	end
end

local function AutoTurnInQuest()
	if AutoQuest.turnInEnabled and not IsShiftKeyDown() then
		if IsQuestCompletable() then
			CompleteQuest()
			print("AutoQuest: Quest turned in automatically")
		end
	end
end

local function AutoCompleteQuest()
	if not AutoQuest.turnInEnabled or IsShiftKeyDown() then return end
	
	local n = GetNumQuestChoices()
	if n <= 1 then
		GetQuestReward(n > 0 and 1 or 0)
		print("AutoQuest: Quest completed automatically")
	else
		print("AutoQuest: Multiple rewards available, please select one")
	end
end

frame:RegisterEvent("GOSSIP_SHOW")

frame:SetScript("OnEvent", function()
	if not AutoQuest.enabled or IsShiftKeyDown() then return end

	if event == "GOSSIP_SHOW" then
		-- Prioritize turning in active quests
		local active = { GetGossipActiveQuests() }
		for i = 1, table.getn(active), 3 do
			if active[i+2] then -- status is 'complete' (not 100% sure for 1.12, but checking for truthiness)
				SelectGossipActiveQuest((i+2)/3)
				return -- Handle one at a time
			end
		end
		
		-- Then available quests
		local available = { GetGossipAvailableQuests() }
		if table.getn(available) > 0 then
			SelectGossipAvailableQuest(1)
			return
		end

	elseif event == "QUEST_GREETING" then
		-- Prioritize turning in
		local numActive = GetNumActiveQuests()
		for i = 1, numActive do
			SelectActiveQuest(i)
			return
		end
		
		-- Then available
		local numAvailable = GetNumAvailableQuests()
		if numAvailable > 0 then
			SelectAvailableQuest(1)
			return
		end
		
	elseif event == "QUEST_PROGRESS" then
		AutoTurnInQuest()
		
	elseif event == "QUEST_COMPLETE" then
		AutoCompleteQuest()
		
	elseif event == "QUEST_DETAIL" then
		AutoAcceptQuest()
	end
end)

SLASH_AUTOQUEST1 = "/autoquest"
SLASH_AUTOQUEST2 = "/aq"

SlashCmdList["AUTOQUEST"] = function(msg)
	if msg == "toggle" then
		AutoQuest.enabled = not AutoQuest.enabled
		if AutoQuest.enabled then
			print("AutoQuest: Enabled")
		else
			print("AutoQuest: Disabled")
		end
	elseif msg == "accept" then
		AutoQuest.acceptEnabled = not AutoQuest.acceptEnabled
		if AutoQuest.acceptEnabled then
			print("AutoQuest: Auto-accept enabled")
		else
			print("AutoQuest: Auto-accept disabled")
		end
	elseif msg == "turnin" then
		AutoQuest.turnInEnabled = not AutoQuest.turnInEnabled
		if AutoQuest.turnInEnabled then
			print("AutoQuest: Auto-turn-in enabled")
		else
			print("AutoQuest: Auto-turn-in disabled")
		end
	else
		print("AutoQuest Commands:")
		print("/aq toggle - Toggle entire addon on/off")
		print("/aq accept - Toggle auto-accept quests")
		print("/aq turnin - Toggle auto-turn-in quests")
	end
end

print("AutoQuest loaded. Use /aq for commands.")
