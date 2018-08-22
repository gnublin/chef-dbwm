[![Build Status](https://travis-ci.org/gnublin/chef-dbwm.svg?branch=master)](https://travis-ci.org/gnublin/chef-dbwm)

# Chef-dbwm
Chef DataBags Web Manager is an application to manage your databag files.
This app support the encrypted or not databags in json format.

You can run this app on your chef server or locally on your computer.

This app has for vocation to simplify the use of the databags compared to the `knife` command.
It try all secrets you have set to uncrypte the databag you want to see.
The databag modification is in increment and only the part of change is modify; that's better to follow changes

## Requirement
 * bundler (gem install bundler)
 * [npm](https://www.npmjs.com/get-npm)

## Install
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

## Configure
You should to create a `config/RACK_ENV/config.yml` configuration.
Ex: `config/development/config.yml`

---
#### Warning: This configuration file is required to run this app.
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
    - name: project42
      path: /home/user/code/git/project_john/data_bags
    - name: project73
      path: /home/user/code/git/project_jane/data_bags
    - name: project0
      path: /home/user/code/git/project_doe/data_bags
```

## Run app
```
bundle exec rackup -p 8080
```

## License and Author

Author: Gauthier FRANCOIS (<gauthier@openux.org>)

```text
MIT License
Copyright (c) 2018 Gauthier FRANCOIS
```
