-- Local benilla/stock Lua 5.0 compatibility adaptation; upstream source pinned in SOURCE.md.
local function AQPrint(text)
 if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then DEFAULT_CHAT_FRAME:AddMessage(tostring(text)) end
end
AutoQuest = {}

local defaults={enabled=true,acceptEnabled=true,turnInEnabled=true,autoReward=false,pawnReward=false}
local initialized=false
function AutoQuest.LoadSettings()
 if type(AutoQuestDB)~="table" then AutoQuestDB={} end
 for key,value in pairs(defaults) do
  if type(AutoQuestDB[key])~="boolean" then AutoQuestDB[key]=value end
  AutoQuest[key]=AutoQuestDB[key]
 end
 initialized=true
 if AutoQuest.RefreshOptions then AutoQuest.RefreshOptions() end
end
function AutoQuest.SetOption(key,value)
 if defaults[key]==nil then return end
 if not initialized then AutoQuest.LoadSettings() end
 AutoQuest[key]=value and true or false;AutoQuestDB[key]=AutoQuest[key]
 if AutoQuest.RefreshOptions then AutoQuest.RefreshOptions() end
end
for key,value in pairs(defaults) do AutoQuest[key]=value end

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

local function Defer(fn,option)
 local title=GetTitleText()
 pendingAction=function()
  if AutoQuest.enabled and (not option or AutoQuest[option]) and not IsShiftKeyDown() and GetTitleText()==title then fn() end
 end
end

frame:SetScript("OnUpdate", function() RunPendingAction(); if AutoQuest.AttachOptionsButton then AutoQuest.AttachOptionsButton() end end)

local function ResetInteraction()
	state = nil
	probeIndex = nil
end

local function AutoAcceptQuest()
	if not AutoQuest.acceptEnabled then return end

	local title = GetTitleText()
	local _, numQuests = GetNumQuestLogEntries()
	if numQuests >= 20 then
		AQPrint("AutoQuest: Quest log is full - \"" .. title .. "\" was not accepted")
		return
	end

	Defer(function()
		if QuestFrame and QuestFrame:IsShown() then
			AcceptQuest()
			AQPrint("AutoQuest: Accepted \"" .. title .. "\"")
		end
	end,"acceptEnabled")
end

local function AutoTurnInQuest()
	if not AutoQuest.turnInEnabled then return end

	if IsQuestCompletable() then
		local title = GetTitleText()
		Defer(function()
			if QuestFrame and QuestFrame:IsShown() then
				CompleteQuest()
				AQPrint("AutoQuest: Turning in \"" .. title .. "\"")
			end
		end,"turnInEnabled")
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
					AQPrint("AutoQuest: Completed \"" .. title .. "\" (choice " .. index .. " by OP score)")
				end
			end,"turnInEnabled")
			return
		end
	end

	if choices <= 1 or AutoQuest.autoReward then
		Defer(function()
			if QuestFrame and QuestFrame:IsShown() then
				GetQuestReward(1)
				AQPrint("AutoQuest: Completed \"" .. title .. "\"")
			end
		end,"turnInEnabled")
	else
		AQPrint("AutoQuest: \"" .. title .. "\" offers " .. choices .. " rewards - please select one")
	end
end

local function OnGossipShow()
	ResetInteraction()

	if AutoQuest.turnInEnabled then
		if table.getn({GetGossipActiveQuests()}) > 0 then
			SelectGossipActiveQuest(1)
			return
		end
	end

	if AutoQuest.acceptEnabled then
		if table.getn({GetGossipAvailableQuests()}) > 0 then
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

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("QUEST_FINISHED")
frame:RegisterEvent("GOSSIP_CLOSED")
frame:RegisterEvent("QUEST_GREETING")
frame:RegisterEvent("QUEST_PROGRESS")
frame:RegisterEvent("QUEST_COMPLETE")
frame:RegisterEvent("QUEST_DETAIL")
frame:RegisterEvent("GOSSIP_SHOW")

frame:SetScript("OnEvent", function()
 if event=="VARIABLES_LOADED" or (event=="ADDON_LOADED" and arg1=="AutoQuest") then AutoQuest.LoadSettings();return end
 if not initialized then AutoQuest.LoadSettings() end
 if event=="QUEST_FINISHED" or event=="GOSSIP_CLOSED" then pendingAction=nil;ResetInteraction();return end
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
	if msg=="" or msg=="options" then AutoQuest.ShowOptions();return
 elseif msg == "toggle" then
		AutoQuest.SetOption("enabled",not AutoQuest.enabled)
		AQPrint("AutoQuest: " .. (AutoQuest.enabled and "Enabled" or "Disabled"))
	elseif msg == "accept" then
		AutoQuest.SetOption("acceptEnabled",not AutoQuest.acceptEnabled)
		AQPrint("AutoQuest: Auto-accept " .. (AutoQuest.acceptEnabled and "enabled" or "disabled"))
	elseif msg == "turnin" then
		AutoQuest.SetOption("turnInEnabled",not AutoQuest.turnInEnabled)
		AQPrint("AutoQuest: Auto-turn-in " .. (AutoQuest.turnInEnabled and "enabled" or "disabled"))
	elseif msg == "reward" then
		AutoQuest.SetOption("autoReward",not AutoQuest.autoReward)
		AQPrint("AutoQuest: Auto-pick first reward " .. (AutoQuest.autoReward and "enabled" or "disabled"))
	elseif msg == "pawn" then
		AutoQuest.SetOption("pawnReward",not AutoQuest.pawnReward)
		if AutoQuest.pawnReward then
			if type(OctoPawnDB) == "table" and type(OctoPawnDB.weights) == "table" then
				AQPrint("AutoQuest: Pick best reward by OctoPawn stat weights enabled")
			else
				AQPrint("AutoQuest: Pick best reward by OctoPawn stat weights enabled (OctoPawn not loaded - will not activate)")
			end
		else
			AQPrint("AutoQuest: Pick best reward by OctoPawn stat weights disabled")
		end
	else
		AQPrint("AutoQuest Commands:")
		AQPrint("/aq toggle - Toggle entire addon on/off")
		AQPrint("/aq accept - Toggle auto-accept quests")
		AQPrint("/aq turnin - Toggle auto-turn-in quests")
		AQPrint("/aq reward - Auto-pick first reward when multiple are offered")
		AQPrint("/aq pawn   - Pick best reward using OctoPawn stat weights (if loaded)")
	end
end

AQPrint("AutoQuest loaded. Use /aq for commands.")