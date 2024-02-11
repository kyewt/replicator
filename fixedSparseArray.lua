local isPosInt = _G.qtype.isPosInt
local floor, min = math.floor, math.min
local create, insert, remove = table.create, table.insert, table.remove

local fixedSparseArray = _G.qclass.extend("fixedSparseArray")

fixedSparseArray:setStaticField("_placeholder", {}, true)

fixedSparseArray:setField("_table", nil, true)
fixedSparseArray:setField("_holes", nil, true)
fixedSparseArray:setField("_peakIndex", 0)

fixedSparseArray:setField("size", nil, true)

fixedSparseArray:setProperty(
    "space",
    function(inst)
        return inst.size - inst._peakIndex + #inst._holes
    end,
    function(inst)
        error("cannot set ".._G.qtype.get(inst)..".space")
    end
)

fixedSparseArray:setMethod("set", function(inst, index, value)
    if index < 1 or index > inst.size or index ~= floor(index) then
        error("bad index expected positive integer within array range")
    end
    local placeholder = inst._placeholder
    if value == nil then
        value = placeholder
    end
    local tab = inst._table
    if tab[index] ~= placeholder then
        insert(inst._holes, index)
    end
    tab[index] = value
end)

fixedSparseArray:setMethod("remove", function(inst, index)
    if not isPosInt(index) or index < 1 or index > inst.space then
        error("bad index expected positive integer within array range")
    end
    local tab = inst._table
    local placeholder = inst._placeholder
    local removed = false
    if tab[index] ~= placeholder then
        insert(inst._holes, index)
        removed = true
    end
    tab[index] = placeholder
    return removed
end)

fixedSparseArray:setMethod("removeMul", function(inst, indices)
    if type(indices) ~= "table" then
        error("bad type to indices expected table")
    end
    local indexCount = #indices
    local space = inst.space
    if indexCount > space then
        error("indices is larger than "..tostring(inst))
    end
    for _, removalIndex in ipairs(indices) do
        if not isPosInt(removalIndex) or removalIndex < 1 or removalIndex > space then
            error("bad index expected positive integer within array range")
        end
    end
    local tab = inst._table
    local placeholder = inst._placeholder
    local removed = {}
    for _, removalIndex in ipairs(indices) do
        if tab[removalIndex] ~= placeholder then
            insert(removed, removalIndex)
        end
        tab[removalIndex] = placeholder
    end
    return removed
end)

fixedSparseArray:setMethod("insert", function(inst, value)
    if inst.space < 0 then
        error(tostring(inst).." out of space")
    end
    if value == nil then
        error("bad type to value expected a non-nil type")
    end
    local index
    local holes = inst._holes
    local hole = holes[1]
    if hole then
        index = hole
    else
        index = inst._peakIndex + 1
    end
    local tab = inst._table
    if tab[index] ~= inst._placeholder then
        insert(holes, index)
    end
    tab[index] = value
    return index
end)

fixedSparseArray:setMethod("insertMul", function(inst, values)
    if type(values) ~= "table" then
        error("bad type to values expected table")
    end
    local valueCount = #values
    if valueCount > inst.space then
        error(tostring(inst).." out of space")
    end
    local holes = inst._holes
    local holeCount = #holes
    local tab = inst._table
    local indices = {}
    for i = 1, min(holeCount, valueCount) do
        insert(indices, holes[i])
    end
    if valueCount > holeCount then
        local peak = inst._peakIndex
        for i = holeCount + 1, valueCount do
            peak += 1
            insert(indices, peak)
        end
        inst._peakIndex = peak
    end
    local placeholder = inst._placeholder
    for index, insertIndex in ipairs(indices) do
        if tab[insertIndex] ~= placeholder then
            insert(holes, insertIndex)
        end
        tab[insertIndex] = values[index]
    end
    return indices
end)

fixedSparseArray:setMethod("get", function(inst, index)
    local val = inst._table[index]
    if val == inst._placeholder then
        return nil
    end
    return val
end)

fixedSparseArray:setMethod("find", function(inst, value)
    for index, existingValue in ipairs(inst._table) do
        if existingValue == value then
            return index
        end
    end
    return nil
end)

fixedSparseArray:setConstructor(function(inst, size)
    if not isPosInt(size) then
        error("bad type to size espected positive integer")
    end
    inst.size = size
    inst._table = create(size, inst._placeholder)
    inst._holes = {}
end)

fixedSparseArray:finalize()
return fixedSparseArray