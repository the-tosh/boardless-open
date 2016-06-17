import datetime
from sapyens.helpers import route_view_config

from boardless.libs import telegram
from boardless import forms

@route_view_config('/feedback/', 'feedback', renderer = 'json', request_method = 'POST', permission = 'view')
def feedback (request):
    form = forms.Feedback(request.POST)
    if not form.validate():
        request.response.status_code = 422
        return form.errors

    # TODO: Mailer!
    # TODO: Template
    telegram.Bot.feedback_notify(
u'''<strong>User ID</strong>: {0}
<strong>Page</strong>: {1}
<strong>Useragent</strong>: {2}
<strong>Subject</strong>: {3}
<strong>Msg type</strong>: {4}
<strong>Message</strong>: {5}
<strong>Time</strong>: {6}'''.format(
            request.user.id,
            form.page.data,
            request.user_agent,
            form.subject.data,
            form.message_type.data,
            form.message.data,
            datetime.datetime.utcnow(),
        )
    )