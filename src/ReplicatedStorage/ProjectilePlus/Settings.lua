local Settings = {}

Settings.ServerVisualize = false --[true OR false] [Default : false] {ONLY USE THIS FOR TESTING. This is meant to be a way to see the projectiles and catchers on the server, so I only reccommend keeping this on for testing.}

Settings.ClientVisualize = false --[true OR false] [Default : false] {ONLY USE THIS FOR TESTING. This is meant to be a way to see the projectiles and catchers on the client, so I only reccommend keeping this on for testing.}

Settings.StartOnRequire = true --[true OR false] [Default : true] {Dictates whether or not the module will automatically activate on first require call.}

Settings.AutoPlayerCleanup = true --[true OR false] [Default : true] {Automatically destroys projectiles belonging to players who leave the game.}

Settings.ImprovedClientAccuracy = false --[true OR false] [Default : false] {Forces the server to update client projectile positions manually. Decreases offset of client projectiles when following a homing path, but leaves a jagged path if your using trails.}

return Settings
