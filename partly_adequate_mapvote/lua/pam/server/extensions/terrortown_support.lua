PAM_EXTENSION.name = "terrortown_support"
PAM_EXTENSION.enabled = true

function PAM_EXTENSION:Initialize()
	-- terrortown support
	if engine.ActiveGamemode() ~= "terrortown" then return false end
end

function PAM_EXTENSION:OnInitialize()
	-- Notify PAM that the round has ended
	hook.Add("TTTEndRound", "PAM_RoundEnded", function()
		PAM.EndRound()
	end)

	local maxRounds = PAM.extension_handler.RunReturningEvent("GetRoundLimit")
	if maxRounds then
		SetGlobalInt("ttt_rounds_left", maxRounds)
	end

	-- ttt2/ttt2
	if TTT2 then
		hook.Add("TTT2LoadNextMap", "PAM_Autostart_TTT2", function(nextmap, rounds_left, time_left)
			PAM.Start()
			return true
		end)
		return
	end

	-- terrortown
	function CheckForMapSwitch()
		local rounds_left = math.max(0, GetGlobalInt("ttt_rounds_left", 6) - 1)

		SetGlobalInt("ttt_rounds_left", rounds_left)

		local time_left = math.max(0, (GetConVar("ttt_time_limit_minutes"):GetInt() * 60) - CurTime())

		if rounds_left <= 0 or time_left <= 0 then
			timer.Stop("end2prep")
			if PAM.state == PAM.STATE_DISABLED then
				PAM.Start()
			end
		end
	end
end

function PAM_EXTENSION:HasRoundLimitExtensionSupport()
	return true
end

function PAM_EXTENSION:RoundLimitExtended(newRound, percentage)
	local roundLimit = PAM.extension_handler.RunReturningEvent("GetRoundLimit") or GetConVar("ttt_round_limit"):GetInt()
	SetGlobalInt("ttt_rounds_left", roundLimit - newRound)

	if (!timer.Exists("end2prep") && GetRoundState() == ROUND_POST) then
		PrepareRound()
	end
end