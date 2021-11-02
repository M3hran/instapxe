from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
import os

db = SQLAlchemy()

DB_HOST = os.environ.get('MYSQL_HOST')
DB_PORT = os.environ.get('MYSQL_PORT')
DB_USERNAME = os.environ.get('MYSQL_USER')
DB_PASSWORD = os.environ.get('MYSQL_PASSWORD')
DB_NAME = os.environ.get('MYSQL_DATABASE')

#DB_HOST = '192.168.1.220'
#DB_PORT = '3306'
#DB_USERNAME = 'instapxe'
#DB_PASSWORD = 'instapxe'
#DB_NAME = 'instapxe'


def create_app():
    app = Flask(__name__)
    app.config['SECRET_KEY'] = 'asdjflkasjf'
    app.config['SQLALCHEMY_DATABASE_URI'] = f'mysql://{DB_USERNAME}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}'
    app.config['SQLALCHEMY_ECHO'] = False
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    db.init_app(app)

    from .views import views
    from .auth import auth

    app.register_blueprint(views, url_prefix='/')
    app.register_blueprint(auth, url_prefix='/')

    from .models import User
    create_database(app)

    login_manager = LoginManager()
    login_manager.login_view = 'auth.login'
    login_manager.init_app(app)

    @login_manager.user_loader
    def load_user(id):
        return User.query.get(int(id))

    return app


def create_database(app):
    db.create_all(app=app)
    print('Create Database!')
