-- Commands
-- These are keys that the game can support being pressed at the same time
-- When altering these, please remember to update the Player.lua HandleButtons method and update things that shouldn't be
-- allowed when player cannot control themselves.

Move.PrimaryAttack          = bit.lshift(1, 0)
Move.SecondaryAttack        = bit.lshift(1, 1)
Move.SelectNextWeapon       = bit.lshift(1, 2)
Move.SelectPrevWeapon       = bit.lshift(1, 3)
Move.Reload                 = bit.lshift(1, 4)
Move.Use                    = bit.lshift(1, 5)
Move.Jump                   = bit.lshift(1, 6)
Move.Crouch                 = bit.lshift(1, 7)
Move.MovementModifier       = bit.lshift(1, 8)
Move.Minimap                = bit.lshift(1, 9)
Move.Buy                    = bit.lshift(1, 10)
Move.ToggleFlashlight       = bit.lshift(1, 11)
Move.Weapon1                = bit.lshift(1, 12)
Move.Weapon2                = bit.lshift(1, 13)
Move.Weapon3                = bit.lshift(1, 14)
Move.Weapon4                = bit.lshift(1, 15)
Move.Weapon5                = bit.lshift(1, 16)
Move.Drop                   = bit.lshift(1, 17)
Move.Taunt                  = bit.lshift(1, 18)
Move.TertiaryAttack         = bit.lshift(1, 19)
Move.Exit                   = bit.lshift(1, 20)
Move.ScrollForward          = bit.lshift(1, 21)
Move.ScrollLeft             = bit.lshift(1, 22)
Move.ScrollRight            = bit.lshift(1, 23)
Move.ScrollBackward         = bit.lshift(1, 24)
--Move.ToggleRequest          = bit.lshift(1, 25) -- should go (not used)
--Move.ToggleSayings          = bit.lshift(1, 26) -- should go (not used)
--Move.Eject                  = bit.lshift(1, 27) -- should go (not used)
--Move.TextChat               = bit.lshift(1, 28) -- should go (not used)
--Move.TeamChat               = bit.lshift(1, 29) -- should go (not used)
Move.QuickSwitch            = bit.lshift(1, 30)
--Move.ReadyRoom              = bit.lshift(1, 31) -- should go (not used)

-- Hotkeys
-- Only one of these will make it to the game, and it's the last one checked by the InputHandler. These can be used
Move.None                = 0 
Move.Q                   = 1                
Move.W                   = 2
Move.E                   = 3
Move.R                   = 4
Move.T                   = 5
Move.Y                   = 6
Move.U                   = 7
Move.I                   = 8
Move.O                   = 9
Move.P                   = 10
Move.A                   = 11
Move.S                   = 12
Move.D                   = 13
Move.F                   = 14
Move.G                   = 15
Move.H                   = 16
Move.J                   = 17
Move.K                   = 18
Move.L                   = 19
Move.Z                   = 20
Move.X                   = 21
Move.C                   = 22
Move.V                   = 23
Move.B                   = 24
Move.N                   = 25
Move.M                   = 26
Move.Space               = 27
Move.ESC                 = 28
