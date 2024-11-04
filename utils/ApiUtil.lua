local ApiUtil = {}

--Script

---Request script to get update call once per frame.
function ApiUtil.beginUpdate() Call("BeginUpdate") end

---	Request script to end update call once per frame.
function ApiUtil.endUpdate() Call("EndUpdate") end

---@return number Integer of the simulation time in seconds.
function ApiUtil.getSimulationTime() return Call("GetSimulationTime") end

---@return number If the controls are in expert mode `1` otherwise `0`.
function ApiUtil.isExpertMode() return Call("IsExpertMode") end


--Position


--Rail vehicle


--Render


--Sound


--Control values


---Evaluates whether a control with a specific name exists.
---@param name string
---@param index number
---@return boolean If the control exists `true` otherwise `false`.
function ApiUtil.controlExists(name, index) return Call("ControlExists", name, index or 0) end

---Get the value for a control.
---@param name string
---@param index number
---@return number The value for the control.
function ApiUtil.getControlValue(name, index) return Call("GetControlValue", name, index or 0) end

---Sets a value for a control.
---@param name string
---@param index number
function ApiUtil.setControlValue(name, value, index) Call("SetControlValue", name, index or 0, value) end

---Locks a control so the user can no longer affect it.
---@param name string
---@param index number
function ApiUtil.lockControl(name, index) return Call("LockControl", name, index or 0, true) end

---Unlocks a control so the user can affect it.
---@param name string
---@param index number
function ApiUtil.unlockControl(name, index) return Call("LockControl", name, index or 0, false) end


--Engine


--Emitter


--Light


--Scenario


---Shows a dialogue box with a message.
---If `title` or `message` are in UUID format, then they are used as keys into the language table.
---@param title string
---@param message string
---@param alert number Optional, the type of message box `INFO(0)` or `ALERT(1)`. Defaults to `ALERT` when not specified.
function ApiUtil.showMessage(title, message, alert)
    SysCall("ScenarioManager:ShowMessage", title, message, alert or 1)
end

---Shows an info dialogue box with a message and extended attributes.
---If `title` or `message` are in UUID format, then they are used as keys into the language table.
---@param title string
---@param message string
---@param time number The time to show the message, set to `0` for indefinite.
---@param pos number The position of the message box: `MSG_TOP(1)`, `MSG_VCENTRE(2)`, `MSG_BOTTOM(4)`, `MSG_LEFT(8)`, `MSG_CENTRE(16)`, `MSG_RIGHT(32)`.
---@param size number The size of the message box: `MSG_SMALL(0)`, `MSG_REG(1)`, `MSG_LRG(2)`.
---@param pause boolean If `true` pause the game while the message is shown.
function ApiUtil.showInfoMessageExt(title, message, time, pos, size, pause)
    SysCall("ScenarioManager:ShowInfoMessageExt", title, message, time, pos, size, pause)
end

---Shows an alert dialogue box with a message and extended attributes.
---If `title` or `message` are in UUID format, then they are used as keys into the language table.
---@param title string
---@param message string
---@param time number The time to show the message, set to `0` for indefinite.
---@param event string Event name triggered on click of message.
function ApiUtil.showAlertMessageExt(title, message, time, event)
    SysCall("ScenarioManager:ShowAlertMessageExt", title, message, time, event)
end


--Weather


--Camera


--Signals

return ApiUtil