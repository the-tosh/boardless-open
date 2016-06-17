# _*_ encoding: utf-8 _*_

import socket
import logging

import requests
from requests.exceptions import Timeout, SSLError, ConnectionError

from boardless import constants

logger = logging.getLogger(__name__)

class Bot (object):
    @staticmethod
    def api_call (method, data):
        url = '{0}/{1}'.format(constants.TelegramBot.API_ENDPOINT, method)

        try:
            requests.get(url, data = data, timeout = 1.5)
        except Timeout:
            logger.warn("Timeout is exceeded. URL: %s. Data: %s", url, data)
        except (SSLError, socket.error, ConnectionError):
            logger.info("Network error. URL: %s. Data: %s", url, data)

    @staticmethod
    def send_message (group_id, message):
        # TODO: add hostname
        data = {
            'chat_id': group_id,
            'text': message,
            'parse_mode': 'HTML',
            # 'disable_web_page_preview': False,
            # reply_to_message_id: -1,
            # reply_markup: 'ForceReply',
        }
        Bot.api_call('sendMessage', data)

    @staticmethod
    def feedback_notify (message):
        message = u'''
********** Фидбек подвезли! **********
{0}
        '''.format(message)
        Bot.send_message(constants.TelegramAdminGroup.ID, message)