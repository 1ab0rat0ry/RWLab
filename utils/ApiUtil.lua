---Provides implementation of the game API functions in Lua.
---@class ApiUtil
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
---Get the position in the current world frame of the object (local coordinates are local to a moving origin centred on the camera's current tile).
---@return number, number, number The position x, y, z in metres relative to the origin.
function ApiUtil.getNearPosition() return Call("getNearPosition") end


--Rail vehicle
---Is the rail vehicle controlled by the player.
---@return number If the train is player controlled `1`, if the train is AI controlled `0`.
function ApiUtil.getIsPlayer() return Call("GetIsPlayer") end

---Get the rail vehicle's current speed.
---@return number The speed in metres per second.
function ApiUtil.getSpeed() return Call("GetSpeed") end

---Get the rail vehicle's acceleration.
---@return number The acceleration in metres per second squared.
function ApiUtil.getAcceleration() return Call("GetAcceleration") end

---Get the total mass of the rail vehicle including cargo.
---@return number The mass in kilograms.
function ApiUtil.getTotalMass() return Call("GetTotalMass") end

---Get the total mass of the entire consist including cargo.
---@return number The mass in kilograms.
function ApiUtil.getConsistTotalMass() return Call("GetConsistTotalMass") end

---Get the consist length.
---@return number The length in metres.
function ApiUtil.getConsistLength() return Call("GetConsistLength") end

---Get the gradient at the front of the consist.
---@return number The gradient as a percentage.
function ApiUtil.getGradient() return Call("GetGradient") end

---Get the curvature (radius of curve) at the front of the consist.
---@return number The radius of the curve in metres.
function ApiUtil.getCurvature() return Call("GetCurvature") end

---Get the curvature relative to the front of the vehicle.
---@param displacement number If positive, gets curvature this number of metres ahead of the front of the vehicle. If negative, gets curvature this number of metres behind the rear of the vehicle.
---@return number The radius of the curve in metres `positive` if curving to the right, `negative` if curving to the left, relative to the way the vehicle is facing.
function ApiUtil.getCurvatureAhead(displacement) return Call("GetCurvatureAhead", displacement) end

---Get the rail vehicle's number.
---@return number The rail vehicle number.
function ApiUtil.getRvNumber() return Call("GetRVNumber") end

---Set the rail vehicle's number (used for changing destination boards).
---@param number number The new number for the vehicle.
function ApiUtil.setRvNumber(number) Call("SetRVNumber", number) end

---Send a message to the next or previous rail vehicle in the consist.
---Calls the script function `OnConsistMessage(message, argument, direction)` in the next or previous rail vehicle.
---@param message number The ID of a message to send (IDs `0` to `100` are reserved, please use IDs greater than `100`).
---@param argument string
---@param direction number Use `0` to send a message to the vehicle in front, `1` to send a message to the vehicle behind.
---@return number If there was a next/previous rail vehicle `1`.
function ApiUtil.sendConsistMessage(message, argument, direction)
    return Call("SendConsistMessage", message, argument, direction)
end

---Get the next restrictive signal's distance and state.
---@param direction number Optional. `0` = forwards, `1` = backwards. Defaults to `0`.
---@param minDistance number Optional. How far ahead in metres to start searching. Defaults to `0`.
---@param maxDistance number Optional. How far ahead in metres to stop searching. Defaults to `10 000`.
---@return number, number, number, number Param 1: `1` = nothing found, `0` = end of track, `>0` = signal found; Param 2: Basic signal state: `-1` = invalid, `1` = warning, `2` = red; Param 3: Distance in metres to signal; Param4: 2D map's "pro" signal state for more detailed aspect information. `-1` = invalid, `1` = yellow, `2` = double-yellow, `3` = red, `10` = flashing-yellow, `11` = flashing-double-yellow.
function ApiUtil.getNextRestrictiveSignal(direction, minDistance, maxDistance)
    return Call("GetNextRestrictiveSignal", direction, minDistance, maxDistance)
end

---Set a failure value on the train brake system for this vehicle.
---@param name string The name of the failure type. Either one of `BRAKE_FADE` (the proportion of brake power lost due to fade in the braking as a result of excess heat) or `BRAKE_LOCK` (the proportion of max force the brake is stuck at due to locking on the wheel).
---@param value number The value of the failure dependent on failure type.
function ApiUtil.setBrakeFailureValue(name, value)
    Call("SetBrakeFailureValue", name, value)
end

---Get the type, limit and distance to the next speed limit.
---@param direction number Optional. `0` = forwards, `1` = backwards. Defaults to `0`.
---@param minDistance number Optional. How far ahead in metres to start searching. Defaults to `0`.
---@param maxDistance number Optional. How far ahead in metres to stop searching. Defaults to `10 000`.
---@return number, number, number Param 1: `-1` = nothing found, `0` = end of track, `1` = track speed limit (no signage), `2` = track speed limit sign, `3` = track speed limit; Param 2: Restriction in metres per second; Param 3: Distance in metres to speed limit.
function ApiUtil.getNextSpeedLimit(direction, minDistance, maxDistance)
    return Call("GetNextSpeedLimit", direction, minDistance, maxDistance)
end

---Get the current speed limit for the consist.
---@param component number Optional. `0` = return current limit, `1` = return separate track and signal limit. Defaults to `0`.
---@return number, number If `component` is set to `0`, then a single value is returned. Otherwise, two values are returned for track and signal limits respectively.
function ApiUtil.getCurrentSpeedLimit(component)
    return Call("GetCurrentSpeedLimit", component)
end

---Get the class of the consist.
---@return number eTrainTypeSpecial = `0`, eTrainTypeLightEngine = `1`, eTrainTypeExpressPassenger = `2`, eTrainTypeStoppingPassenger = `3`, eTrainTypeHighSpeedFreight = `4`, eTrainTypeExpressFreight = `5`, eTrainTypeStandardFreight = `6`, eTrainTypeLowSpeedFreight = `7`, eTrainTypeOtherFreight = `8`, eTrainTypeEmptyStock = `9`, eTrainTypeInternational = `10`
function ApiUtil.getConsistType()
    return Call("GetConsistType")
end

---Evaluates if camera is near this vehicle ( < 4 km).
---@return boolean
function ApiUtil.getIsNearCamera()
    return Call("GetIsNearCamera")
end

---Evaluates if the vehicle is in a tunnel.
---@return boolean
function ApiUtil.getIsInTunnel()
    return Call("GetIsInTunnel")
end


--Render


--Sound


--Control values
---Evaluates whether a control with a specific name exists.
---@param name string
---@param index number Optional, defaults to `0`. The index of the control (usually `0` unless there are multiple controls with the same name).
---@return boolean If the control exists `true` otherwise `false`.
function ApiUtil.controlExists(name, index) return Call("ControlExists", name, index or 0) end

---Get the value for a control.
---@param name string
---@param index number Optional, defaults to `0`. The index of the control (usually `0` unless there are multiple controls with the same name).
---@return number The value for the control.
function ApiUtil.getControlValue(name, index) return Call("GetControlValue", name, index or 0) end

---Sets a value for a control.
---@param name string
---@param index number Optional, defaults to `0`. The index of the control (usually `0` unless there are multiple controls with the same name).
function ApiUtil.setControlValue(name, value, index) Call("SetControlValue", name, index or 0, value) end

---Locks a control so the user can no longer affect it.
---@param name string
---@param index number Optional, defaults to `0`. The index of the control (usually `0` unless there are multiple controls with the same name).
function ApiUtil.lockControl(name, index) return Call("LockControl", name, index or 0, true) end

---Unlocks a control so the user can affect it.
---@param name string
---@param index number Optional, defaults to `0`. The index of the control (usually `0` unless there are multiple controls with the same name).
function ApiUtil.unlockControl(name, index) return Call("LockControl", name, index or 0, false) end


--Engine


--Emitter


--Light


--Scenario
---Shows a dialogue box with a message.
---If `title` or `message` are in UUID format, then they are used as keys into the language table.
---@param title string
---@param message string
---@param alert number Optional, defaults to `ALERT`. The type of message box `INFO(0)` or `ALERT(1)`.
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