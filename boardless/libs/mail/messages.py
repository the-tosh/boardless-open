# _*_ encoding: utf-8 _*_

from boardless.libs.mail import NOTIFICATION_SENDER

from pyramid_mailer.message import Message

def registration_confirmation (user):
    msg = Message(
        subject = 'Boardless: Registration confirmation',
        sender = NOTIFICATION_SENDER,
        recipients = [user.email],
        html = u'''Перейдите по <a href="http://boardless.ru/profile/confirm/{0}">ссылке</a> для завершения регистрации'''.format(user.confirmation_hash) # TODO: use templates
    )
    return msg

def restore_password_request (user, req):
    msg = Message(
        subject = 'Boardless: Restore password request',
        sender = NOTIFICATION_SENDER,
        recipients = [user.email],
        html = u'''Для ввода нового пароля, перейдите по <a href="http://boardless.ru/auth/restore_password/{0}">ссылке</a>.
            <br />
            Если вы не запрашивали восстановление пароля, обратитесь в тех поддержку: admin@boardless.ru
        '''.format(req.hash).strip(),
    )

    return msg