-- ======= Copyright (c) 2019, Unknown Worlds Entertainment, Inc. All rights reserved. =============
--
-- lua/GUI/wrappers/CircularCollision.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Class wrapper used to modify the IsPointOverObject method of the object to make it a circular
--    (actually ellipsoid) shape.
--
-- ========= For more information, visit us at http://www.unknownworlds.com ========================

Script.Load("lua/GUI/wrappers/WrapperUtility.lua")

DefineClassWrapper
{
    name = "CircularCollision",
    classBuilderFunc = function(wrappedClass, baseClass)
        wrappedClass.IsPointOverObject = GetCachedExtendedMethod("IsPointOverObject", wrappedClass, baseClass,
        function(newClass, oldClass)
            
            -- CircularCollision IsPointOverObject()
            return function(self, pt)
                
                -- Early-out if the old result puts it not over the object.  This new method can
                -- only _exclude_ area, not add new area.
                local oldResult = oldClass.IsPointOverObject(self, pt)
                if not oldResult then
                    return false
                end
                
                local upperLeft = self:GetScreenPosition()
                if pt.x < upperLeft.x or pt.y < upperLeft.y then
                    return false -- outside bounding box.
                end
                
                local absoluteSize = self:GetAbsoluteSize()
                local bottomRight = upperLeft + absoluteSize
                if pt.x >= bottomRight.x or pt.y >= bottomRight.y then
                    return false -- outside bounding box.
                end
    
                local halfSize = absoluteSize * 0.5
                local middle = upperLeft + halfSize
                
                if halfSize.x == 0 then halfSize.x = 1 end
                if halfSize.y == 0 then halfSize.y = 1 end
                
                local normalizedPt = (pt - middle) / halfSize
                local normalizedDistanceSq = (normalizedPt.x * normalizedPt.x) + (normalizedPt.y * normalizedPt.y)
                
                return normalizedDistanceSq <= 1.0
                
            end
            
        end)
    end
}
