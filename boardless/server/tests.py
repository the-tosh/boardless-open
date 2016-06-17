### Test actions

@add_route()
class SleepPostgres (ParentAction):
    def sleep_postgres (self):
        DBSession.execute('SELECT pg_sleep(5)')
        return [skill.as_dict() for skill in models.Skill.query]

    def handle (self):
        self.sleep_postgres()
        return {'success': True}

@add_route()
class SleepPython (ParentAction):
    def sleep_python (self):
        import time
        time.sleep(5)
        return [skill.as_dict() for skill in models.Skill.query]

    def handle (self):
        self.sleep_python()
        return {'success': True}