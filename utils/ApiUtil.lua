local ApiUtil = {}

--Script component
function ApiUtil.beginUpdate() Call("BeginUpdate") end

function ApiUtil.endUpdate() Call("EndUpdate") end

---@return number integer of the simulation time in seconds
function ApiUtil.getSimulationTime() return Call("GetSimulationTime") end

---@return number if the controls are in expert mode `1`, otherwise `0`
function ApiUtil.isExpertMode() return Call("IsExpertMode") end


--PosOri



--Rail Vehicle Component


--Render Component


--Sound Component


--Control Container
function ApiUtil.controlExists(name, index) return Call("*:ControlExists", name, index or 0) end

function ApiUtil.getControlValue(name, index) return Call("GetControlValue", name, index or 0) end

function ApiUtil.setControlValue(name, value, index) return Call("SetControlValue", name, index or 0, value) end

function ApiUtil.lockControl(name, index) return Call("LockControl", name, index or 0, true) end

function ApiUtil.unlockControl(name, index) return Call("LockControl", name, index or 0, false) end


--ScenarioManager
function ApiUtil.showMessage(title, message, alert)
    SysCall("ScenarioManager:ShowMessage", title, message, alert or 1)
end

function ApiUtil.showInfoMessageExt(title, message, time, pos, size, pause)
    SysCall("ScenarioManager:ShowInfoMessageExt", title, message, time, pos, size, pause)
end

function ApiUtil.showAlertMessageExt(title, message, time, event)
    SysCall("ScenarioManager:ShowAlertMessageExt", title, message, time, event)
end

return ApiUtil