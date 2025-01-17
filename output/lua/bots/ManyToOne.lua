------------------------------------------
--  Many-to-one relation, such as many bots to a single memory
--  Many 'items' can be assigned to one 'group', and each 'item' can ONLY be assigned to one group
------------------------------------------
class "ManyToOne"

function ManyToOne:Initialize()

    self.item2group = {}
    self.group2items = {}

end

function ManyToOne:Reset()
    self:Initialize()
end

function ManyToOne:Unassign( item )

    if self.item2group[item] ~= nil then

        -- remove the item from its group set
        local group = self.item2group[item]
        local found = 0
        for i = 1, #self.group2items[group] do
            if self.group2items[group][i] == item then
                found = i
                break
            end
        end

        assert(found > 0)
        table.remove(self.group2items[group], found)

        -- remove the other way
        self.item2group[item] = nil

        return group

    end

end

function ManyToOne:Assign( item, group )

    if self.item2group[item] == group then
        return
    end

    -- First unassign it from its previous, if any
    self:Unassign( item )

    self.item2group[item] = group

    local items = self.group2items[ group ]
    if items == nil then
        items = {}
        self.group2items[ group ] = items
    end
    items[ #items+1 ] = item

end

function ManyToOne:GetIsAssignedTo( item, group )

    return self.item2group[item] == group

end

function ManyToOne:GetItems(group)

    if self.group2items[group] ~= nil then
        return self.group2items[group]
    else
        return {}
    end

end

function ManyToOne:GetNumAssignedTo(group, countsFunc)

    local items = self.group2items[ group ]

    if items == nil then
        return 0
    else

        local count = 0
        for _,item in ipairs(items) do
            if countsFunc == nil or countsFunc(item) then
                count = count + 1
            end
        end
        return count
    end

end

function ManyToOne:DebugDump(item2string, group2string)

    Print("-- group-to-item table --")
    for group, items in pairs(self.group2items) do

        local s = group2string(group) .. " <-- { "
        for _,item in ipairs(items) do
            s = s .. item2string(item) .. ", "

            -- do a sanity check here
            assert( self.item2group[item] == group )
        end
        s = s .. "}"
        Print(s)
        
    end

    Print("-- item-to-group table --")
    for item, group in pairs(self.item2group) do

        Print("%s --> %s", item2string(item), group2string(group))

        assert( table.contains(self.group2items[group], item) )

    end

end

function ManyToOne:RemoveGroup(group)

    local items = self.group2items[group]

    if items ~= nil then

        for _,item in ipairs(items) do
            self.item2group[item] = nil
        end

        self.group2items[group] = nil

    end

end
