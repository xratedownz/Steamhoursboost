/*
 _   _           _           _  _____   _____    _ _         _____           _       _     _             _                                 
| \ | |         | |         | |/ ____| |_   _|  | | |       / ____|         (_)     | |   | |           | |                                
|  \| | ___   __| | ___     | | (___     | |  __| | | ___  | (___   ___ _ __ _ _ __ | |_  | |__  _   _  | |    _   _ _ __ __  ____ _  __ _ 
| . ` |/ _ \ / _` |/ _ \_   | |\___ \    | | / _` | |/ _ \  \___ \ / __| '__| | '_ \| __| | '_ \| | | | | |   | | | | '_ \\ \/ / _` |/ _` |
| |\  | (_) | (_| |  __/ |__| |____) |  _| || (_| | |  __/  ____) | (__| |  | | |_) | |_  | |_) | |_| | | |___| |_| | | | |>  < (_| | (_| |
|_| \_|\___/ \__,_|\___|\____/|_____/  |_____\__,_|_|\___| |_____/ \___|_|  |_| .__/ \__| |_.__/ \__, | |______\__, |_| |_/_/\_\__,_|\__,_|
                                                                              | |                 __/ |         __/ |                      
                                                                              |_|                |___/         |___/                       
*/
 
// npm install steam@v0.6.8
var steam = require('steam');
var fs = require('fs');
// npm install readline-sync
var readlineSync = require('readline-sync');
 
// request an auth code from the user, this freezes any other progress until a response is received
var promptAuthCode = function(account) {
	var code = readlineSync.question('[STEAM][' + account.username + '][AUTHCODE]: Enter authcode: ');
	account.authcode = code;
}
 
// just for swagger
var shuffleArray = function(array) {
    for (var i = array.length - 1; i > 0; i--) {
        var j = Math.floor(Math.random() * (i + 1));
        var temp = array[i];
        array[i] = array[j];
        array[j] = temp;
    }
	
    return array;
}
 
// accounts array, you can move this into another file if you want
// if you move it to a different file you'll need to do var ... = require(...)
// to access the array.
var accounts = [
	{
		username: "ph_ara_oh@hotmail.com",
		password: "x12ra21ted",
		games: [
			730, 
			570, 
			440, 
			10,
			240,
			368720,
			383580,
			230410,
			399430
		],
		loggedIn: false
	}
];
 
var build = function() {
	for (var index in accounts) {
		buildBot(index);
	}
}
 
var buildBot = function(index) {
	var account = accounts[index];
	var username = account.username;
	var password = account.password;
	var authcode = account.authcode;
	var sentryFileHash = new Buffer(username).toString('base64');
	var bot = new steam.SteamClient();
	
	if (fs.existsSync(sentryFileHash)) {
		var sentry = fs.readFileSync(sentryFileHash);
		console.log("[STEAM][" + username + "]: Logging in with sentry. (" + sentryFileHash + ")");
		bot.logOn({
			accountName: username,
			password: password,
			shaSentryfile: sentry
		});
	} else {
		console.log("[STEAM][" + username + "]: Logging in without sentry.");
		bot.logOn({
			accountName: username,
			password: password,
			authCode: authcode
		});
	}
	
	bot.on('loggedOn', function() {
		console.log("[STEAM][" + username + "]: Logged In.");
		account.loggedIn = true;
		bot.setPersonaState(steam.EPersonaState.Online); // our bot needs to be in an online state for our idling to work.
		bot.gamesPlayed(shuffleArray(account.games)); // idle games
		
		setInterval(function() {
			//
			if (account.loggedIn) {
				try {
					console.log("[STEAM][" + username + "]: Changing games");
					bot.gamesPlayed([]); // empty array, we aren't playing anything.
					bot.gamesPlayed(shuffleArray(account.games));
				} catch (ex) {}
			}
			//
		}, 7200000); // 2 hours
	});
	
	bot.on('sentry', function(sentryHash) {
		console.log("[STEAM][" + username + "]: Received sentry file.");
		fs.writeFile(sentryFileHash, sentryHash, function(err) {
			if (err){
				console.log("[STEAM][" + username + "]: " + err);
			} else {
				console.log("[STEAM][" + username + "]: Wrote sentry file.");
			}
		});
	});
	
	bot.on('error', function(e) {
		if (e.eresult == steam.EResult.InvalidPassword) {
			console.log("[STEAM][" + username + "]: " + 'Login Failed. Reason: invalid password');
		} else if (e.eresult == steam.EResult.AlreadyLoggedInElsewhere) {
			console.log("[STEAM][" + username + "]: " + 'Login Failed. Reason: already logged in elsewhere');
		} else if (e.eresult == steam.EResult.AccountLogonDenied) {
			console.log("[STEAM][" + username + "]: " + 'Login Failed. Reason: logon denied - steam guard needed');
			promptAuthCode(accounts[index]);
			buildBot(index);
		} else {
			if (account.loggedIn) {
				account.loggedIn = false;
				bot.logOff();
				// change log in status to false to prevent exceptions
				// a logout reason of 'unknown' happens when ever you cannot access the account
				// or when you're logged out.
				console.log("[STEAM][" + username + "]: -----------------------------------------------------------");
				console.log("[STEAM][" + username + "]: Cannot log in at this time.");
				console.log("[STEAM][" + username + "]: !!! The script will try to log in again in 5 minutes. !!!");
				console.log("[STEAM][" + username + "]: If you're currently logged into the account log out.");
				console.log("[STEAM][" + username + "]: You are able to log into an account whilst it's idling, just don't play games.");
				setTimeout(function() {
					// try again.
					buildBot(index);
				}, 300000);
				console.log("[STEAM][" + username + "]: -----------------------------------------------------------");
			} else {
				console.log("[STEAM][" + username + "]: Login Failed. Reason: " + e.eresult);
			}
		}
	});
}
 
// run the idle script.
build();