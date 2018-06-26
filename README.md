[![Build Status](https://travis-ci.org/gnublin/chef-dbwm.svg?branch=master)](https://travis-ci.org/gnublin/chef-dbwm)

# Chef-dbwm
Chef DataBags Web Manager is an application to manage your databag files.
This app support the encrypted or not databags in json format.

You can run this app on your chef server or locally on your computer.

## Requirement
 * bundler
 * npm

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
You should to create a `config.yml` configuration file.

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
    - name: env1
      path: /home/user/code/git/project1/data_bags
    - name: env2
      path: /home/user/code/git/project2/data_bags
    - name: env3
      path: /home/user/code/git/project3/data_bags
```

## Run app
```
bundle exec ruby config.ru
```

## License and Author

Author: Gauthier FRANÇOIS (<gauthier@openux.org>)

```text
GNU General Public License v3.0
```
