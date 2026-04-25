return {
    Settings = {
        Elevators = {
            ["Elevator13"] = true,
            ["Elevator14"] = true,
            ["Elevator15"] = true,
            ["Elevator16"] = true
        }
    },

    Positions = {
        ["Mech Cameraman"] = {
            CFrame.new(-26.57, 88.97, -79.43)
        },
        ["Upgraded Titan Cameraman"] = {
            CFrame.new(-27.40, 90.34, -78.89)
        },
        ["Upgraded Speakerwoman"] = {
            CFrame.new(-28.43, 84.69, -65.10)
        },
    },

    Prices = {
        ["Mech Cameraman"] = {400, 300, 500, 800, 1000},
        ["Upgraded Speakerwoman"] = {250, 450, 1000, 1500},
        ["Upgraded Titan Cameraman"] = {1500, 1500, 3000, 4000, 8000, 10000},
    },

    Steps = {
        {action = "set", target = "Skip", value = true},

        {action="place", tower="Upgraded Speakerwoman"},
        {action="upgrade", tower="Upgraded Speakerwoman", level=2},
        {action="upgrade", tower="Upgraded Speakerwoman", level=3},
        {action="upgrade", tower="Upgraded Speakerwoman", level=4},

        {action="fullPlace", tower="Mech Cameraman", count=9},
        
        {action="fullPlace", tower="Upgraded Titan Cameraman"},
        
        {action = "set", target = "Skip", value = true, condition = {type = "wave", value = 25}},
      
        {action="sell", tower="Upgraded Speakerwoman", level=3},

        {action="fullPlace", tower="Upgraded Titan Cameraman", count=5},
    }
}
