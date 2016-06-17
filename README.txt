boardless README  
==================  

**FOR UBUNTU 14.04 (x64)**  

1. virtualenv --no-site-packages venv  
2. source venv/bin/activate  
3. cp development.ini.example SETTINGS.ini (do not forget add SETTINGS.ini to your global ~/.gitignore)  
4. set up your SETTINGS.ini file  

**Install postgresql**

5. echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" | sudo tee -a /etc/apt/sources.list.d/pgdg.list  
6. wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -  
7. sudo apt-get update  
8. sudo apt-get install postgresql-9.5 postgresql-server-dev-9.5 libpq-dev  
9. set up your postgresql and create the necessary database, user etc  

**Dependencies and migrations**

10. pip install -e .  
11. pip install -r git_requirements.txt  
12. migrate SETTINGS.ini  

**Install frontend-related stuff**  

./boardless/scripts/install_node_stuff.sh  

**Start your DEV web server:**  

./run SETTINGS.ini  

**To run the playground (websockets-based gamesession server)**  

1. cp server/dev.ini server/SETTINGS.ini  
2. cd server  
3. ./run SETTINGS.ini  

NOTE: If is_dev=true is in SETTINGS.ini, settings.js will be generated automatically before starting the server
