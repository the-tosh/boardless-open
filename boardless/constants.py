# _*_ coding: utf-8 _*_

import os
import bidict

#################################
# Admin
#################################
class Admin (object):
	OBJECTS_PER_PAGE = 50

#################################
# User
#################################
class UserGroups (object):
	UNCONFIRMED = "unconfirmed"
	CONFIRMED = "confirmed"
	ADMIN = "admin"

	CHOICES = [
		(UNCONFIRMED, "Unconfirmed (just registered)"),
		(CONFIRMED, "Confirmed (default)"),
		(ADMIN, "Admin"),
	]

class UserStatus (object):
	NEW = 1
	ACTIVE = 2

	CHOICES = [
		(NEW, 'New'),
		(ACTIVE, 'Active')
	]

#################################
# Telegram
#################################
class TelegramBot (object):
	# https://core.telegram.org/bots
	# https://core.telegram.org/bots/api

	API_KEY = 'PLACE YOUR API KEY HERE'
	API_ENDPOINT = 'https://api.telegram.org/bot{0}'.format(API_KEY)

class TelegramAdminGroup (object):
	ID = -102260378

#################################
# GameRules
#################################

class GameRulesCommon (object):
	MAX_PLAYERS = 10

class GameRulesStatuses (object):
	IS_MODERATING = 1
	AVAILABLE = 2

	CHOICES = [
		(IS_MODERATING, 'Moderating'),
		(AVAILABLE, 'Available')
	]

#################################
# GameSession
#################################

class GameSessionStatuses (object):
	AVAILABLE = 1
	CLOSED = 2

#################################
# SessionCharacter
#################################

class SessionCharacterRoles (object):
	MASTER = "master"
	PLAYER = "player"
	WATCHER = "watcher"

#################################
# PlayObject
#################################

class PlayfieldObject (object):
	NPC = 1
	ITEM = 2
	PLAYER = 3

	STR_NPC = "npc"
	STR_ITEM = "item"
	STR_PLAYER = "player"

	NAME_TO_TYPE = bidict.bidict({
		STR_NPC: NPC,
		STR_ITEM: ITEM,
		STR_PLAYER: PLAYER,
	})

	TO_SELECT = [(k, v) for k, v in NAME_TO_TYPE.viewitems()]


	GENERAL_OBJECTS_ORDER = ["npc", "item"]

	@classmethod
	def get_defaults (cls, static_path):
		return {
			"npc": {
				'title': "New NPC",
				'img_url': os.path.join(static_path, 'img/play/npc.png')
			},
			"item": {
				'title': "New item",
				'img_url': os.path.join(static_path, 'img/play/item.png'),
			},
		}