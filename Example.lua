-- Lumen Interface Suite | Full example
-- Load the library from the Sentinal-Interface-Suite repository.

local Lumen = loadstring(game:HttpGet("https://raw.githubusercontent.com/siabheng/Sentinal-Interface-Suite/refs/heads/main/Source.lua", true))()

local Window = Lumen:CreateWindow({
	Name = "Lumen Example",
	Subtitle = "v1.0",
	ToggleKey = Enum.KeyCode.RightShift,
	ConfigFolder = "LumenExample",
	KeySystem = false,
	-- KeySettings = { Key = { "KEY-1" }, Note = "Enter your key.", SaveKey = true },
})

local Main = Window:CreateTab({ Name = "Main", Icon = "dashboard", IconSource = "Material" })
local Visuals = Window:CreateTab({ Name = "Visuals", Icon = "visibility", IconSource = "Material" })
local Settings = Window:CreateTab({ Name = "Settings", Icon = "settings", IconSource = "Material" })

-- Main ------------------------------------------------------------
Main:CreateSection("Basics")

Main:CreateButton({
	Name = "Say hello",
	Description = "Shows a notification.",
	Callback = function()
		Lumen:Notify({ Title = "Hello", Content = "Lumen is working.", Type = "Success" })
	end,
})

Main:CreateToggle({
	Name = "Example toggle",
	Description = "Fires its callback on every change.",
	CurrentValue = false,
	Callback = function(value) print("Toggle:", value) end,
}, "ExampleToggle")

Main:CreateSlider({
	Name = "WalkSpeed",
	Range = { 16, 150 },
	Increment = 1,
	CurrentValue = 16,
	Callback = function(value)
		local character = game.Players.LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.WalkSpeed = value end
	end,
}, "WalkSpeed")

Main:CreateSection("Input")

Main:CreateInput({
	Name = "Username",
	PlaceholderText = "Type a name",
	Enter = true,
	Callback = function(text) print("Input:", text) end,
}, "Username")

Main:CreateBind({
	Name = "Hold to sprint",
	CurrentBind = "E",
	HoldToInteract = true,
	Callback = function(held) print("Held:", held) end,
}, "SprintBind")

Main:CreateDropdown({
	Name = "Mode",
	Options = { "Legit", "Rage", "Silent" },
	CurrentOption = "Legit",
	Callback = function(value) print("Mode:", value) end,
}, "Mode")

Main:CreateDropdown({
	Name = "Targets (multi)",
	Options = { "Head", "Torso", "Arms", "Legs" },
	CurrentOption = { "Head", "Torso" },
	MultipleOptions = true,
	Callback = function(list) print("Targets:", table.concat(list, ", ")) end,
}, "Targets")

Main:CreateDropdown({
	Name = "Player",
	Description = "SpecialType = \"Player\" keeps the list in sync.",
	SpecialType = "Player",
	Callback = function(name) print("Player:", name) end,
})

-- Visuals ---------------------------------------------------------
Visuals:CreateColorPicker({
	Name = "ESP colour",
	Color = Color3.fromRGB(98, 120, 255),
	Callback = function(color) print("Colour:", color) end,
}, "ESPColour")

Visuals:CreateDivider()
Visuals:CreateLabel({ Text = "Labels support styles.", Style = "Info" })
Visuals:CreateLabel({ Text = "This is a warning.", Style = "Warning" })

local About = Visuals:CreateParagraph({
	Title = "Paragraph",
	Text = "Paragraphs wrap long text and resize themselves. Use :Set() to change them later.",
})

-- Settings --------------------------------------------------------
Settings:CreateSection("Interface")
Settings:CreateSection("Configuration")
Lumen:BuildConfigSection(Settings)

-- Load the autoload config (if one was set) once the UI is built.
Lumen:LoadAutoload()

Lumen:Notify({ Title = "Lumen", Content = "Press RightShift to hide or show the window.", Duration = 5 })
