AutoQuest = {}

AutoQuest.enabled = true
AutoQuest.acceptEnabled = true
AutoQuest.turnInEnabled = true
AutoQuest.autoReward = false
AutoQuest.pawnReward = false

local frame = CreateFrame("Frame", "AutoQuestFrame")

local state
local probeIndex

local pendingAction
local function RunPendingAction()
	if pendingAction then
		local fn = pendingAction
		pendingAction = nil
		fn()
	end
end

local function Defer(fn)
	pendingAction = fn
end

frame:SetScript("OnUpdate", RunPendingAction)

local function ResetInteraction()
	state = nil
	probeIndex = nil
end

local function AutoAcceptQuest()
	if not AutoQuest.acceptEnabled then return end

	local title = GetTitleText()
	local _, numQuests = GetNumQuestLogEntries()
	if numQuests >= 20 then
		print("AutoQuest: Quest log is full - \"" .. title .. "\" was not accepted")
		return
	end

	Defer(function()
		if QuestFrame and QuestFrame:IsShown() then
			AcceptQuest()
			print("AutoQuest: Accepted \"" .. title .. "\"")
		end
	end)
end

local function AutoTurnInQuest()
	if not AutoQuest.turnInEnabled then return end

	if IsQuestCompletable() then
		local title = GetTitleText()
		Defer(function()
			if QuestFrame and QuestFrame:IsShown() then
				CompleteQuest()
				print("AutoQuest: Turning in \"" .. title .. "\"")
			end
		end)
	elseif state == "probing" then
		probeIndex = probeIndex + 1
		if QuestFrameGoodbyeButton and QuestFrameGoodbyeButton:IsShown() then
			QuestFrameGoodbyeButton:Click()
		end
	end
end

local function OctoPawnScoreRewardChoice(index)
	if type(OctoPawnDB) ~= "table" or type(OctoPawnDB.weights) ~= "table" then return nil end
	if not OctoPawn_ScoreTooltip or not OctoPawn_GetScanTooltip then return nil end
	local hasWeights = false
	for _ in pairs(OctoPawnDB.weights) do
		hasWeights = true
		break
	end
	if not hasWeights then return nil end

	local tip = OctoPawn_GetScanTooltip()
	if not tip then return nil end
	tip:SetOwner(UIParent, "ANCHOR_NONE")
	tip:ClearLines()
	tip:SetQuestItem("choice", index)
	tip:Show()
	local score = OctoPawn_ScoreTooltip(tip)
	tip:Hide()
	return score or 0
end

local function AutoCompleteQuest()
	if not AutoQuest.turnInEnabled then return end

	local title = GetTitleText()
	local choices = GetNumQuestChoices()

	if choices > 1 and AutoQuest.pawnReward then
		local bestIndex, scored = 1, false
		local bestScore = -math.huge
		local i
		for i = 1, choices do
			local s = OctoPawnScoreRewardChoice(i)
			if s then
				scored = true
				if s > bestScore then
					bestScore, bestIndex = s, i
				end
			end
		end
		if scored then
			local index = bestIndex
			Defer(function()
				if QuestFrame and QuestFrame:IsShown() then
					GetQuestReward(index)
					print("AutoQuest: Completed \"" .. title .. "\" (choice " .. index .. " by OP score)")
				end
			end)
			return
		end
	end

	if choices <= 1 or AutoQuest.autoReward then
		Defer(function()
			if QuestFrame and QuestFrame:IsShown() then
				GetQuestReward(1)
				print("AutoQuest: Completed \"" .. title .. "\"")
			end
		end)
	else
		print("AutoQuest: \"" .. title .. "\" offers " .. choices .. " rewards - please select one")
	end
end

local function OnGossipShow()
	ResetInteraction()

	if AutoQuest.turnInEnabled then
		if select("#", GetGossipActiveQuests()) > 0 then
			SelectGossipActiveQuest(1)
			return
		end
	end

	if AutoQuest.acceptEnabled then
		if select("#", GetGossipAvailableQuests()) > 0 then
			SelectGossipAvailableQuest(1)
			return
		end
	end
end

local function OnQuestGreeting()
	local numActive = GetNumActiveQuests()
	local numAvailable = GetNumAvailableQuests()

	if state == "probing" then
		if not AutoQuest.turnInEnabled or (probeIndex and probeIndex > numActive) then
			ResetInteraction()
			if AutoQuest.acceptEnabled and numAvailable > 0 then
				state = "available"
				SelectAvailableQuest(1)
			end
		elseif probeIndex then
			SelectActiveQuest(probeIndex)
		end
		return
	end

	if state == "available" then
		if AutoQuest.acceptEnabled and numAvailable > 0 then
			SelectAvailableQuest(1)
		else
			ResetInteraction()
		end
		return
	end

	if AutoQuest.turnInEnabled and numActive > 0 then
		state = "probing"
		probeIndex = 1
		SelectActiveQuest(1)
		return
	end

	if AutoQuest.acceptEnabled and numAvailable > 0 then
		state = "available"
		SelectAvailableQuest(1)
	end
end

frame:RegisterEvent("QUEST_GREETING")
frame:RegisterEvent("QUEST_PROGRESS")
frame:RegisterEvent("QUEST_COMPLETE")
frame:RegisterEvent("QUEST_DETAIL")
frame:RegisterEvent("GOSSIP_SHOW")

frame:SetScript("OnEvent", function()
	if not AutoQuest.enabled or IsShiftKeyDown() then return end

	if event == "GOSSIP_SHOW" then
		OnGossipShow()
	elseif event == "QUEST_GREETING" then
		OnQuestGreeting()
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
	msg = string.lower(msg or "")
	if msg == "toggle" then
		AutoQuest.enabled = not AutoQuest.enabled
		print("AutoQuest: " .. (AutoQuest.enabled and "Enabled" or "Disabled"))
	elseif msg == "accept" then
		AutoQuest.acceptEnabled = not AutoQuest.acceptEnabled
		print("AutoQuest: Auto-accept " .. (AutoQuest.acceptEnabled and "enabled" or "disabled"))
	elseif msg == "turnin" then
		AutoQuest.turnInEnabled = not AutoQuest.turnInEnabled
		print("AutoQuest: Auto-turn-in " .. (AutoQuest.turnInEnabled and "enabled" or "disabled"))
	elseif msg == "reward" then
		AutoQuest.autoReward = not AutoQuest.autoReward
		print("AutoQuest: Auto-pick first reward " .. (AutoQuest.autoReward and "enabled" or "disabled"))
	elseif msg == "pawn" then
		AutoQuest.pawnReward = not AutoQuest.pawnReward
		if AutoQuest.pawnReward then
			if type(OctoPawnDB) == "table" and type(OctoPawnDB.weights) == "table" then
				print("AutoQuest: Pick best reward by OctoPawn stat weights enabled")
			else
				print("AutoQuest: Pick best reward by OctoPawn stat weights enabled (OctoPawn not loaded - will not activate)")
			end
		else
			print("AutoQuest: Pick best reward by OctoPawn stat weights disabled")
		end
	else
		print("AutoQuest Commands:")
		print("/aq toggle - Toggle entire addon on/off")
		print("/aq accept - Toggle auto-accept quests")
		print("/aq turnin - Toggle auto-turn-in quests")
		print("/aq reward - Auto-pick first reward when multiple are offered")
		print("/aq pawn   - Pick best reward using OctoPawn stat weights (if loaded)")
	end
end

print("AutoQuest loaded. Use /aq for commands.")