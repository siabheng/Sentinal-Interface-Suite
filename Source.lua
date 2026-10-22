--[[

	Lumen Interface Suite
	A clean, dependency-free UI library for Roblox.

	- No external assets or models: every control is built in code
	- Windows, tabs, sections and 10 ready-made elements
	- Notifications, key system, config saving, themes
	- MIT licensed

	Documentation: see README.md

]]

local Release = "1.0.0"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Lumen = { Version = Release, Options = {}, Folder = "Lumen" }

----------------------------------------------------------------------
-- Themes
----------------------------------------------------------------------

local Themes = {
	Dark = {
		Background = Color3.fromRGB(17, 17, 23), Surface = Color3.fromRGB(24, 24, 32),
		Element = Color3.fromRGB(30, 30, 40), ElementHover = Color3.fromRGB(38, 38, 50),
		Stroke = Color3.fromRGB(48, 48, 62), Hover = Color3.fromRGB(70, 70, 92),
		Text = Color3.fromRGB(236, 236, 244), SubText = Color3.fromRGB(150, 150, 168),
		Accent = Color3.fromRGB(98, 120, 255), Success = Color3.fromRGB(72, 199, 142),
		Warning = Color3.fromRGB(245, 181, 68), Danger = Color3.fromRGB(237, 86, 94),
	},
	Midnight = {
		Background = Color3.fromRGB(8, 10, 20), Surface = Color3.fromRGB(13, 17, 32),
		Element = Color3.fromRGB(18, 24, 44), ElementHover = Color3.fromRGB(25, 33, 58),
		Stroke = Color3.fromRGB(34, 44, 78), Hover = Color3.fromRGB(60, 76, 130),
		Text = Color3.fromRGB(230, 236, 255), SubText = Color3.fromRGB(133, 146, 184),
		Accent = Color3.fromRGB(64, 156, 255),
	},
	Rose = {
		Background = Color3.fromRGB(22, 15, 20), Surface = Color3.fromRGB(30, 21, 28),
		Element = Color3.fromRGB(38, 27, 36), ElementHover = Color3.fromRGB(48, 34, 45),
		Stroke = Color3.fromRGB(66, 46, 61), Hover = Color3.fromRGB(98, 68, 90),
		Text = Color3.fromRGB(248, 236, 243), SubText = Color3.fromRGB(177, 148, 166),
		Accent = Color3.fromRGB(244, 99, 151),
	},
	Emerald = {
		Background = Color3.fromRGB(12, 19, 17), Surface = Color3.fromRGB(17, 27, 24),
		Element = Color3.fromRGB(22, 35, 31), ElementHover = Color3.fromRGB(29, 45, 40),
		Stroke = Color3.fromRGB(38, 60, 53), Hover = Color3.fromRGB(56, 92, 81),
		Text = Color3.fromRGB(233, 247, 242), SubText = Color3.fromRGB(142, 172, 162),
		Accent = Color3.fromRGB(52, 211, 153),
	},
	Light = {
		Background = Color3.fromRGB(244, 245, 249), Surface = Color3.fromRGB(255, 255, 255),
		Element = Color3.fromRGB(255, 255, 255), ElementHover = Color3.fromRGB(238, 240, 247),
		Stroke = Color3.fromRGB(218, 221, 232), Hover = Color3.fromRGB(183, 188, 208),
		Text = Color3.fromRGB(28, 30, 40), SubText = Color3.fromRGB(104, 110, 130),
		Accent = Color3.fromRGB(79, 100, 240),
	},
}

for _, theme in pairs(Themes) do
	for key, value in pairs(Themes.Dark) do
		if theme[key] == nil then theme[key] = value end
	end
end

local Theme = {}
for key, value in pairs(Themes.Dark) do Theme[key] = value end

Lumen.Themes = Themes

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

local Connections = {}
local ThemeListeners = {}
local Registry = setmetatable({}, { __mode = "k" }) -- instance -> { Property = ThemeKey }

local function Track(connection)
	Connections[#Connections + 1] = connection
	return connection
end

local function OnTheme(fn)
	ThemeListeners[fn] = true
	return function() ThemeListeners[fn] = nil end
end

local function Defaults(defaults, passed)
	local out = {}
	if type(passed) == "table" then
		for key, value in pairs(passed) do out[key] = value end
	end
	for key, value in pairs(defaults) do
		if out[key] == nil then out[key] = value end
	end
	return out
end

local function Safe(fn, ...)
	if type(fn) ~= "function" then return end
	local ok, err = pcall(fn, ...)
	if not ok then warn("[Lumen] Callback error: " .. tostring(err)) end
end

local function Tween(instance, goal, duration, style, direction)
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
		goal
	)
	tween:Play()
	return tween
end

local TextClasses = { TextLabel = true, TextButton = true, TextBox = true }

local function Create(class, props, children)
	props = props or {}
	local instance = Instance.new(class)

	if instance:IsA("GuiObject") then
		instance.BorderSizePixel = 0
		if class == "TextLabel" or class == "ImageLabel" or class == "TextButton" or class == "ImageButton" or class == "TextBox" then
			instance.BackgroundTransparency = 1
		end
	end
	if TextClasses[class] then
		instance.Font = Enum.Font.Gotham
		instance.TextSize = 13
		if class == "TextButton" then
			instance.AutoButtonColor = false
			instance.Text = ""
		end
	end

	local themed = {}
	if props.Theme then
		for property, key in pairs(props.Theme) do themed[property] = key end
	end
	if TextClasses[class] and props.TextColor3 == nil and themed.TextColor3 == nil then
		themed.TextColor3 = "Text"
	end
	local parent = props.Parent

	for property, value in pairs(props) do
		if property ~= "Theme" and property ~= "Parent" then instance[property] = value end
	end
	if next(themed) then
		Registry[instance] = themed
		for property, key in pairs(themed) do instance[property] = Theme[key] end
	end

	if children then
		for _, child in ipairs(children) do child.Parent = instance end
	end
	instance.Parent = parent
	return instance
end

local function Corner(radius)
	return Create("UICorner", { CornerRadius = UDim.new(0, radius or 6) })
end

local function Stroke(key)
	return Create("UIStroke", {
		Theme = { Color = key or "Stroke" },
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function ListLayout(padding)
	return Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, padding or 0) })
end

local function Pad(top, right, bottom, left)
	return Create("UIPadding", {
		PaddingTop = UDim.new(0, top or 0), PaddingRight = UDim.new(0, right or 0),
		PaddingBottom = UDim.new(0, bottom or 0), PaddingLeft = UDim.new(0, left or 0),
	})
end

local function ToHex(color)
	return string.format("#%02X%02X%02X", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
end

local function FromHex(text)
	local r, g, b = tostring(text):match("^%s*#?(%x%x)(%x%x)(%x%x)%s*$")
	if not r then return nil end
	return Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
end

-- Hover effect shared by most elements
local function Hoverable(frame, stroke)
	Track(frame.MouseEnter:Connect(function()
		Tween(frame, { BackgroundColor3 = Theme.ElementHover }, 0.15)
		if stroke then Tween(stroke, { Color = Theme.Hover }, 0.15) end
	end))
	Track(frame.MouseLeave:Connect(function()
		Tween(frame, { BackgroundColor3 = Theme.Element }, 0.15)
		if stroke then Tween(stroke, { Color = Theme.Stroke }, 0.15) end
	end))
end

----------------------------------------------------------------------
-- Theme API
----------------------------------------------------------------------

function Lumen:SetTheme(themeOrName)
	local source = type(themeOrName) == "string" and Themes[themeOrName] or themeOrName
	if type(source) ~= "table" then return false end
	for key, value in pairs(source) do
		if Theme[key] ~= nil then Theme[key] = value end
	end
	for instance, map in pairs(Registry) do
		for property, key in pairs(map) do
			pcall(function() instance[property] = Theme[key] end)
		end
	end
	for fn in pairs(ThemeListeners) do pcall(fn) end
	return true
end

function Lumen:GetTheme()
	local copy = {}
	for key, value in pairs(Theme) do copy[key] = value end
	return copy
end

----------------------------------------------------------------------
-- Root GUI and notifications
----------------------------------------------------------------------

local function MakeGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "LumenUI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 10000

	if not RunService:IsStudio() then
		if type(gethui) == "function" then
			pcall(function() gui.Parent = gethui() end)
		end
		if not gui.Parent then
			pcall(function() gui.Parent = CoreGui end)
		end
	end
	if not gui.Parent then
		gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end

	for _, sibling in ipairs(gui.Parent:GetChildren()) do
		if sibling.Name == gui.Name and sibling ~= gui then sibling:Destroy() end
	end
	return gui
end

local Gui = MakeGui()

local NotifHolder = Create("Frame", {
	Name = "Notifications",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.new(0, 300, 1, -32),
	BackgroundTransparency = 1,
	Parent = Gui,
}, {
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 8),
	}),
})

local notifCounter = 0

function Lumen:Notify(options)
	options = Defaults({ Title = "Notification", Content = "", Duration = 4, Type = "Info" }, options)
	local colorKey = ({ Info = "Accent", Success = "Success", Warning = "Warning", Error = "Danger" })[options.Type] or "Accent"
	notifCounter += 1

	local wrapper = Create("Frame", {
		Name = "Notification", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = notifCounter, Parent = NotifHolder,
	})
	local card = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(1, 40, 0, 0), Theme = { BackgroundColor3 = "Surface" }, Parent = wrapper,
	}, {
		Corner(8),
		Create("UIStroke", { Color = Theme[colorKey], Thickness = 1, Transparency = 0.4 }),
	})
	local body = Create("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = card,
	}, { Pad(12, 14, 12, 14), ListLayout(3) })

	Create("TextLabel", {
		Text = tostring(options.Title), Size = UDim2.new(1, 0, 0, 18), Font = Enum.Font.GothamBold, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Theme[colorKey], LayoutOrder = 1, Parent = body,
	})
	if tostring(options.Content) ~= "" then
		Create("TextLabel", {
			Text = tostring(options.Content), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			TextWrapped = true, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top, Theme = { TextColor3 = "SubText" }, LayoutOrder = 2, Parent = body,
		})
	end

	Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.35)
	task.delay(options.Duration, function()
		if not wrapper.Parent then return end
		Tween(card, { Position = UDim2.new(1, 40, 0, 0) }, 0.3)
		task.wait(0.32)
		wrapper:Destroy()
	end)
end

----------------------------------------------------------------------
-- Dragging
----------------------------------------------------------------------

local function MakeDraggable(handle, target)
	local dragging, startPos, startInput
	Track(handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, startInput, startPos = true, input.Position, target.Position
			local changed
			changed = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					changed:Disconnect()
				end
			end)
		end
	end))
	Track(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - startInput
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end))
end

----------------------------------------------------------------------
-- Element factory (shared by Tabs and Sections)
----------------------------------------------------------------------

local AddElements -- defined in the elements part

local function Register(flag, element)
	if flag and flag ~= "" then Lumen.Options[flag] = element end
end

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------

function Lumen:CreateWindow(settings)
	settings = Defaults({
		Name = "Lumen Window",
		Subtitle = "",
		Size = UDim2.fromOffset(640, 420),
		ToggleKey = Enum.KeyCode.RightShift,
		ConfigFolder = "Lumen",
		KeySystem = false,
		KeySettings = {},
	}, settings)

	settings.KeySettings = Defaults({
		Title = settings.Name,
		Subtitle = "Key System",
		Note = "Enter your key to continue.",
		Key = { "" },
		SaveKey = true,
		FileName = "key",
		Link = nil, -- optional: copied to clipboard by the "Get Key" button
	}, settings.KeySettings)

	Lumen.Folder = settings.ConfigFolder

	local Window = { Tabs = {}, Visible = true, ToggleKey = settings.ToggleKey }
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local width = math.min(settings.Size.X.Offset, viewport.X - 40)
	local height = math.min(settings.Size.Y.Offset, viewport.Y - 40)

	local Main = Create("Frame", {
		Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height), ClipsDescendants = true,
		Theme = { BackgroundColor3 = "Background" }, Parent = Gui,
	}, { Corner(10), Stroke("Stroke") })

	local Topbar = Create("Frame", {
		Name = "Topbar", Size = UDim2.new(1, 0, 0, 44), Theme = { BackgroundColor3 = "Surface" }, Parent = Main,
	})
	Create("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1),
		Theme = { BackgroundColor3 = "Stroke" }, Parent = Topbar,
	})
	Create("Frame", {
		Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(16, 16),
		Theme = { BackgroundColor3 = "Accent" }, Parent = Topbar,
	}, { Corner(5) })
	Create("TextLabel", {
		Text = settings.Name, Font = Enum.Font.GothamBold, TextSize = 14, Position = UDim2.fromOffset(38, 0),
		Size = UDim2.new(0.5, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = Topbar,
	})
	local subtitle = Create("TextLabel", {
		Text = settings.Subtitle, TextSize = 12, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -90, 0, 0),
		Size = UDim2.new(0.35, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Right,
		Theme = { TextColor3 = "SubText" }, Parent = Topbar,
	})
	subtitle.Visible = settings.Subtitle ~= ""

	local function TopButton(text, offset)
		local button = Create("TextButton", {
			Text = text, Font = Enum.Font.GothamBold, TextSize = 14, AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, offset, 0.5, 0), Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1,
			Theme = { TextColor3 = "SubText", BackgroundColor3 = "ElementHover" }, Parent = Topbar,
		}, { Corner(6) })
		Track(button.MouseEnter:Connect(function() Tween(button, { BackgroundTransparency = 0 }, 0.12) end))
		Track(button.MouseLeave:Connect(function() Tween(button, { BackgroundTransparency = 1 }, 0.12) end))
		return button
	end
	local CloseButton = TopButton("×", -10)
	local MinButton = TopButton("–", -42)

	MakeDraggable(Topbar, Main)

	local Sidebar = Create("Frame", {
		Name = "Sidebar", Position = UDim2.fromOffset(0, 44), Size = UDim2.new(0, 158, 1, -44),
		Theme = { BackgroundColor3 = "Surface" }, Parent = Main,
	})
	Create("Frame", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 1, 1, 0),
		Theme = { BackgroundColor3 = "Stroke" }, Parent = Sidebar,
	})
	local TabList = Create("ScrollingFrame", {
		Size = UDim2.new(1, -1, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = Sidebar,
	}, { Pad(10, 8, 10, 8), ListLayout(4) })

	local Content = Create("Frame", {
		Name = "Content", Position = UDim2.fromOffset(158, 44), Size = UDim2.new(1, -158, 1, -44),
		BackgroundTransparency = 1, ClipsDescendants = true, Parent = Main,
	})

	local Overlay = Create("Frame", { -- key system / modal layer
		Name = "Overlay", Size = UDim2.fromScale(1, 1), Theme = { BackgroundColor3 = "Background" },
		Visible = false, ZIndex = 50, Parent = Main,
	})

	-- Visibility ----------------------------------------------------
	local minimized = false
	function Window:SetVisible(state)
		Window.Visible = state
		Main.Visible = state
	end
	function Window:Toggle() Window:SetVisible(not Window.Visible) end

	Track(UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Window.ToggleKey then Window:Toggle() end
	end))

	Track(CloseButton.MouseButton1Click:Connect(function()
		Window:SetVisible(false)
		Lumen:Notify({
			Title = "Interface hidden",
			Content = "Press " .. Window.ToggleKey.Name .. " to open it again.",
			Duration = 3,
		})
	end))

	Track(MinButton.MouseButton1Click:Connect(function()
		minimized = not minimized
		Sidebar.Visible = not minimized
		Content.Visible = not minimized
		Tween(Main, { Size = minimized and UDim2.fromOffset(width, 44) or UDim2.fromOffset(width, height) }, 0.25)
	end))

	function Window:SetToggleKey(key) Window.ToggleKey = key end

		-- Key system ----------------------------------------------------
	if settings.KeySystem then
		local ks = settings.KeySettings
		if type(ks.Key) == "string" then ks.Key = { ks.Key } end

		local keyFile = Lumen.Folder .. "/keys/" .. ks.FileName .. ".key"
		local canFile = type(isfile) == "function" and type(writefile) == "function"

		local function Valid(input)
			for _, key in ipairs(ks.Key) do
				if input == key then return true end
			end
			return false
		end

		local passed = false
		if canFile and ks.SaveKey then
			local ok, saved = pcall(function()
				if isfile(keyFile) then return readfile(keyFile) end
			end)
			if ok and saved and Valid(saved) then passed = true end
		end

		if not passed then
			Overlay.Visible = true
			local card = Create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(340, 0), AutomaticSize = Enum.AutomaticSize.Y,
				Theme = { BackgroundColor3 = "Surface" }, ZIndex = 51, Parent = Overlay,
			}, { Corner(10), Stroke("Stroke"), Pad(20, 20, 20, 20), ListLayout(8) })

			Create("TextLabel", {
				Text = ks.Title, Font = Enum.Font.GothamBold, TextSize = 18, Size = UDim2.new(1, 0, 0, 24),
				TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, ZIndex = 52, Parent = card,
			})
			Create("TextLabel", {
				Text = ks.Subtitle, TextSize = 12, Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left,
				Theme = { TextColor3 = "Accent" }, LayoutOrder = 2, ZIndex = 52, Parent = card,
			})
			Create("TextLabel", {
				Text = ks.Note, TextSize = 12, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
				TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
				Theme = { TextColor3 = "SubText" }, LayoutOrder = 3, ZIndex = 52, Parent = card,
			})

			local box = Create("TextBox", {
				Text = "", PlaceholderText = "Enter key...", ClearTextOnFocus = false, Size = UDim2.new(1, 0, 0, 36),
				BackgroundTransparency = 0, Theme = { BackgroundColor3 = "Element", PlaceholderColor3 = "SubText" },
				LayoutOrder = 4, ZIndex = 52, Parent = card,
			}, { Corner(6), Stroke("Stroke"), Pad(0, 10, 0, 10) })
			box.TextXAlignment = Enum.TextXAlignment.Left

			local status = Create("TextLabel", {
				Text = "", TextSize = 12, Size = UDim2.new(1, 0, 0, 14), TextXAlignment = Enum.TextXAlignment.Left,
				Theme = { TextColor3 = "Danger" }, LayoutOrder = 5, ZIndex = 52, Parent = card,
			})

			local row = Create("Frame", {
				Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, LayoutOrder = 6, ZIndex = 52, Parent = card,
			}, { Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }) })

			local function KeyButton(text, accent, width)
				local button = Create("TextButton", {
					Text = text, Font = Enum.Font.GothamMedium, BackgroundTransparency = 0,
					Size = UDim2.new(width, width == 1 and 0 or -4, 1, 0), ZIndex = 53,
					Theme = { BackgroundColor3 = accent and "Accent" or "Element" }, Parent = row,
				}, { Corner(6) })
				if accent then
					Registry[button] = { BackgroundColor3 = "Accent" }
					button.TextColor3 = Color3.new(1, 1, 1)
				end
				return button
			end

			local hasLink = ks.Link ~= nil and ks.Link ~= ""
			local submit = KeyButton("Submit", true, hasLink and 0.5 or 1)
			if hasLink then
				local getKey = KeyButton("Get Key", false, 0.5)
				Track(getKey.MouseButton1Click:Connect(function()
					if type(setclipboard) == "function" then
						pcall(setclipboard, tostring(ks.Link))
						status.TextColor3 = Theme.Success
						status.Text = "Link copied to clipboard."
					else
						status.TextColor3 = Theme.Warning
						status.Text = tostring(ks.Link)
					end
				end))
			end

			local attempts = 0
			local function Attempt()
				if Valid(box.Text) then
					if canFile and ks.SaveKey then
						pcall(function()
							if type(isfolder) == "function" and not isfolder(Lumen.Folder) then makefolder(Lumen.Folder) end
							if not isfolder(Lumen.Folder .. "/keys") then makefolder(Lumen.Folder .. "/keys") end
							writefile(keyFile, box.Text)
						end)
					end
					passed = true
					Overlay.Visible = false
					card:Destroy()
				else
					attempts += 1
					status.TextColor3 = Theme.Danger
					status.Text = "Invalid key (" .. attempts .. ")"
				end
			end
			Track(submit.MouseButton1Click:Connect(Attempt))
			Track(box.FocusLost:Connect(function(enter) if enter then Attempt() end end))

			repeat task.wait(0.1) until passed
		end
	end


		-- Tabs ----------------------------------------------------------
	local function SelectTab(tab)
		for _, other in ipairs(Window.Tabs) do
			local active = other == tab
			other.Page.Visible = active
			Tween(other.Button, { BackgroundTransparency = active and 0 or 1 }, 0.15)
			Tween(other.Label, { TextColor3 = active and Theme.Text or Theme.SubText }, 0.15)
			Tween(other.Bar, { BackgroundTransparency = active and 0 or 1 }, 0.15)
		end
		Window.CurrentTab = tab
	end

	function Window:CreateTab(tabSettings)
		tabSettings = Defaults({ Name = "Tab", Icon = nil }, tabSettings)
		local Tab = { Name = tabSettings.Name }

		local button = Create("TextButton", {
			Name = tabSettings.Name, Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1,
			Theme = { BackgroundColor3 = "Element" }, LayoutOrder = #Window.Tabs + 1, Parent = TabList,
		}, { Corner(6) })
		local bar = Create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(3, 16),
			BackgroundTransparency = 1, Theme = { BackgroundColor3 = "Accent" }, Parent = button,
		}, { Corner(2) })
		local label = Create("TextLabel", {
			Text = (tabSettings.Icon and (tabSettings.Icon .. "  ") or "") .. tabSettings.Name,
			Font = Enum.Font.GothamMedium, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -14, 1, 0),
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			TextColor3 = Theme.SubText, Parent = button,
		})

		local page = Create("ScrollingFrame", {
			Name = tabSettings.Name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Theme = { ScrollBarImageColor3 = "Hover" }, Visible = false, Parent = Content,
		}, { Pad(14, 14, 14, 14), ListLayout(8) })

		Tab.Page, Tab.Button, Tab.Label, Tab.Bar = page, button, label, bar
		Window.Tabs[#Window.Tabs + 1] = Tab

		Track(button.MouseButton1Click:Connect(function() SelectTab(Tab) end))
		Track(button.MouseEnter:Connect(function()
			if Window.CurrentTab ~= Tab then Tween(label, { TextColor3 = Theme.Text }, 0.12) end
		end))
		Track(button.MouseLeave:Connect(function()
			if Window.CurrentTab ~= Tab then Tween(label, { TextColor3 = Theme.SubText }, 0.12) end
		end))

		AddElements(Tab, page)

		function Tab:CreateSection(name)
			local Section = {}
			Create("TextLabel", {
				Text = string.upper(tostring(name or "Section")), Font = Enum.Font.GothamBold, TextSize = 11,
				Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Left,
				Theme = { TextColor3 = "SubText" }, LayoutOrder = Tab:NextOrder(), Parent = page,
			}, { Pad(6, 0, 0, 2) })
			AddElements(Section, page, Tab)
			return Section
		end

		function Tab:Activate() SelectTab(Tab) end

		if #Window.Tabs == 1 then SelectTab(Tab) end
		return Tab
	end

	function Window:Destroy() Lumen:Destroy() end

	-- Re-colour tab labels when the theme changes
	OnTheme(function()
		if Window.CurrentTab then SelectTab(Window.CurrentTab) end
	end)

	Window.Main = Main


	return Window
end

----------------------------------------------------------------------
-- Elements
----------------------------------------------------------------------

local PageOrder = setmetatable({}, { __mode = "k" })

local function Card(page, height, order)
	local frame = Create("Frame", {
		Size = UDim2.new(1, 0, 0, height or 40), Theme = { BackgroundColor3 = "Element" },
		LayoutOrder = order, Parent = page,
	}, { Corner(6) })
	local stroke = Stroke("Stroke")
	stroke.Parent = frame
	return frame, stroke
end

local function TitleAndDesc(frame, name, description, rightPadding)
	local hasDesc = description ~= nil and description ~= ""
	Create("TextLabel", {
		Name = "Title", Text = tostring(name), Font = Enum.Font.GothamMedium,
		Position = UDim2.fromOffset(12, hasDesc and 7 or 0), Size = UDim2.new(1, -(rightPadding or 24), 0, hasDesc and 16 or 40),
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = frame,
	})
	if hasDesc then
		Create("TextLabel", {
			Name = "Desc", Text = tostring(description), TextSize = 12, Position = UDim2.fromOffset(12, 24),
			Size = UDim2.new(1, -(rightPadding or 24), 0, 14), TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, Theme = { TextColor3 = "SubText" }, Parent = frame,
		})
		frame.Size = UDim2.new(1, 0, 0, 50)
	end
	return hasDesc
end

AddElements = function(target, page)
	PageOrder[page] = PageOrder[page] or 0
	function target:NextOrder()
		PageOrder[page] += 1
		return PageOrder[page]
	end

	-- Divider ---------------------------------------------------------
	function target:CreateDivider()
		local holder = Create("Frame", {
			Size = UDim2.new(1, 0, 0, 10), BackgroundTransparency = 1, LayoutOrder = target:NextOrder(), Parent = page,
		})
		Create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 1),
			Theme = { BackgroundColor3 = "Stroke" }, Parent = holder,
		})
		return { Destroy = function() holder:Destroy() end }
	end

	-- Label -----------------------------------------------------------
	function target:CreateLabel(options)
		options = Defaults({ Text = "Label", Style = "Default" }, options)
		local Label = { Settings = options }
		local color = ({ Default = "SubText", Info = "Accent", Success = "Success", Warning = "Warning", Error = "Danger" })[options.Style] or "SubText"

		local text = Create("TextLabel", {
			Text = tostring(options.Text), TextSize = 13, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
			Theme = { TextColor3 = color }, LayoutOrder = target:NextOrder(), Parent = page,
		}, { Pad(2, 2, 2, 2) })

		function Label:Set(newText)
			Label.Settings.Text = newText
			text.Text = tostring(newText)
		end
		function Label:Destroy() text:Destroy() end
		return Label
	end

	-- Paragraph -------------------------------------------------------
	function target:CreateParagraph(options)
		options = Defaults({ Title = "Paragraph", Text = "" }, options)
		local Paragraph = { Settings = options }

		local frame = Card(page, 40, target:NextOrder())
		frame.AutomaticSize = Enum.AutomaticSize.Y
		frame.Size = UDim2.new(1, 0, 0, 0)
		local body = Create("Frame", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = frame,
		}, { Pad(10, 12, 12, 12), ListLayout(4) })
		local title = Create("TextLabel", {
			Text = tostring(options.Title), Font = Enum.Font.GothamBold, Size = UDim2.new(1, 0, 0, 16),
			TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, Parent = body,
		})
		local text = Create("TextLabel", {
			Text = tostring(options.Text), TextSize = 12, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
			Theme = { TextColor3 = "SubText" }, LayoutOrder = 2, Parent = body,
		})

		function Paragraph:Set(new)
			new = Defaults({ Title = Paragraph.Settings.Title, Text = Paragraph.Settings.Text }, new)
			Paragraph.Settings = new
			title.Text, text.Text = tostring(new.Title), tostring(new.Text)
		end
		function Paragraph:Destroy() frame:Destroy() end
		return Paragraph
	end

	-- Button ----------------------------------------------------------
	function target:CreateButton(options)
		options = Defaults({ Name = "Button", Description = nil, Callback = function() end }, options)
		local Button = { Settings = options }

		local frame, stroke = Card(page, 40, target:NextOrder())
		TitleAndDesc(frame, options.Name, options.Description, 50)
		Create("TextLabel", {
			Text = "›", Font = Enum.Font.GothamBold, TextSize = 20, AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(16, 20), Theme = { TextColor3 = "SubText" }, Parent = frame,
		})
		local click = Create("TextButton", { Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = frame })
		Hoverable(frame, stroke)

		Track(click.MouseButton1Click:Connect(function()
			Tween(stroke, { Color = Theme.Accent }, 0.1)
			task.delay(0.18, function() Tween(stroke, { Color = Theme.Stroke }, 0.2) end)
			Safe(Button.Settings.Callback)
		end))

		function Button:Set(new)
			new = Defaults(Button.Settings, new)
			Button.Settings = new
			frame.Title.Text = tostring(new.Name)
			if frame:FindFirstChild("Desc") then frame.Desc.Text = tostring(new.Description or "") end
		end
		function Button:Destroy() frame:Destroy() end
		return Button
	end

	-- Toggle ----------------------------------------------------------
	function target:CreateToggle(options, flag)
		options = Defaults({ Name = "Toggle", Description = nil, CurrentValue = false, Callback = function() end }, options)
		local Toggle = { Class = "Toggle", CurrentValue = options.CurrentValue and true or false, Settings = options }

		local frame, stroke = Card(page, 40, target:NextOrder())
		TitleAndDesc(frame, options.Name, options.Description, 70)
		local track = Create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(38, 20),
			Theme = { BackgroundColor3 = "Stroke" }, Parent = frame,
		}, { Corner(10) })
		local knob = Create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = Color3.new(1, 1, 1), Parent = track,
		}, { Corner(7) })
		local click = Create("TextButton", { Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = frame })
		Hoverable(frame, stroke)

		local function Render(animate)
			local on = Toggle.CurrentValue
			local duration = animate and 0.18 or 0
			Tween(track, { BackgroundColor3 = on and Theme.Accent or Theme.Stroke }, duration)
			Tween(knob, { Position = on and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, duration)
		end
		Render(false)

		local function SetValue(value, silent)
			Toggle.CurrentValue = value and true or false
			Toggle.Settings.CurrentValue = Toggle.CurrentValue
			Render(true)
			if not silent then Safe(Toggle.Settings.Callback, Toggle.CurrentValue) end
		end

		Track(click.MouseButton1Click:Connect(function() SetValue(not Toggle.CurrentValue) end))
		OnTheme(function() Render(false) end)

		function Toggle:Set(new)
			if type(new) == "boolean" then return SetValue(new) end
			new = Defaults(Toggle.Settings, new)
			Toggle.Settings = new
			frame.Title.Text = tostring(new.Name)
			if frame:FindFirstChild("Desc") then frame.Desc.Text = tostring(new.Description or "") end
			SetValue(new.CurrentValue)
		end
		function Toggle:Destroy() frame:Destroy() end

		Register(flag, Toggle)
		if Toggle.CurrentValue then Safe(options.Callback, true) end
		return Toggle
	end

	-- Slider ----------------------------------------------------------
	function target:CreateSlider(options, flag)
		options = Defaults({
			Name = "Slider", Range = { 0, 100 }, Increment = 1, Suffix = "",
			CurrentValue = 50, Callback = function() end,
		}, options)
		local Slider = { Class = "Slider", Settings = options }

		local frame, stroke = Card(page, 52, target:NextOrder())
		Create("TextLabel", {
			Name = "Title", Text = tostring(options.Name), Font = Enum.Font.GothamMedium, Position = UDim2.fromOffset(12, 6),
			Size = UDim2.new(1, -90, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, Parent = frame,
		})
		local valueLabel = Create("TextLabel", {
			Text = "", TextSize = 12, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 6),
			Size = UDim2.fromOffset(80, 18), TextXAlignment = Enum.TextXAlignment.Right, Theme = { TextColor3 = "SubText" }, Parent = frame,
		})
		local bar = Create("Frame", {
			Position = UDim2.new(0, 12, 0, 33), Size = UDim2.new(1, -24, 0, 6), Theme = { BackgroundColor3 = "Stroke" }, Parent = frame,
		}, { Corner(3) })
		local fill = Create("Frame", {
			Size = UDim2.fromScale(0, 1), Theme = { BackgroundColor3 = "Accent" }, Parent = bar,
		}, { Corner(3) })
		local knob = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(12, 12),
			BackgroundColor3 = Color3.new(1, 1, 1), Parent = bar,
		}, { Corner(6) })
		Hoverable(frame, stroke)

		local min, max = options.Range[1], options.Range[2]
		local function Snap(value)
			local step = options.Increment
			value = math.clamp(value, min, max)
			value = math.floor((value - min) / step + 0.5) * step + min
			return math.clamp(tonumber(string.format("%.6f", value)), min, max)
		end

		local function Render(value, animate)
			local alpha = (max == min) and 0 or (value - min) / (max - min)
			local duration = animate and 0.08 or 0
			Tween(fill, { Size = UDim2.fromScale(alpha, 1) }, duration)
			Tween(knob, { Position = UDim2.fromScale(alpha, 0.5) }, duration)
			valueLabel.Text = tostring(value) .. tostring(options.Suffix)
		end

		local function SetValue(value, silent)
			value = Snap(tonumber(value) or Slider.CurrentValue or min)
			local changed = value ~= Slider.CurrentValue
			Slider.CurrentValue = value
			Slider.Settings.CurrentValue = value
			Render(value, true)
			if changed and not silent then Safe(Slider.Settings.Callback, value) end
		end

		local dragging = false
		local function FromMouse(x)
			local alpha = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
			SetValue(min + (max - min) * alpha)
		end
		local hit = Create("TextButton", { Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = frame })
		Track(hit.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				FromMouse(input.Position.X)
			end
		end))
		Track(UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				FromMouse(input.Position.X)
			end
		end))
		Track(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end))

		Slider.CurrentValue = Snap(options.CurrentValue)
		Render(Slider.CurrentValue, false)

		function Slider:Set(new)
			if type(new) == "number" then return SetValue(new) end
			new = Defaults(Slider.Settings, new)
			Slider.Settings = new
			options, min, max = new, new.Range[1], new.Range[2]
			frame.Title.Text = tostring(new.Name)
			SetValue(new.CurrentValue)
		end
		function Slider:Destroy() frame:Destroy() end

		Register(flag, Slider)
		Safe(options.Callback, Slider.CurrentValue)
		return Slider
	end

	-- Input -----------------------------------------------------------
	function target:CreateInput(options, flag)
		options = Defaults({
			Name = "Input", Description = nil, CurrentValue = "", PlaceholderText = "Type here...",
			Numeric = false, Enter = false, ClearOnFocusLost = false, MaxCharacters = nil, Callback = function() end,
		}, options)
		local Input = { Class = "Input", CurrentValue = tostring(options.CurrentValue), Settings = options }

		local frame, stroke = Card(page, 40, target:NextOrder())
		TitleAndDesc(frame, options.Name, options.Description, 170)
		local boxFrame = Create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(140, 26),
			Theme = { BackgroundColor3 = "Background" }, Parent = frame,
		}, { Corner(5), Stroke("Stroke"), Pad(0, 8, 0, 8) })
		local box = Create("TextBox", {
			Text = Input.CurrentValue, PlaceholderText = options.PlaceholderText, ClearTextOnFocus = false, TextSize = 12,
			Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			Theme = { PlaceholderColor3 = "SubText" }, Parent = boxFrame,
		})
		Hoverable(frame, stroke)

		local function Fire()
			Input.CurrentValue = box.Text
			Input.Settings.CurrentValue = box.Text
			Safe(Input.Settings.Callback, box.Text)
		end

		Track(box:GetPropertyChangedSignal("Text"):Connect(function()
			if Input.Settings.Numeric then
				local cleaned = box.Text:gsub("[^%d%.%-]", "")
				if cleaned ~= box.Text then box.Text = cleaned return end
			end
			local limit = tonumber(Input.Settings.MaxCharacters)
			if limit and #box.Text > limit then box.Text = box.Text:sub(1, limit) return end
			Input.CurrentValue = box.Text
			if not Input.Settings.Enter then Fire() end
		end))
		Track(box.FocusLost:Connect(function(enterPressed)
			if Input.Settings.Enter and enterPressed then Fire() end
			if Input.Settings.ClearOnFocusLost then box.Text = "" end
		end))

		function Input:Set(new)
			if type(new) == "string" then new = { CurrentValue = new } end
			new = Defaults(Input.Settings, new)
			Input.Settings = new
			frame.Title.Text = tostring(new.Name)
			box.PlaceholderText = tostring(new.PlaceholderText)
			box.Text = tostring(new.CurrentValue)
		end
		function Input:Destroy() frame:Destroy() end

		Register(flag, Input)
		return Input
	end

	-- Keybind ---------------------------------------------------------
	function target:CreateBind(options, flag)
		options = Defaults({
			Name = "Keybind", Description = nil, CurrentBind = "Q", HoldToInteract = false,
			Callback = function() end, OnChangedCallback = function() end,
		}, options)
		local Bind = { Class = "Keybind", CurrentBind = options.CurrentBind, Active = false, Settings = options }

		local frame, stroke = Card(page, 40, target:NextOrder())
		TitleAndDesc(frame, options.Name, options.Description, 120)
		local chip = Create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(70, 26),
			Font = Enum.Font.GothamMedium, TextSize = 12, BackgroundTransparency = 0, Text = options.CurrentBind,
			Theme = { BackgroundColor3 = "Background" }, Parent = frame,
		}, { Corner(5), Stroke("Stroke") })
		Hoverable(frame, stroke)

		local listening = false
		local function Resize()
			chip.Size = UDim2.fromOffset(math.max(50, #chip.Text * 8 + 20), 26)
		end
		Resize()

		Track(chip.MouseButton1Click:Connect(function()
			listening = true
			chip.Text = "..."
			Resize()
		end))

		Track(UserInputService.InputBegan:Connect(function(input, processed)
			if listening then
				if input.UserInputType == Enum.UserInputType.Keyboard then
					listening = false
					if input.KeyCode == Enum.KeyCode.Escape then
						chip.Text = Bind.CurrentBind
					else
						Bind.CurrentBind = input.KeyCode.Name
						Bind.Settings.CurrentBind = input.KeyCode.Name
						chip.Text = input.KeyCode.Name
						Safe(Bind.Settings.OnChangedCallback, input.KeyCode)
					end
					Resize()
				end
				return
			end
			if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
			if input.KeyCode.Name ~= Bind.CurrentBind then return end

			if Bind.Settings.HoldToInteract then
				Bind.Active = true
				Safe(Bind.Settings.Callback, true)
			else
				Bind.Active = not Bind.Active
				Safe(Bind.Settings.Callback, Bind.Active)
			end
		end))
		Track(UserInputService.InputEnded:Connect(function(input)
			if Bind.Settings.HoldToInteract and input.KeyCode.Name == Bind.CurrentBind and Bind.Active then
				Bind.Active = false
				Safe(Bind.Settings.Callback, false)
			end
		end))

		function Bind:Set(new)
			if type(new) == "string" then new = { CurrentBind = new } end
			new = Defaults(Bind.Settings, new)
			Bind.Settings = new
			Bind.CurrentBind = new.CurrentBind
			frame.Title.Text = tostring(new.Name)
			chip.Text = new.CurrentBind
			Resize()
		end
		function Bind:Destroy() frame:Destroy() end

		Register(flag, Bind)
		return Bind
	end

	-- Dropdown --------------------------------------------------------
	function target:CreateDropdown(options, flag)
		options = Defaults({
			Name = "Dropdown", Description = nil, Options = { "Option 1", "Option 2" },
			CurrentOption = nil, MultipleOptions = false, SpecialType = nil, Callback = function() end,
		}, options)
		local Dropdown = { Class = "Dropdown", Settings = options }

		local function PlayerNames()
			local names = {}
			for _, player in ipairs(Players:GetPlayers()) do names[#names + 1] = player.Name end
			return names
		end
		if options.SpecialType == "Player" then options.Options = PlayerNames() end

		local selected
		local function Normalise(value)
			local result = {}
			if type(value) == "string" then result = { value }
			elseif type(value) == "table" then for _, v in ipairs(value) do result[#result + 1] = tostring(v) end end
			if not options.MultipleOptions and #result > 1 then result = { result[1] } end
			return result
		end
		selected = Normalise(options.CurrentOption)

		local closedHeight = (options.Description and options.Description ~= "") and 50 or 40
		local frame, stroke = Card(page, closedHeight, target:NextOrder())
		frame.ClipsDescendants = true
		TitleAndDesc(frame, options.Name, options.Description, 190)

		local valueLabel = Create("TextLabel", {
			Text = "", TextSize = 12, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -34, 0, 0),
			Size = UDim2.new(0, 150, 0, closedHeight), TextXAlignment = Enum.TextXAlignment.Right,
			TextTruncate = Enum.TextTruncate.AtEnd, Theme = { TextColor3 = "SubText" }, Parent = frame,
		})
		local chevron = Create("TextLabel", {
			Text = "⌄", Font = Enum.Font.GothamBold, TextSize = 16, AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 0), Size = UDim2.fromOffset(18, closedHeight),
			Theme = { TextColor3 = "SubText" }, Parent = frame,
		})
		local header = Create("TextButton", { Size = UDim2.new(1, 0, 0, closedHeight), ZIndex = 5, Parent = frame })

		local search = Create("TextBox", {
			PlaceholderText = "Search...", Text = "", ClearTextOnFocus = false, TextSize = 12,
			Position = UDim2.fromOffset(10, closedHeight + 2), Size = UDim2.new(1, -20, 0, 26), BackgroundTransparency = 0,
			TextXAlignment = Enum.TextXAlignment.Left, Theme = { BackgroundColor3 = "Background", PlaceholderColor3 = "SubText" },
			Parent = frame,
		}, { Corner(5), Pad(0, 8, 0, 8) })
		local list = Create("ScrollingFrame", {
			Position = UDim2.fromOffset(10, closedHeight + 34), Size = UDim2.new(1, -20, 0, 100), BackgroundTransparency = 1,
			ScrollBarThickness = 2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Theme = { ScrollBarImageColor3 = "Hover" }, Parent = frame,
		}, { ListLayout(2) })
		local openHeight = closedHeight + 142
		Hoverable(frame, stroke)

		local isOpen = false
		local function Summary()
			if #selected == 0 then return "None" end
			if #selected <= 2 then return table.concat(selected, ", ") end
			return selected[1] .. ", " .. selected[2] .. " +" .. (#selected - 2)
		end

		local rows = {}
		local function Paint()
			valueLabel.Text = Summary()
			for name, row in pairs(rows) do
				local on = table.find(selected, name) ~= nil
				row.TextColor3 = on and Theme.Accent or Theme.Text
				row.BackgroundTransparency = on and 0.85 or 1
			end
		end

		local function Fire()
			local payload = options.MultipleOptions and table.clone(selected) or selected[1]
			Dropdown.CurrentOption = payload
			Dropdown.Settings.CurrentOption = payload
			Safe(Dropdown.Settings.Callback, payload)
		end

		local function Toggle(open)
			isOpen = open
			Tween(frame, { Size = UDim2.new(1, 0, 0, open and openHeight or closedHeight) }, 0.22)
			Tween(chevron, { Rotation = open and 180 or 0 }, 0.22)
		end

		local function Rebuild()
			for _, row in pairs(rows) do row:Destroy() end
			rows = {}
			for index, name in ipairs(options.Options) do
				name = tostring(name)
				local row = Create("TextButton", {
					Text = name, TextSize = 12, Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = index,
					TextXAlignment = Enum.TextXAlignment.Left, Theme = { BackgroundColor3 = "Accent" }, Parent = list,
				}, { Corner(4), Pad(0, 0, 0, 8) })
				rows[name] = row
				Track(row.MouseButton1Click:Connect(function()
					if options.MultipleOptions then
						local at = table.find(selected, name)
						if at then table.remove(selected, at) else table.insert(selected, name) end
					else
						selected = { name }
						Toggle(false)
					end
					Paint()
					Fire()
				end))
			end
			Paint()
		end

		Track(header.MouseButton1Click:Connect(function() Toggle(not isOpen) end))
		Track(search:GetPropertyChangedSignal("Text"):Connect(function()
			local query = search.Text:lower()
			for name, row in pairs(rows) do
				row.Visible = query == "" or name:lower():find(query, 1, true) ~= nil
			end
		end))
		OnTheme(Paint)

		if options.SpecialType == "Player" then
			local function Refresh() options.Options = PlayerNames() Rebuild() end
			Track(Players.PlayerAdded:Connect(Refresh))
			Track(Players.PlayerRemoving:Connect(function() task.defer(Refresh) end))
			if #selected == 0 then selected = { options.Options[1] } end
		end

		Rebuild()
		Dropdown.CurrentOption = options.MultipleOptions and table.clone(selected) or selected[1]

		function Dropdown:Set(new)
			if type(new) == "string" or (type(new) == "table" and new[1] ~= nil) then new = { CurrentOption = new } end
			new = Defaults(Dropdown.Settings, new)
			Dropdown.Settings = new
			options = new
			frame.Title.Text = tostring(new.Name)
			selected = Normalise(new.CurrentOption)
			Rebuild()
			Fire()
		end
		function Dropdown:Refresh(newOptions, keepSelection)
			options.Options = newOptions
			if not keepSelection then selected = {} end
			Rebuild()
		end
		function Dropdown:Destroy() frame:Destroy() end

		Register(flag, Dropdown)
		if #selected > 0 then Fire() end
		return Dropdown
	end

	-- Color Picker ----------------------------------------------------
	function target:CreateColorPicker(options, flag)
		options = Defaults({ Name = "Color Picker", Color = Color3.fromRGB(255, 255, 255), Callback = function() end }, options)
		local Picker = { Class = "Colorpicker", Color = options.Color, Settings = options }

		local frame, stroke = Card(page, 40, target:NextOrder())
		frame.ClipsDescendants = true
		TitleAndDesc(frame, options.Name, nil, 80)
		local swatch = Create("Frame", {
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 9), Size = UDim2.fromOffset(40, 22),
			BackgroundColor3 = options.Color, Parent = frame,
		}, { Corner(5), Stroke("Stroke") })
		local header = Create("TextButton", { Size = UDim2.new(1, 0, 0, 40), ZIndex = 5, Parent = frame })
		Hoverable(frame, stroke)

		local h, s, v = options.Color:ToHSV()

		local sv = Create("Frame", {
			Position = UDim2.fromOffset(12, 48), Size = UDim2.new(1, -24, 0, 90),
			BackgroundColor3 = Color3.fromHSV(h, 1, 1), Parent = frame,
		}, { Corner(5) })
		-- white -> transparent (saturation), then transparent -> black (value)
		Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = sv }, {
			Corner(5),
			Create("UIGradient", { Transparency = NumberSequence.new(0, 1) }),
		})
		Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Parent = sv }, {
			Corner(5),
			Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }),
		})
		local svKnob = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, ZIndex = 4, Parent = sv,
		}, { Corner(5), Create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }) })

		local hue = Create("Frame", {
			Position = UDim2.fromOffset(12, 146), Size = UDim2.new(1, -24, 0, 10), BackgroundColor3 = Color3.new(1, 1, 1), Parent = frame,
		}, { Corner(5), Create("UIGradient", { Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)), ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
			ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)), ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
			ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)), ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
		}) }) })
		local hueKnob = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(6, 16),
			BackgroundColor3 = Color3.new(1, 1, 1), Parent = hue,
		}, { Corner(3), Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0.6 }) })

		local hexBox = Create("TextBox", {
			Text = "", TextSize = 12, Position = UDim2.fromOffset(12, 164), Size = UDim2.new(1, -24, 0, 26), BackgroundTransparency = 0,
			ClearTextOnFocus = false, Theme = { BackgroundColor3 = "Background" }, Parent = frame,
		}, { Corner(5), Stroke("Stroke") })

		local function Apply(silent)
			local color = Color3.fromHSV(h, s, v)
			Picker.Color = color
			Picker.Settings.Color = color
			swatch.BackgroundColor3 = color
			sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			svKnob.Position = UDim2.fromScale(s, 1 - v)
			hueKnob.Position = UDim2.fromScale(h, 0.5)
			hexBox.Text = ToHex(color)
			if not silent then Safe(Picker.Settings.Callback, color) end
		end

		local mode
		local function Update(position)
			if mode == "sv" then
				s = math.clamp((position.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
				v = 1 - math.clamp((position.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
				Apply()
			elseif mode == "hue" then
				h = math.clamp((position.X - hue.AbsolutePosition.X) / math.max(hue.AbsoluteSize.X, 1), 0, 1)
				Apply()
			end
		end
		local function Begin(target_, name)
			Track(target_.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					mode = name
					Update(input.Position)
				end
			end))
		end
		Begin(sv, "sv")
		Begin(hue, "hue")
		Track(UserInputService.InputChanged:Connect(function(input)
			if mode and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				Update(input.Position)
			end
		end))
		Track(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then mode = nil end
		end))
		Track(hexBox.FocusLost:Connect(function()
			local parsed = FromHex(hexBox.Text)
			if parsed then h, s, v = parsed:ToHSV() end
			Apply()
		end))

		local open = false
		Track(header.MouseButton1Click:Connect(function()
			open = not open
			Tween(frame, { Size = UDim2.new(1, 0, 0, open and 200 or 40) }, 0.22)
		end))

		Apply(true)

		function Picker:Set(new)
			if typeof(new) == "Color3" then new = { Color = new } end
			new = Defaults(Picker.Settings, new)
			Picker.Settings = new
			frame.Title.Text = tostring(new.Name)
			h, s, v = new.Color:ToHSV()
			Apply()
		end
		function Picker:Destroy() frame:Destroy() end

		Register(flag, Picker)
		Safe(options.Callback, options.Color)
		return Picker
	end
end

----------------------------------------------------------------------
-- Configuration
----------------------------------------------------------------------

local FS = type(isfile) == "function" and type(writefile) == "function" and type(readfile) == "function"
	and type(isfolder) == "function" and type(makefolder) == "function" and type(listfiles) == "function"

local function SettingsPath()
	return Lumen.Folder .. "/settings"
end

local function EnsureFolders()
	if not FS then return false end
	if not isfolder(Lumen.Folder) then makefolder(Lumen.Folder) end
	if not isfolder(SettingsPath()) then makefolder(SettingsPath()) end
	return true
end

local Serializers = {
	Toggle = {
		Save = function(option) return { value = option.CurrentValue } end,
		Load = function(option, data) option:Set(data.value == true) end,
	},
	Slider = {
		Save = function(option) return { value = option.CurrentValue } end,
		Load = function(option, data) if type(data.value) == "number" then option:Set(data.value) end end,
	},
	Input = {
		Save = function(option) return { value = option.CurrentValue } end,
		Load = function(option, data) if type(data.value) == "string" then option:Set(data.value) end end,
	},
	Keybind = {
		Save = function(option) return { value = option.CurrentBind } end,
		Load = function(option, data) if type(data.value) == "string" then option:Set(data.value) end end,
	},
	Dropdown = {
		Save = function(option) return { value = option.CurrentOption } end,
		Load = function(option, data) if data.value ~= nil then option:Set(data.value) end end,
	},
	Colorpicker = {
		Save = function(option) return { value = ToHex(option.Color) } end,
		Load = function(option, data)
			local color = FromHex(data.value)
			if color then option:Set(color) end
		end,
	},
}

function Lumen:SaveConfig(name)
	if not EnsureFolders() then return false, "Your executor does not support file functions." end
	if type(name) ~= "string" or name:gsub("%s", "") == "" then return false, "Config name cannot be empty." end

	local data = {}
	for flag, option in pairs(Lumen.Options) do
		local serializer = Serializers[option.Class]
		if serializer then
			local entry = serializer.Save(option)
			entry.class = option.Class
			data[flag] = entry
		end
	end
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
	if not ok then return false, "Could not encode config." end
	writefile(SettingsPath() .. "/" .. name .. ".json", encoded)
	return true
end

function Lumen:LoadConfig(name)
	if not FS then return false, "Your executor does not support file functions." end
	local path = SettingsPath() .. "/" .. tostring(name) .. ".json"
	if not isfile(path) then return false, "Config not found." end

	local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
	if not ok or type(data) ~= "table" then return false, "Config file is corrupted." end

	for flag, entry in pairs(data) do
		local option = Lumen.Options[flag]
		local serializer = option and Serializers[option.Class]
		if serializer and entry.class == option.Class then
			pcall(serializer.Load, option, entry)
		end
	end
	return true
end

function Lumen:ListConfigs()
	local names = {}
	if not EnsureFolders() then return names end
	for _, file in ipairs(listfiles(SettingsPath())) do
		local name = file:match("([^/\\]+)%.json$")
		if name then names[#names + 1] = name end
	end
	table.sort(names)
	return names
end

function Lumen:DeleteConfig(name)
	if not FS or type(delfile) ~= "function" then return false end
	local path = SettingsPath() .. "/" .. tostring(name) .. ".json"
	if isfile(path) then delfile(path) return true end
	return false
end

function Lumen:SetAutoload(name)
	if not EnsureFolders() then return false end
	writefile(SettingsPath() .. "/autoload.txt", tostring(name))
	return true
end

function Lumen:LoadAutoload()
	if not EnsureFolders() then return false end
	local path = SettingsPath() .. "/autoload.txt"
	if not isfile(path) then return false end
	return Lumen:LoadConfig(readfile(path))
end

----------------------------------------------------------------------
-- Prebuilt sections
----------------------------------------------------------------------

-- Adds a ready-made config manager to any tab or section.
function Lumen:BuildConfigSection(target)
	local chosen, newName
	local dropdown

	target:CreateInput({
		Name = "Config Name", PlaceholderText = "my-config",
		Callback = function(text) newName = text end,
	})
	target:CreateButton({
		Name = "Create Config", Description = "Save every flagged element into a new config.",
		Callback = function()
			local ok, err = Lumen:SaveConfig(newName)
			Lumen:Notify({ Title = "Config", Type = ok and "Success" or "Error", Content = ok and ("Saved '" .. newName .. "'.") or err })
			if ok then dropdown:Refresh(Lumen:ListConfigs(), true) end
		end,
	})
	dropdown = target:CreateDropdown({
		Name = "Configs", Options = Lumen:ListConfigs(), CurrentOption = {},
		Callback = function(value) chosen = value end,
	})
	target:CreateButton({
		Name = "Load Config",
		Callback = function()
			local ok, err = Lumen:LoadConfig(chosen)
			Lumen:Notify({ Title = "Config", Type = ok and "Success" or "Error", Content = ok and ("Loaded '" .. tostring(chosen) .. "'.") or err })
		end,
	})
	target:CreateButton({
		Name = "Overwrite Config",
		Callback = function()
			local ok, err = Lumen:SaveConfig(chosen)
			Lumen:Notify({ Title = "Config", Type = ok and "Success" or "Error", Content = ok and "Config overwritten." or err })
		end,
	})
	target:CreateButton({
		Name = "Set As Autoload",
		Callback = function()
			local ok = chosen and Lumen:SetAutoload(chosen)
			Lumen:Notify({ Title = "Config", Type = ok and "Success" or "Error", Content = ok and ("'" .. chosen .. "' will load on start.") or "Select a config first." })
		end,
	})
	target:CreateButton({
		Name = "Refresh List",
		Callback = function() dropdown:Refresh(Lumen:ListConfigs()) end,
	})
end

-- Adds a ready-made theme switcher to any tab or section.
function Lumen:BuildThemeSection(target)
	local names = {}
	for name in pairs(Themes) do names[#names + 1] = name end
	table.sort(names)

	target:CreateDropdown({
		Name = "Theme", Description = "Switch the interface colours instantly.",
		Options = names, CurrentOption = "Dark",
		Callback = function(value) Lumen:SetTheme(value) end,
	})
	target:CreateColorPicker({
		Name = "Accent Colour", Color = Theme.Accent,
		Callback = function(color) Lumen:SetTheme({ Accent = color }) end,
	})
end

----------------------------------------------------------------------
-- Cleanup
----------------------------------------------------------------------

function Lumen:Destroy()
	for _, connection in ipairs(Connections) do pcall(function() connection:Disconnect() end) end
	table.clear(Connections)
	table.clear(ThemeListeners)
	Gui:Destroy()
end

return Lumen
