local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharmSync = require(ReplicatedStorage.Packages.CharmSync)
local TypedRemote = require(ReplicatedStorage.Shared.Classes.TypedRemote)
local Types = require(ReplicatedStorage.Shared.Types)

local _RemoteFunction, RemoteEvent, _UnreliableRemoteEvent = TypedRemote.parent(script)

type RemoteFunction<T..., R...> = TypedRemote.Function<T..., R...>
type RemoteEvent<T...> = TypedRemote.Event<T...>

return {
	-- ✰ Shared ✰ --
	Notifications = {
		Notify = RemoteEvent("Notification") :: RemoteEvent<string, Types.ColorKey?, Types.SoundKey?, number?>,
		
		Normal = RemoteEvent("NotifyNormal") :: RemoteEvent<string, number?>,
		Info = RemoteEvent("NotifyInfo") :: RemoteEvent<string, number?>,
		Warning = RemoteEvent("NotifyWarn") :: RemoteEvent<string, number?>,
		Error = RemoteEvent("NotifyError") :: RemoteEvent<string, number?>,
		Success = RemoteEvent("NotifySuccess") :: RemoteEvent<string, number?>,
		ProductBought = RemoteEvent("ProductBought") :: RemoteEvent<string, number?>,
		ItemBought = RemoteEvent("ItemBought") :: RemoteEvent<string, number?>,
	},
	
	PlaySounds = {
		CustomSound = RemoteEvent("CustomSound") :: RemoteEvent<string>,
		StopSound = RemoteEvent("StopSound") :: RemoteEvent<string>,
		
		Error = RemoteEvent("ErrorSFX") :: RemoteEvent<>,
		Success = RemoteEvent("SuccessSFX") :: RemoteEvent<>,
		Purchase = RemoteEvent("PurchaseSFX") :: RemoteEvent<>,
		Warning = RemoteEvent("WarningSFX") :: RemoteEvent<>,
	},
	
	Chat = {
		DisplayChatMessage = RemoteEvent("DisplayChatMessage") :: RemoteEvent<string>,
	},
	
	Overlay = {
		Transition = RemoteEvent("Transition") :: RemoteEvent<>,
		MutationReveal = RemoteEvent("MutationReveal") :: RemoteEvent<string, number, boolean?>,
	},
	
	Tutorial = {
		Progress = RemoteEvent("Progress") :: RemoteEvent<number, boolean?>,
	},
	
	Spin = {
		SpinWheel = _RemoteFunction("SpinWheel") :: RemoteFunction<(), ()>
	},

	---- ✰ Atom Syncing ✰ --
	ClientData = {
		Sync = RemoteEvent("SyncClientData") :: RemoteEvent<CharmSync.SyncPayload>,
		ClientSignaledLoaded = RemoteEvent("ClientSignaledLoaded") :: RemoteEvent<>,
	},
	State = {
		Request = RemoteEvent("RequestState") :: RemoteEvent<>,
		Sync = RemoteEvent("SyncState") :: RemoteEvent<CharmSync.SyncPayload>,
	},


	---- ✰ Data Components ✰ --
	
	---- DataPlots
	Plots = {
		BuySlot = RemoteEvent("BuySlot") :: RemoteEvent<number, number>,
		
		EggRoll = RemoteEvent("EggRoll") :: RemoteEvent<>,
		BuyEggRoll = RemoteEvent("BuyEggRoll") :: RemoteEvent<string, number>,
		PlaceAtSlot = RemoteEvent("PlaceAtSlot") :: RemoteEvent<string, number, number>,
		HatchEgg = RemoteEvent("HatchEgg") :: RemoteEvent<string, number, number>,
		SkipEggHatch = RemoteEvent("SkipEggHatch") :: RemoteEvent<number, number>,
		Mutate = RemoteEvent("Mutate") :: RemoteEvent<string, number, number>,
		RevealMutation = RemoteEvent("RevealMutation") :: RemoteEvent<string, number, number>,
		SkipMutation = RemoteEvent("SkipMutation") :: RemoteEvent<string, number, number>,
		TakeLabubu = RemoteEvent("TakeLabubu") :: RemoteEvent<string, number, number>,
		
		Rebirth = RemoteEvent("Rebirth") :: RemoteEvent<number>,
		StealLabubu = RemoteEvent("StealLabubu") :: RemoteEvent<Model, number, string, number, number>,
		
		KeepLostMutationSuccess = RemoteEvent("KeepLostMutationSuccess") :: RemoteEvent<string>,
		MutateFail = RemoteEvent("MutateFail") :: RemoteEvent<string, string, number>,
		ClientMutateFail = RemoteEvent("ClientMutateFail") :: RemoteEvent<string>,
	},
	
	Seller = {
		SellLabubus = _RemoteFunction("SellLabubus") :: RemoteFunction<(), (boolean)>,
		SellEggs = _RemoteFunction("SellEggs") :: RemoteFunction<(), (boolean)>,
		CheckValue = _RemoteFunction("CheckValue") :: RemoteFunction<(string), (boolean)>,
		SellHandItem = _RemoteFunction("SellHandItem") :: RemoteFunction<(string), (boolean)>,
	},
	
	-- DataTrading
	Trading = {
		TradeRequest = RemoteEvent("TradeRequest") :: RemoteEvent<string>,
		TradeResponse = RemoteEvent("TradeResponse") :: RemoteEvent<string, boolean>,
		TradeUpdate = RemoteEvent("TradeUpdate") :: RemoteEvent<{string}>,
		TradeAccept = RemoteEvent("TradeAccept") :: RemoteEvent<>,
		TradeCancel = RemoteEvent("TradeCancel") :: RemoteEvent<>,
	},

	---- DataCodes
	Codes = {
		RedeemCode = _RemoteFunction("RedeemCode") :: RemoteFunction<(string), (boolean?)>,
	},
	
	DailyRewards = {
		Claim = RemoteEvent("DailyRewardsClaim") :: RemoteEvent<>,
	},

	-- DataGroupRewards
	GroupRewards = {
		Claimed = _RemoteFunction("GroupRewardsClaimed") :: RemoteFunction<(boolean?), (boolean?)>,
	},
	
	-- DataGifting
	Gifting = {
		Select = RemoteEvent("GiftSelect") :: RemoteEvent<number, string, string>,
	},
	
	Purchases = {
		promptProduct = RemoteEvent("PromptProduct") :: RemoteEvent<number, boolean?>,
		promptGamepass = RemoteEvent("PromptGamepass") :: RemoteEvent<number, boolean?>,
		promptBundle = RemoteEvent("PromptBundle") :: RemoteEvent<number, boolean?>,
		
		ConfettiEffect = RemoteEvent("ConfettiEffect") :: RemoteEvent<>,
	},
	
	Prompts = {
		FavoritePrompt = RemoteEvent("FavoritePrompt") :: RemoteEvent<>,
	},

	-- DataSettings
	Settings = {
		-- ClientW
		ClientUpdateSettings = RemoteEvent("ClientUpdateSettings") :: RemoteEvent<Types.Settings>,
	},
}