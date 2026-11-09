local A=AutoQuest
function A.RefreshOptions()
 if not A.optionChecks then return end
 for key,check in pairs(A.optionChecks) do check:SetChecked(A[key]) end
end
function A.ShowOptions()
 A.LoadSettings()
 if not A.options then
  local f=CreateFrame("Frame","AutoQuestOptions",UIParent);A.options=f
  f:SetWidth(390);f:SetHeight(350);f:SetPoint("CENTER",UIParent,"CENTER",0,0);f:SetFrameStrata("DIALOG");f:EnableMouse(true)
  f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
  local t=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge");t:SetPoint("TOPLEFT",f,"TOPLEFT",22,-20);t:SetText("自动接交任务  1.2.1")
  local close=CreateFrame("Button","AutoQuestOptionsClose",f,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",f,"TOPRIGHT",-5,-5);close:SetScript("OnClick",function() f:Hide() end)
  A.optionChecks={}
  for i,row in ipairs({{"enabled","总开关"},{"acceptEnabled","自动接任务"},{"turnInEnabled","自动交已完成任务"},{"autoReward","多个奖励时自动选第一个"},{"pawnReward","按OctoPawn评分选奖励（需该插件）"}}) do
   local key=row[1];local check=CreateFrame("CheckButton","AutoQuestOption"..i,f,"UICheckButtonTemplate");check:SetPoint("TOPLEFT",f,"TOPLEFT",20,-50-(i-1)*38)
   local label=f:CreateFontString(nil,"OVERLAY","GameFontHighlight");label:SetPoint("LEFT",check,"RIGHT",5,0);label:SetText(row[2]);check:SetScript("OnClick",function() A.SetOption(key,this:GetChecked()==1) end);A.optionChecks[key]=check
  end
  local note=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");note:SetWidth(340);note:SetPoint("TOPLEFT",f,"TOPLEFT",25,-256);note:SetJustifyH("LEFT");note:SetText("设置会保存。多个奖励默认手动选择；可选第一项或OctoPawn评分。评分需安装OctoPawn，无评分时不自动替选。按住Shift交互可暂时跳过。")
 end
 A.RefreshOptions();A.options:Show()
end
function A.AttachOptionsButton()
 if A.settingsButton or not QuestLogFrame then return end
 local b=CreateFrame("Button","AutoQuestSettingsButton",QuestLogFrame,"UIPanelButtonTemplate");b:SetWidth(105);b:SetHeight(22);b:SetPoint("TOPRIGHT",QuestLogFrame,"TOPRIGHT",-55,-35);b:SetText("自动接交设置");b:SetScript("OnClick",function() A.ShowOptions() end);A.settingsButton=b
end
A.AttachOptionsButton()
