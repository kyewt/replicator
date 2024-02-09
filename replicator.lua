local isPosInt = _G.qtype.isPosInt

local replicator = _G.qclass.extend("replicator")

replicator:setStaticField("_placeholder", {}, true)

replicator:setField("_mainSet", nil, true)
replicator:setField("_tempSets", nil, true)
replicator:setField("_hole", nil)
replicator:setField("_tempHoles", nil)
replicator:setField("_defaultSetSize", 2000000)

replicator:setMethod("makeTempSet", function(inst, size)
    if size ~= nil then
        if isPosInt(size) then error("bad type to size, expected positive integer") end
    else
        size = inst._defaultSetSize
    end
    local tempSets = inst._tempSets
    local placeholder = inst._placeholder
    local newSetIndex = nil
    for index, set in ipairs(tempSets) do
        if set == placeholder then
            newSetIndex = index
        end
    end
    if not newSetIndex then
        newSetIndex = #tempSets + 1
    end
    tempSets[newSetIndex] = table.create(size, inst._placeholder)
    inst._tempHoles[newSetIndex] = 1
    return newSetIndex
end)
replicator:setMethod("deleteTempSet", function(inst, setIndex)
    local tempSets = inst._tempSets
    local set = tempSets[setIndex]
    if not set then error("tempSet with index of "..tostring(setIndex).." doesn't exist") end
    tempSets[setIndex] = inst._placeholder
    inst._tempHoles[setIndex] = inst._placeholder
end)
replicator:setMethod("clearTempSet", function(inst, setIndex)
    local set = inst._tempSets[setIndex]
    if not set then error("tempSet with index of "..tostring(setIndex).." doesn't exist") end
    local placeholder = inst._placeholder
    for i = 1, #set do
        set[i] = placeholder
    end
    inst._tempHoles[setIndex] = 1
end)

replicator:setMethod("getItem", function(inst, id, tempSetIndex)
    local item = inst._mainSet[id]
    if not item and tempSetIndex then
        item = inst._tempSets[tempSetIndex][id]
    end
    if item ~= inst._placeholder then
        return item
    end
    return nil
end)
replicator:setMethod("getId", function(inst, item, tempSetId)
    for id, registeredItem in ipairs(inst._mainSet) do
        if item == registeredItem then
            return id
        end
    end
    if not tempSetId then
        return
    end
    local tempSet = inst._tempSets[tempSetId]
    if tempSet == nil or tempSet == inst._placeholder then
        error("tempSet with an index of "..tostring(tempSetId).." doesn't exist")
    end
    for id, registeredItem in ipairs(tempSet) do
        if item == registeredItem then
            return id
        end
    end
    return nil
end)

replicator:setMethod("registerItem", function(inst, item)
    local hole = inst._hole
    if hole == inst._placeholder then error("registered items table full") end
    inst._mainSet[hole] = item
    inst._prepareHole()
    return hole
end)
replicator:setMethod("tempRegisterItem", function(inst, tempSetIndex, item, tempId)
    if tempId then
        inst._tempSets[tempSetIndex][tempId] = item
        inst._prepareTempHole(tempSetIndex)
        return tempId
    end
    local hole = inst._tempHoles[tempSetIndex]
    if hole == inst._placeholder then error ("tempRegistered items table full") end
    inst._tempSets[tempSetIndex][hole] = item
    inst._prepareTempHole(tempSetIndex)
    return hole
end)
replicator:setMethod("tempDeregisterItem", function(inst, tempSetIndex, tempId)
    local tempSet = inst._tempSets[tempSetIndex]
    if not tempSet then
        error("tempSet with an index of "..tostring(tempSetIndex).." doesn't exist")
    end
    local tempItem = tempSet[tempId]
    local placeholder = inst._placeholder
    if tempItem == placeholder then
        error("tempItem in set "..tostring(tempSetIndex).." with index of "..tostring(tempId).." doesn't exist")
    end
    tempSet[tempId] = inst._placeholder
end)

replicator:setMethod("_getHole", function(inst, tab)
    local placeholder = inst._placeholder
    for index, value in ipairs(tab) do
        if value == placeholder then
            return index
        end
    end
    return placeholder
end)
replicator:setMethod("_prepareHole", function(inst)
    inst._hole = inst._getHole(inst._mainSet)
end)
replicator:setMethod("_prepareTempHole", function(inst, tempSetIndex)
    inst._tempHoles[tempSetIndex] = inst._getHole(inst._tempSets[tempSetIndex])
end)

replicator:setConstructor(function(inst, size)
    if size ~= nil then
        if isPosInt(size) then error("bad type to size, expected positive integer") end
    else
        size = inst._defaultSetSize
    end
    local placeholder = inst._placeholder
    inst._mainSet = table.create(size, placeholder)
    inst._hole = 1
    inst._tempSets = {}
    inst._tempHoles = {}
end)

replicator:finalize()
return replicator