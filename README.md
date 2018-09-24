[![Build Status](https://travis-ci.org/gnublin/chef-dbwm.svg?branch=master)](https://travis-ci.org/gnublin/chef-dbwm)

# Chef-dbwm
Chef DataBags Web Manager is an application to manage your databags files.
This app support the encrypted or plain databags in json format.

You can run this app on your chef server or locally on your computer.

This app has vocation to simplify databags management instead the `knife` command.
App try all secrets you have registered to uncrypte the databag you want to access.
The databag modification is concern only the part of changes; that's better to follow changes in versionning repository.

# Install from GIT

### Requirement
 * bundler (gem install bundler)
 * [npm](https://www.npmjs.com/get-npm)

### Prepare
* Clone this repository
 ```
git clone https://github.com/gnublin/chef-dbwm.git
 ```
* Install ruby Gems
 ```
bundle install
 ```
* Install node modules
 ```
npm install
 ```

### Configure
Please read the [configure](#configure-2) section

### Run app
```
bundle exec rackup -p 8080
```

# Install from docker

### Prepare
* Clone this repository
 ```
git clone https://github.com/gnublin/chef-dbwm.git
 ```

### Configure

#### Docker

---
###### Warn: rackup default is in development mode. Your configuration file should be `config/development/config.yml`
---

You should to configure the shared volumes.

To manage the sharing, I've create an extra docker-compose file:

Edit the `docker-compose-vol.yml` sample:

```
# docker-compose-vol.yml
version: '3.0'
services:
  web:
    volumes:
      - /path_to/config/development/config.yml:/app/config/development/config.yml
      - /path_to/databags:/app/databags
      - /path_to/templates:/app/templates
```

I think the docker-compose-vol.yml will not be modify in the future. It's in my `.gitignore` file.

#### App

---
###### Warn: Adapt your App configuration file with your volumes mapping
---

Please read the [configure](#configure-2) section

## Run

To run this app in docker, you should to run the docker-compose command:

`docker-compose up -f docker-compose.yml -f docker-compose-vol.yml`
To down this app, you could to use the docker-compose command too:

`docker-compose down`

# Configure

You should to create a `config/RACK_ENV/config.yml` configuration.

Ex: `config/development/config.yml`

---
###### Warn: This configuration file is required to run this app.
---

```yaml
mdb_config:
  secret_keys_path:
    env1:
      path: /home/user/databags_keys/secret_env1
    env2:
      path: /home/user/databags_keys/secret_env2
    env3:
      path: /home/user/databags_keys/secret_env3
  data_bags_path:
    project42: /home/user/code/git/project_john/data_bags
    project73: /home/user/code/git/project_jane/data_bags
    project0: /home/user/code/git/project_doe/data_bags
  templates_dir:
    tpl1: /home/user/code/git/chef-dbwm/templates #absolute path
    tpl2: templates #relative path from repository
```

# Contribution

## Commit convention ##

* feat(#issue): description* when issue is a feature
* inprovement(#issue): description* when issue is a feature
* card(#issue): description* when issue is a bug
* bug(#issue): description* when issue is a card
* test(card name): description* when you add more commits into issue
* doc(readme): description* when you want to update readme or other doc


*feel free to add more details in multi-line list of your commit description

## License and Author

Author: Gauthier FRANCOIS (<gauthier@openux.org>)

```text
MIT License
Copyright (c) 2018 Gauthier FRANCOIS
```
