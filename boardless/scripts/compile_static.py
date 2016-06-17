import os
import time
import shutil
import subprocess

HERE = os.path.abspath(os.path.dirname(__file__))

def compile_coffeescript ():
	print "Compiling coffeescript to js..."

	TMP_DIR = '/tmp/coffee'
	JS_PATH = os.path.join(HERE, '../static/js/compiled')
	COFFEE_PATH = os.path.join(HERE, '../static/coffee')

	if not os.path.isdir(JS_PATH):
		os.mkdir(JS_PATH)

	subprocess.check_call(['coffee', '--compile', '--map', '--output', TMP_DIR, COFFEE_PATH,])

	for filename in os.listdir(TMP_DIR):
		old_path = os.path.join(TMP_DIR, filename)
		new_path = os.path.join(JS_PATH, '{0}'.format(filename))
		shutil.copy2(old_path, new_path)

	print "Done"

def compile_styles ():
	print "Compiling styl to css..."

	CSS_PATH = os.path.join(HERE, '../static/css')
	FILES_TO_COMPILE = ('styles.styl',)

	subprocess.check_call(['stylus'] + [os.path.join(CSS_PATH, styl_filename) for styl_filename in FILES_TO_COMPILE])

	print "Done"

def compile_grammatic ():
	print "Compiling grammatic..."

	SOURCE_PATH = os.path.join(HERE, '../static/grammatics')
	DEST_PATH = os.path.join(HERE, '../static/grammatics/compiled')
	FILES_TO_COMPILE = ('grammatics.pegjs',)

	if not os.path.isdir(DEST_PATH):
		os.mkdir(DEST_PATH)

	for filename in FILES_TO_COMPILE:
		print "Compiling {0}".format(filename)
		new_filename = filename.replace('.pegjs', '.js')
		subprocess.check_call(['pegjs', '--export-var', 'window.PEG', os.path.join(SOURCE_PATH, filename), os.path.join(DEST_PATH, new_filename)])

	print "Done."

def create_client_settings (settings):
	print "Creating settings.js"

	FILENAME = "settings.js"
	COMPILE_PATH = os.path.join(HERE, '../static/js/compiled', FILENAME)

	ws_host = settings.get('connection', 'host')
	ws_port = settings.getint('connection', 'port')

	with open(COMPILE_PATH, 'w') as f:
		f.write('''
window.board.CACHEOFF = "{ts}";

window.board.WS_HOST = "{ws_host}";
window.board.WS_PORT = {ws_port};
		'''.strip().format(
				ts = int(time.time()),
				ws_host = ws_host,
				ws_port = ws_port,
			)
		)

	print "Done"

if __name__ == '__main__':
	compile_coffeescript()
	compile_styles()
	compile_grammatic()