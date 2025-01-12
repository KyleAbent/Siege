-- ======= Copyright (c) 2017, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\menu\FancyGUIViewManager.lua
--
--    Created by:   Trevor Harris (trevor@naturalselection2.com)
--
--    Manages all the intermediate steps for a rendered result for complex effects.
--    Example:
--   |  Input Text
--   |  FancyTextGUIView -- renders font to single texture (cannot apply complex shaders to text directly)
--   |  FancyTextureGUIView -- renders complex effects on the resultant texture, and delivers this as a second texture.
--   |  Output Texture
--   V  
--
--    Since GUIView objects are not self-aware, they cannot perform certain tasks like shutting themselves off
--    after they render, or re-activating themselves and their followers when an update is needed.  This manager
--    class fills that role.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

kFancyTextScript = "lua/menu/FancyTextGUIView.lua"
kFancyTextureScript = "lua/menu/FancyTextureGUIView.lua"

class "FancyRenderNode"

function FancyRenderNode:Initialize(manager)
    
    self.manager = manager
    
    self.inputs = {}
    self.inputsIndex = {}
    
    self.inputName = nil
    self.isText = false
    self.outputName = nil
    self.shaderName = nil
    self.extraInputs = {} -- textures parameters generated by other nodes in the tree.
    self.extraParameters = {} -- all parameters (including the above)
    self.extraParametersString = "" -- we can't pass tables to a guiview VM. :(
    
    self.guiView = nil
    self.needsRendering = false
    self.isRendering = false
    
    getmetatable(self).__tostring = FancyRenderNode.ToString
    
end

function FancyRenderNode:ToString()
    
    return string.format("%s\n    inputName = %s\n    isText = %s\n    outputName = %s\n    shaderName = %s\n    extraInputs = %s\n    extraParameters = %s\n    guiView = %s\n    needsRendering = %s\n    isRendering = %s\n", self.classname, self.inputName, self.isText, self.outputName, self.shaderName, self.extraInputs, self.extraParameters, self.guiView, self.needsRendering, self.isRendering)
    
end

function FancyRenderNode:DoRender()
    
    if not self.guiView then
        Log("WARNING!  Attempt to call DoRender() for FancyRenderNode without initializing guiView!")
        Log("%s", debug.traceback())
        return
    end
    
    self.isRendering = true
    self.guiView:SetRenderCondition(GUIView.RenderOnce)
    
end

function FancyRenderNode:HaltRender()
    
    if not self.guiView then
        return
    end
    
    self.isRendering = false
    self.guiView:SetRenderCondition(GUIView.RenderNever)
    
end

function FancyRenderNode:Destroy()
    
    if self.guiView then
        Client.DestroyGUIView(self.guiView)
    end
    
end

function FancyRenderNode:CreateGUIView(luaPath)
    
    if self.guiView then
        Log("ERROR!  Attempt to call FancyRenderNode:CreateGUIViewForText() when guiView is already created!")
        Log("%s", debug.traceback())
        return
    end
    
    local sizeX, sizeY = self.manager:GetSize()
    self.guiView = Client.CreateGUIView(sizeX, sizeY)
    self.guiView:Load(luaPath)
    self.guiView:SetGlobal("sizeX", sizeX)
    self.guiView:SetGlobal("sizeY", sizeY)
    self.guiView:SetRenderCondition(GUIView.RenderNever) -- disable rendering until we're ready to render.
    
end

function FancyRenderNode:CreateGUIViewForText()
    
    self:CreateGUIView(kFancyTextScript)
    
end

function FancyRenderNode:CreateGUIViewForTexture()
    
    self:CreateGUIView(kFancyTextureScript)
    local _, scale = Fancy_Transform(Vector(0,0,0), 1)
    self.guiView:SetGlobal("resScale", scale)
    
end

function FancyRenderNode:CreateGUIViewForNode()
    
    if self.isText then
        self:CreateGUIViewForText()
    else
        self:CreateGUIViewForTexture()
    end
    
end

function FancyRenderNode:SetShader(name)
    
    if self.guiView then
        self.guiView:SetGlobal("shader", name)
    else
        Log("WARNING!  FancyRenderNode:SetShader() called before guiView was setup!")
        Log("%s", debug.traceback())
        return
    end
    
end

-- DO NOT use for texture inputs.  Use AddInputNode for texture inputs, as these are a little bit more involved.
function FancyRenderNode:SetShaderInput(name, value)
    
    if type(value) ~= "string" and type(value) ~= "number" then
        Log("ERROR!  Attempt to call SetShaderInput() with invalid type!  Valid types are string or number.  Type was '%s'", type(value))
        Log("%s", debug.traceback())
        return
    end
    
    if self.guiView then
        
        self.guiView:SetGlobal(name, value)
        
        -- unfortunately, there isn't a really "clean" way of notifying the GUIView when we pass
        -- it a new texture... and we can't pass tables -- only strings and floats.
        -- So we set the globals, and also pass along a string of global variable names separated by
        -- a pipe symbol, and read it back in that way inside the GUIView... hacky, I know... :(
        if not self.extraParameters[name] then
            self.extraParameters[name] = true
            if self.extraParametersString == "" then
                self.extraParametersString = name
            else
                self.extraParametersString = self.extraParametersString.."|"..name
            end
            
            self.guiView:SetGlobal("params", self.extraParametersString)
        end
    else
        Log("WARNING!  FancyRenderNode:SetShaderInput() called before guiView was setup!")
        Log("%s", debug.traceback())
        return
    end
    
    self.manager:RenderAll()
    
end

-- Sets up the heirarchy to keep track of which nodes outputs this node will use as input(s).
-- Use this to set shader paths.
function FancyRenderNode:AddInputNode(node, textureInputName, texturePath)
    
    if self.inputsIndex[node] then
        -- existing input, do nothing
        return
    else
        -- new input
        self.inputsIndex[node] = #self.inputs + 1
        self.inputs[#self.inputs+1] = node
    end
    
    self:SetShaderInput(textureInputName, texturePath)
    
end

class "FancyGUIViewManager"

function FancyGUIViewManager:Initialize(size)
    
    self.nodes = {}
    self.outputNode = nil
    
    self.sizeX = size.x
    self.sizeY = size.y
    
    self.isRendering = false
    self.restartRendering = false
    
    self.lastResetTime = Client.GetLastRenderResetTime()
    
    getmetatable(self).__tostring = FancyGUIViewManager.ToString
    
    -- DEBUG
    gGVM = self
    
end

function FancyGUIViewManager:ToString()
    
    return string.format("%s()\n    nodes = %s\n    outputNode = %s\n    sizeX = %s\n    sizeY = %s\n    isRendering = %s\n    restartRendering = %s\n", self.classname, self.nodes, self.outputNode, self.sizeX, self.sizeY, self.isRendering, self.restartRendering)
    
end

function FancyGUIViewManager:SetSize(sizeX, sizeY)
    
    self.sizeX = sizeX
    self.sizeY = sizeY
    
end

function FancyGUIViewManager:GetSize()
    
    return self.sizeX, self.sizeY
    
end

function FancyGUIViewManager:Destroy()
    
    for i=1, #self.nodes do
        self.nodes[i]:Destroy()
    end
    self.nodes = nil
    
end

local function CreateNewNode(self)
    
    local newNode = FancyRenderNode()
    newNode:Initialize(self)
    self.nodes[#self.nodes + 1] = newNode
    return newNode
    
end

function FancyGUIViewManager:GetNodeByOutputName(name)
    
    for i=1, #self.nodes do
        if self.nodes[i].outputName == name then
            return self.nodes[i]
        end
    end
    
    return nil
    
end

function FancyGUIViewManager:SetTextInputValue(name, value)
    
    for i=1, #self.nodes do
        if self.nodes[i].isText then
            self.nodes[i]:SetShaderInput(name, value)
        end
    end
    
end

-- Creates all node objects and links them together, but doesn't create the guiViews themselves.
function FancyGUIViewManager:Setup(setupTable)
    
    -- read data in, and create the nodes needed.
    for i=1, #setupTable do
        
        local readNode = setupTable[i]
        local newNode = CreateNewNode(self)
        if not readNode.source then
            -- do nothing... could be a mistake, or could be the pixel shader just generates its
            -- own input without a texture.
        elseif readNode.source == "text" then -- text input
            newNode.isText = true
        else -- texture input.
            newNode.inputName = readNode.source
        end
        
        newNode.shaderName = readNode.shader
        
        if readNode.extraInputs then
            for i=1, #readNode.extraInputs do
                newNode.extraInputs[#newNode.extraInputs+1] = readNode.extraInputs[i]
            end
        end
        
        assert(readNode.output)
        if string.sub(readNode.output, 1, 1) ~= "*" then
            Log("ERROR: gui view output texture name MUST begin with '*'.")
            assert(false)
        end
        newNode.outputName = readNode.output
        
        if i == #setupTable then
            -- last node's output is the manager's output.
            self.outputNode = newNode
        end
        
    end
    
    -- link nodes together based on input and output names, and create gui views for them.
    for i=1, #self.nodes do
        local node = self.nodes[i]
        
        -- Must be created in order to setup the inputs.
        node:CreateGUIViewForNode()
        node.guiView:SetTargetTexture(node.outputName)
        
        if node.shaderName then
            node:SetShader(node.shaderName)
        end
        
        -- "source" inputs.
        if node.inputName then
            local inputNode = self:GetNodeByOutputName(node.inputName)
            if inputNode then
                node:AddInputNode(inputNode, "baseTexture", node.inputName)
            else
                -- must come from somewhere else... no node outputs to this texture
                node:SetShaderInput("baseTexture", node.inputName)
            end
        end
        
        -- "extraInputs" inputs.
        for j=1, #node.extraInputs do
            
            if type(node.extraInputs[j][2]) == "number" then
                
                node:SetShaderInput(node.extraInputs[j][1], node.extraInputs[j][2])
                
            elseif type(node.extraInputs[j][2]) == "string" then
                
                local inputNode = self:GetNodeByOutputName(node.extraInputs[j][2])
                if inputNode then
                    
                    -- this node is now dependent upon this other node.
                    node:AddInputNode(inputNode, node.extraInputs[j][1], node.extraInputs[j][2])
                    
                else
                    
                    -- texture not found in any node's output -- must be a pre-made texture, or at least 
                    -- generated elsewhere.
                    node:SetShaderInput(node.extraInputs[j][1], node.extraInputs[j][2])
                    
                end
            else
                assert(false)
            end
            
        end
    end
    
end

-- Causes all nodes to be considered "unrendered" and therefore need re-rendering.
-- We cannot optimize by only updating the outputs of changed nodes because we have
-- no way of knowing if the input textures are still valid... could be invalidated
-- by texture memory manager... I think...
function FancyGUIViewManager:RenderAll()
    
    -- start the rendering next update, so we don't do all this work if we set a bunch of shader inputs at once.
    self.restartRendering = true
    
end

function FancyGUIViewManager:GetOutputTextureName()
    
    if not self.outputNode then
        return nil
    end
    
    return self.outputNode.outputName
    
end

function FancyGUIViewManager:GetIsReadyToDisplay()
    
    -- if it is still rendering or if it will re-render on next update...
    if self.isRendering or self.restartRendering then
        return false
    end
    
    return true
    
end

function FancyGUIViewManager:GetHasRenderDeviceReset()
    
    local resetTime = Client.GetLastRenderResetTime()
    if resetTime > self.lastResetTime then
        self.lastResetTime = resetTime
        return true
    end
    
    return false
    
end

-- Should be called every update.
function FancyGUIViewManager:Update(deltaTime)
    
    -- handle device resets (changing resolutions, alt tabbing, etc.)
    -- if the device resets, usually that means the texture was also
    -- destroyed/cleared, so we need to re-render.  Detect when this
    -- happens.
    -- Detect resets
    local reset = self:GetHasRenderDeviceReset()
    if reset then
        self.waitingForPresent = Shared.GetTime()
        self.restartRenderingCountdown = 4 -- any fewer, and it doesn't take... :/  ... at least on my machine...
    end
    
    -- Detect present.  If we render the instant we reset, it won't work.  We
    -- have to wait until the renderer is actually presenting.
    if self.restartRenderingCountdown then
        
        if self.restartRenderingCountdown <= 0 then
            self.restartRenderingCountdown = nil
            self.restartRendering = true
        else
            local present = Client.GetLastPresentTime()
            if present > self.waitingForPresent then
                self.restartRenderingCountdown = self.restartRenderingCountdown - 1
                self.waitingForPresent = present
            end
        end
        
    end
    
    if self.restartRendering then
        if not self.outputNode then
            return
        end
        
        self.restartRendering = false
        
        -- mark all nodes as needing re-render
        for i=1, #self.nodes do
            self.nodes[i].needsRendering = true
            self.nodes[i]:HaltRender()
        end
        
        self.isRendering = true
        
    end
    
    if self.isRendering then
    
        self.isRendering = false
        
        -- Update the "needsRendering" counter for all the nodes.
        for i=1, #self.nodes do
            if self.nodes[i].isRendering and self.nodes[i].guiView:GetRenderCondition() == GUIView.RenderNever then
                -- node has rendered for this frame
                self.nodes[i].needsRendering = false
                self.nodes[i].isRendering = false
            end
        end
        
        -- At this point, if a node does not "needRendering", then we know it is up-to-date.
        for i=1, #self.nodes do
            if self.nodes[i].needsRendering then
                local node = self.nodes[i]
                local ready = true
                for j=1, #node.inputs do
                    if node.inputs[j].needsRendering then
                        ready = false
                        break
                    end
                end
                
                -- all input nodes to this node have been rendered.
                if ready then
                    self.isRendering = true
                    node:DoRender()
                end
            end
        end
        
    end
    
end

local function OnGVMUpdate()
    
    local nodes = gGVM.nodes
    for i=1, #nodes do
        nodes[i].guiView:SetRenderCondition(GUIView.RenderOnce)
    end
    Log("gvmupdate...")
    
end
Event.Hook("Console_gvmupdate", OnGVMUpdate)



